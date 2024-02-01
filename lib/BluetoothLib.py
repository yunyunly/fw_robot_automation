import pgi 
pgi.install_as_gi()
from gi.repository import GLib

import bluetooth.utils as utils 
import bluetooth.constants as constants
import dbus
from dbus import proxies
from dbus import _dbus
from dbus import connection
import dbus.mainloop.glib
import sys
import time
import threading
import robot.api.logger 

#sys.path.insert(0, '.')

dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
mainloop: GLib.MainLoop
signal_receivers: list[connection.SignalMatch] = list()

service_resolved_event = threading.Event()
new_device_event = threading.Event()
manufacturer_data_event = threading.Event()


def get_managed_object_path(object_manager, object_path):
    managed = False 
    managed_objects = object_manager.GetManagedObjects()
    for path, ifaces in managed_objects.items():
        if object_path == path:
            managed = True
    if managed:
        return object_path
    return None 

def get_if_connected(object_manager, object_path):
    connected = False 
    managed_objects = object_manager.GetManagedObjects()
    ifaces = managed_objects.get(object_path)
    device1_properties = ifaces.get(constants.DEVICE_INTERFACE)
    if 'Connected' in device1_properties:
        connected = utils.dbus_to_python(device1_properties['Connected'])
    return connected

class Adapter:
    def __init__(self, path, obj, interface):
        self.path: str = path 
        self.obj: proxies.ProxyObject = obj
        self.interface: proxies.Interface = interface

class Device:
    def __init__(self, path, obj, interface):
        self.path: str = path
        self.obj: proxies.ProxyObject = obj
        self.interface: proxies.Interface = interface
        self.rx: proxies.Interface
        self.tx: proxies.Interface

def mainloop_run():
    global mainloop
    bus = dbus.SystemBus()
    signal_receivers.append(bus.add_signal_receiver(interfaces_added,
            dbus_interface = constants.DBUS_OM_IFACE,
            signal_name = "InterfacesAdded"))
    signal_receivers.append(bus.add_signal_receiver(interfaces_removed,
            dbus_interface = constants.DBUS_OM_IFACE,
            signal_name = "InterfacesRemoved"))
    signal_receivers.append(bus.add_signal_receiver(properties_changed,
            dbus_interface = constants.DBUS_PROPERTIES,
            signal_name = "PropertiesChanged",
            path_keyword = "path"))
    mainloop.run()
    print("mainloop run end")

def mainloop_quit():
    global mainloop
    if mainloop_is_running():
        for i in signal_receivers:
            i.remove()
        #bus.remove_signal_receiver(interfaces_added,"InterfacesAdded")
        #bus.remove_signal_receiver(interfaces_added,"InterfacesRemoved")
        #bus.remove_signal_receiver(properties_changed,"PropertiesChanged")
        mainloop.quit()
    print("routine end")

def mainloop_is_running():
    global mainloop
    return mainloop.is_running()

class BluetoothLib:
    ROBOT_LIBRARY_SCOPE = 'SUITE'
    charging_case_header = 9
    def __init__(self):
        pass

    def __del__(self):
        pass 
    
    def __new__(cls):
        if not hasattr(cls, 'instance'):
            cls.instance = super(BluetoothLib, cls).__new__(cls)
        return cls.instance

    def init(self):
        global mainloop
        self.adapter: Adapter
        self.ha: Device 
        self.cc: Device
        self.bus = dbus.SystemBus()
        mainloop = GLib.MainLoop()
        self.object_manager = dbus.Interface(self.bus.get_object(constants.BLUEZ_SERVICE_NAME, "/"), constants.DBUS_OM_IFACE)

        self.config_adapter()
        self.mainloop = threading.Thread(target = mainloop_run)
        self.mainloop.start()

    def quit(self):
        if mainloop_is_running():
            mainloop_quit()
            time.sleep(0.1)
            self.mainloop.join()
            del self.mainloop

    def config_adapter(self):
        adapter_path = constants.BLUEZ_NAMESPACE + constants.ADAPTER_NAME
        adapter_object = self.bus.get_object(constants.BLUEZ_SERVICE_NAME, adapter_path)
        adapter_interface= dbus.Interface(adapter_object, constants.ADAPTER_INTERFACE)
        self.adapter = Adapter(adapter_path, adapter_object, adapter_interface)

    def discover_device(self, addr):
        global new_device_event
        self.adapter.interface.StartDiscovery(byte_arrays=True)
        dev_path = utils.device_address_to_path(addr, self.adapter.path)
        device_path = get_managed_object_path(self.object_manager, dev_path)
        if device_path is None:
            print("[Discover]", "No Managed Device Found")
            new_device_event.wait(15)
            new_device_event.clear()
        else:
            print("[Discover]", "Managed Device Found")
            connected = get_if_connected(self.object_manager, device_path)
            if connected:
                print("[Discover]", "Managed Device Was Connected")
                manufacturer_data_event.wait(15)
                manufacturer_data_event.clear() 
            else:
                print("[Discover]", "Managed Device Was Disconnected")
                time.sleep(10)
        self.adapter.interface.StopDiscovery()
        device_path = get_managed_object_path(self.object_manager, dev_path)
        if device_path :
            print("[Discover] Device Found")
            return constants.RESULT_OK 
        else:
            print("[Discover] Device Not Found")
            return constants.RESULT_ERR_NOT_FOUND

    def connect_device(self, addr):
        device_path = utils.device_address_to_path(addr, self.adapter.path)
        device_path = get_managed_object_path(self.object_manager, device_path)
        if device_path is None:
            return constants.RESULT_ERR_NOT_FOUND
        connected = get_if_connected(self.object_manager, device_path)
        if connected:
            pass 

        device_object = self.bus.get_object(constants.BLUEZ_SERVICE_NAME, device_path)
        device_interface = dbus.Interface(device_object, constants.DEVICE_INTERFACE)
        try:
            props = dbus.Interface(device_object, constants.DBUS_PROPERTIES)
            props.Set(constants.DEVICE_INTERFACE, "Trusted", True)
            device_interface.Connect()
        except Exception as e:
            print("[Connect] Failed to connect", e)
            #print(e.get_dbus_name())
            #print(e.get_dbus_message())
            if ("UnknownObject" in e.get_dbus_name()):
                print("[Connect] Try scan first to resolve this problem")
            return constants.RESULT_EXCEPTION
        else:
            print("[Connect] Connect Ok")
            return constants.RESULT_OK
    
    def discover_service(self):
        global service_resolved_event
        flag = service_resolved_event.wait(15)
        if flag:
            service_resolved_event.clear()
            return constants.RESULT_OK 
        else:
            return constants.RESULT_ERR_SERVICES_NOT_RESOLVED
    
    def disconnect_device(self, addr):
        device_path = utils.device_address_to_path(addr, self.adapter.path)
        device_path = get_managed_object_path(self.object_manager, device_path)
        if device_path == None:
            return constants.RESULT_ERR_NOT_FOUND
        connected = get_if_connected(self.object_manager, device_path)
        print("[Disconnect] previous connected:", connected)
        if not connected:
            return constants.RESULT_ERR_NOT_CONNECTED
        device_object = self.bus.get_object(constants.BLUEZ_SERVICE_NAME, device_path)
        device_interface = dbus.Interface(device_object, constants.DEVICE_INTERFACE)
        try:
            device_interface.Disconnect()
        except Exception as e:
            print("[Disconnect] Failed to disconnect", e)
            #print(e.get_dbus_name())
            #print(e.get_dbus_message())
            return constants.RESULT_EXCEPTION
        else:
            print("[Disconnect] OK")
            return constants.RESULT_OK
    
    def remove_device(self, addr):
        device_path = utils.device_address_to_path(addr, self.adapter.path)
        device_path = get_managed_object_path(self.object_manager, device_path)
        if device_path == None:
            return constants.RESULT_ERR_NOT_FOUND
        device_object = self.bus.get_object(constants.BLUEZ_SERVICE_NAME, device_path)
        try:
            self.adapter.interface.RemoveDevice(device_object)
        except Exception as e:
            print("[Remove] Failed to remove", e)
            #print(e.get_dbus_name())
            #print(e.get_dbus_message())
            return constants.RESULT_EXCEPTION
        else:
            print("[Remove] OK")
            return constants.RESULT_OK
    
    def discover_connect_resolve(self, addr):
        print("|| Discover Device")
        if self.discover_device(addr) == constants.RESULT_OK:
            print("|| Discover Device Success")
            print("|| Connect")
            if self.connect_device(addr) == constants.RESULT_OK:
                print("|| Connect Success")
                print("|| Resolve Service")
                if self.discover_service() == constants.RESULT_OK:
                    print("|| Resolve Service Success")
                    return constants.RESULT_OK
                else:
                    print("|| Failed Resolve Service")
                    return constants.RESULT_ERR_SERVICES_NOT_RESOLVED
            else:
                print("== Failed Connect")
                return constants.RESULT_ERR_NOT_CONNECTED
        else:
            print("== Failed Discover Device")
            return constants.RESULT_ERR_NOT_FOUND

    def ble_connect_hearing_aids(self, addr):
        """Connect to low energy bluetooth hearing aids"""
        print("=== BLE Connect Hearing Aids ===")
        filter = dict()
        filter.update({"Pattern" :  addr})
        try:
            self.adapter.interface.SetDiscoveryFilter(filter)
        except Exception as e:
            print("set discovery filter failed", e)
            return False

        if constants.RESULT_OK == self.discover_connect_resolve(addr):
            device_path = utils.device_address_to_path(addr, self.adapter.path)
            device_object = self.bus.get_object(constants.BLUEZ_SERVICE_NAME, device_path)
            device_path = get_managed_object_path(self.object_manager, device_path)
            device_interface = dbus.Interface(device_object, constants.GATT_SERVICE_INTERFACE)
            self.ha = Device(device_path, device_object, device_interface)
            char_object = self.bus.get_object(constants.BLUEZ_SERVICE_NAME, device_path+"/service001a/char001f")
            self.ha.tx = dbus.Interface(char_object, constants.GATT_CHARACTERISTIC_INTERFACE)
            return True 
        else:
            return False
    
    def bt_connect_hearing_aids(self, addr):
        """Connect to classic bluetooth hearing aids"""
        print("=== BT Connect Hearing Aids ===")
        filter = dict()
        filter.update({"Transport" :  "bredr"})
        filter.update({"Pattern" :  addr})
        try:
            self.adapter.interface.SetDiscoveryFilter(filter)
        except Exception as e:
            print("set discovery filter failed", e)
            return False
        if constants.RESULT_OK == self.discover_connect_resolve(addr):
            return True 
        return False

    def ble_connect_case(self, addr):
        """Connect to a given address charging case, no matter whether it is cached"""
        print("=== BLE Connect Charging Case ===")
        filter = dict()
        filter.update({"Transport" :  "le"})
        filter.update({"Pattern" :  addr})
        try:
            self.adapter.interface.SetDiscoveryFilter(filter)
        except Exception as e:
            print("Failed to set discovery filter", e)
            return False

        if constants.RESULT_OK == self.discover_connect_resolve(addr):
            device_path = utils.device_address_to_path(addr, self.adapter.path)
            device_object = self.bus.get_object(constants.BLUEZ_SERVICE_NAME, device_path)
            device_path = get_managed_object_path(self.object_manager, device_path)
            device_interface = dbus.Interface(device_object, constants.GATT_SERVICE_INTERFACE)
            self.cc = Device(device_path, device_object, device_interface)
            char_object = self.bus.get_object(constants.BLUEZ_SERVICE_NAME, device_path+"/service0019/char001a")
            self.cc.tx = dbus.Interface(char_object, constants.GATT_CHARACTERISTIC_INTERFACE)
            return True 
        else:
            return False

    def ble_disconnect_hearing_aids(self, addr):
        """Disconnect from hearing aids"""
        self.disconnect_device(addr)
        self.remove_device(addr)

    def ble_disconnect_case(self, addr):
        """Disconnect from charging case"""
        self.disconnect_device(addr)
        self.remove_device(addr)

    def ble_send_case(self, data):
        """Send data to connected charging case"""
        data = [self.charging_case_header] + data
        print(f"WriteValue: {bytearray(data).hex()}")
        try:
            self.cc.tx.WriteValue(bytearray(data), {})
        except Exception as e:
            print("Failed to write", e)
            return False 
        else:
            print("Write OK")
            return True

    def ble_send_hearing_aids(self, data):
        """Send data to connected hearing aids"""
        print(f"WriteValue: {bytearray(data).hex()}")
        try:
            self.ha.tx.WriteValue(bytearray(data), {})
        except Exception as e:
            print("Failed to write", e)
            #print(e.get_dbus_name())
            #print(e.get_dbus_message())
            return False
        else:
            print("Write OK")
            return True
    
    def ble_case_connected(self, addr):
        """Return True if charging case connected, otherwise False"""
        device_path = utils.device_address_to_path(addr, self.adapter.path)
        device_path = get_managed_object_path(self.object_manager, device_path)
        if device_path:
            return get_if_connected(self.object_manager, device_path)
        else:
            return False

    def ble_hearing_aids_connected(self, addr):
        """Return True if hearing aids connected, otherwise False"""
        device_path = utils.device_address_to_path(addr, self.adapter.path)
        device_path = get_managed_object_path(self.object_manager, device_path)
        if device_path:
            return get_if_connected(self.object_manager, device_path)
        else:
            return False
        
    def addr_remove_colon(self,dev_addr:str):
        """given a colon seperated bluetooth addres, return a string of the address without colon"""
        ble_address_without_colons = dev_addr.replace(':', '')
        return ble_address_without_colons

    def addr_insert_colon(self,dev_addr:str):
        """given a bluetooth adddress string without colon, return the address with colon seperation"""
        ble_address_with_colons = ':'.join([dev_addr[i:i+2] for i in range(0, len(dev_addr), 2)])
        return ble_address_with_colons


def interfaces_added(path, interfaces):
    # interfaces is an array of dictionary entries
    global new_device_event
    if not path.startswith("/org/bluez"):
        return 
    if constants.DEVICE_INTERFACE in interfaces:
        device_properties = interfaces[constants.DEVICE_INTERFACE]
        print("------------------------------")
        print("[ADD] NEW path  :", path)

        if 'Address' in device_properties:
            print("[ADD] NEW bdaddr: ", utils.dbus_to_python(device_properties['Address']))
        if 'Name' in device_properties:
            print("[ADD] NEW name  : ", utils.dbus_to_python(device_properties['Name']))

        if 'RSSI' in device_properties:
            print("[ADD] NEW RSSI  : ", utils.dbus_to_python(device_properties['RSSI']))
        new_device_event.set()

    if constants.GATT_SERVICE_INTERFACE in interfaces:
        properties = interfaces[constants.GATT_SERVICE_INTERFACE]
        print("[ADD] SVC path   :", path)
        if 'UUID' in properties:
            uuid = properties['UUID']
            print("[ADD] SVC UUID   : ", utils.dbus_to_python(uuid))
            if uuid == constants.ECHO_GATT_SVC_UUID:
                print("[ADD] SVC Name   : ", "Echo Gatt Service")
            elif uuid == constants.ORKA2_GATT_SVC_UUID:
                print("[ADD] SVC Name   : ", "Orka2 Gatt Service")
            #print("SVC name   : ", utils.get_name_from_uuid(uuid))
            else:
                print("[ADD] SVC Name   : ", "Others")
    if constants.GATT_CHARACTERISTIC_INTERFACE in interfaces:
        properties = interfaces[constants.GATT_CHARACTERISTIC_INTERFACE]
        print("[ADD]   CHR path   :", path)
        if 'UUID' in properties:
            uuid = properties['UUID']
            print("[ADD]   CHR UUID   : ", utils.dbus_to_python(uuid))
            if uuid == constants.ECHO_GATT_CHR_UUID:
                print("[ADD]   CHR Name   : ", "Echo Gatt Characteristic")
            elif uuid == constants.ORKA2_GATT_CHR_UUID:
                print("[ADD]   CHR Name   : ", "Orka2 Gatt Characteristic")
            else:
                print("[ADD]   CHR Name   : ", "Others")
            flags  = ""
            for flag in properties['Flags']:
                flags = flags + flag + ","
            print("[ADD]   CHR flags  : ", flags)
    
    if constants.MEDIA_CONTROL_INTERFACE in interfaces:
        properties = interfaces[constants.MEDIA_CONTROL_INTERFACE]
        print("[ADD]   Media path   : ", path)
        print("[ADD]   Media interfaces : ", interfaces)
        if 'UUID' in properties:
            uuid = properties['UUID']
            if uuid == constants.HFP_UUID:
                print("[ADD]   HFP Interface Added")
            elif uuid == constants.A2DP_AUDIO_SINK_UUID:
                print("[ADD]   A2DP Interface Added")
            else:
                print("[ADD]   Others Interface Added")
    if constants.MEDIA_TRANSPORT_INTERFACE in interfaces:
        properties = interfaces[constants.MEDIA_TRANSPORT_INTERFACE]
        print("[ADD]   Media path   : ", path)
        print("[ADD]   Media interfaces : ", interfaces)
        if 'UUID' in properties:
            uuid = properties['UUID']

def interfaces_removed(path, interfaces):
    if not path.startswith("/org/bluez"):
        return 
    print("------------------------------")
    print("[DEL] DEL path : ", path)
    for i in interfaces:
        print("[DEL]  DEL   : ", i)

def properties_changed(interface, changed, invalidated, path):
    global service_resolved_event
    if not path.startswith("/org/bluez"):
        return 
    print("------------------------------")
    print(f'[CHG] CHG path: {path}\n  interface: {interface}')
    for k,v in changed.items():
        print("[CHG]   CHGD: ", k, "To",v)
    if interface != constants.DEVICE_INTERFACE:
        return
    if 'ServicesResolved' in changed:
        sr = utils.dbus_to_python(changed['ServicesResolved'])
        if sr == True:
            service_resolved_event.set()
    # Hardcode. Discover new device while device was found
    if 'ManufacturerData' in changed:
        mf = utils.dbus_to_python(changed['ManufacturerData'])
        if 13621 in mf:
            manufacturer_data_event.set()
    # Hardcode. Simulate ServicesResolved while service was resolved
    if 'UUIDs' in changed:
        uuids: list[str] = utils.dbus_to_python(changed['UUIDs'])
        expected = ['00000000-17e7-4aa2-b4a3-771fd30a70f1', 
                    '0000110b-0000-1000-8000-00805f9b34fb', 
                    '0000110c-0000-1000-8000-00805f9b34fb', 
                    '0000110e-0000-1000-8000-00805f9b34fb', 
                    '0000111e-0000-1000-8000-00805f9b34fb', 
                    '00001800-0000-1000-8000-00805f9b34fb', 
                    '00001801-0000-1000-8000-00805f9b34fb', 
                    '01000100-0000-1000-8000-009078563412', 
                    '66666666-6666-6666-6666-666666666666']
        if not (len(uuids) == len(expected)):
            pass 
        else:
            uuids.sort()
            expected.sort()
            solved = True 
            for (l,r) in zip(uuids, expected):
                if not ( l == r ):
                    solved = False 
                    break 
            if solved:
                service_resolved_event.set()
        
if __name__ == "__main__":
    m = BluetoothLib()
    addr = "D0:14:11:20:1F:B3"
    addr1 = "12:34:56:78:A0:B3"
    m.ble_connect_case(addr)
    m.bt_connect_hearing_aids(addr1)
    m.ble_connect_hearing_aids(addr1)
    import subprocess
    output = subprocess.check_output(["busctl", "tree", "org.bluez"])
    print(output.decode())
    m.ble_disconnect_case(addr)
    m.ble_disconnect_hearing_aids(addr1)
    #m.ble_disconnect_hearing_aids("12:34:56:78:A0:B3")
    m.quit()


