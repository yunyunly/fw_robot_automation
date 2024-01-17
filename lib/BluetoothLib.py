import sys
try:
    import dbus
    import dbus.mainloop.glib
except ImportError as e:
    if 'linux' not in sys.platform:
        raise e
    print(e)
    print('Install packages `libgirepository1.0-dev gir1.2-gtk-3.0 libcairo2-dev libdbus-1-dev libdbus-glib-1-dev` for resolving the issue')
    raise

from logging import error
import time
import robot.api.logger 
import subprocess

BLUEZ_SERVICE_NAME = 'org.bluez'
DBUS_OM_IFACE = 'org.freedesktop.DBus.ObjectManager'
DBUS_PROP_IFACE = 'org.freedesktop.DBus.Properties'

ADAPTER_IFACE = 'org.bluez.Adapter1'
DEVICE_IFACE = 'org.bluez.Device1'

GATT_MANAGER_IFACE = 'org.bluez.GattManager1'
LE_ADVERTISING_MANAGER_IFACE = 'org.bluez.LEAdvertisingManager1'

GATT_SERVICE_IFACE = 'org.bluez.GattService1'
GATT_CHRC_IFACE = 'org.bluez.GattCharacteristic1'

MEDIA_SERVICE_IFACE = "org.bluez.MediaEndpoint1"
MEDIA_CHRC_IFACE = "org.bluez.MediaTransport1"

BLE_HEARING_AIDS_SERVICE_UUID = "01000100-0000-1000-8000-009078563412"
BLE_HEARING_AIDS_CHRC_UUID = "03000300-0000-1000-8000-009278563412"
BT_HEARING_AIDS_SERVICE_UUID = "00000001-0000-1000-8000-00805f9b34fb"

BLE_CHARGING_CASE_SERVICE_UUID = ""
BLE_CHARGING_CASE_CHRC_UUID = ""

Console = robot.api.logger.console 
Debug = robot.api.logger.debug 
Info = robot.api.logger.info 

class DBusException(dbus.exceptions.DBusException):
    pass

class Characteristic:
    def __init__(self):
        self.iface = None
        self.path = None
        self.props = None

class Service:
    def __init__(self):
        self.iface = None
        self.path = None
        self.props = None
        self.chars = []

class Device:
    def __init__(self):
        self.iface = None
        self.path = None
        self.props = None
        self.name = None
        self.addr = None
        self.services = []
        self.services_bt = []
        self.service_le = None

class Adapter:
    def __init__(self):
        self.iface = None
        self.path = None
        self.props = None

class BluetoothLib(object):
    """This class is the underlying impl for charging case and hearing aids bluetooth related libraries.

    Do not suggest you use its any API in test cases, you should use HearingAidsLib or ChargingCaseLib.
    """
    ROBOT_LIBRARY_SCOPE = 'SUITE'
    charging_case_header = 9
    hci_id = 0
    case_addr:str 
    hearing_aids_addr:str
    def __init__(self):
        self.bus = dbus.SystemBus()
        self.bluez_obj = self.bus.get_object("org.bluez", "/org/bluez")
        self.adapter_obj = self.bus.get_object("org.bluez", f"/org/bluez/hci{self.hci_id}")
        self.om_if = dbus.Interface(
            self.bus.get_object("org.bluez", "/"), 
            "org.freedesktop.DBus.ObjectManager"
        )
        Console("Bluetooth Inited")
        return 

    def __del__(self):
        try:
            # Cleanup
            self.ble_disconnect_hearing_aids()
            print('Bluetooth Lib Exit')
        except Exception as e:
            print(e)
            
    def init(self):
        """
            Temp palceholder for new ble lib
        """
        return
    
    def quit(self):
        """
            Temp palceholder for new ble lib
        """
        return
    
    def connect(self, addr="D0:14:11:20:20:18"):
        """Connect Device via bluetoothctl
        
        Examples:
        | Connect | D0:11:22:33:44:55 |
        """
        dev_addr = addr.replace(":", "_")
        dev_path = f'/org/bluez/hci{self.hci_id}/dev_{dev_addr}'
        cnt = 10 
        while dev_path not in self.om_if.GetManagedObjects().keys():
            time.sleep(3)
            cnt = cnt - 1 
            if cnt == 0:
                print("timeout")
                return None, None
            #print(self.om_if.GetManagedObjects().keys())

        dev_obj = self.bus.get_object("org.bluez", dev_path)
        try:
            print("connecting...")
            dev_itf = dbus.Interface(dev_obj, 'org.freedesktop.DBus.Properties')
            dev_itf.Set('org.bluez.Device1', 'Trusted', dbus.Boolean(True))
            time.sleep(2)
            Console("device trusted status: "+str(dev_itf.Get('org.bluez.Device1', 'Trusted')))
            dev_obj.Connect(dbus_interface="org.bluez.Device1")
        except:
            try: 
                print("connecting...")
                dev_obj.Connect(dbus_interface="org.bluez.Device1")
            except Exception as e:
                error(e)
        return (dev_obj, dev_path)
    
    def send(self, iface, data):
        """Send data to connected device via BLE 
        
        You should not use it in test cases
        """
        Console(f"WriteValue: {bytearray(data).hex()}")
        try:
            iface.WriteValue(bytearray(data), {})
        except Exception as e:
            error(e)

    def read(self, iface):
        """Read properties, not recieving
        
        You should not use it in test cases 
        """
        return iface.ReadValue("")
    
    def get_gatt_char(self, dev_path, srv_id, char_id):
        char_path = f"{dev_path}/{srv_id}/{char_id}"
        cnt = 10
        while char_path not in self.om_if.GetManagedObjects():
            print("scan char...")
            time.sleep(1)
            cnt = cnt - 1 
            if cnt == 0 : return None 
        return dbus.Interface(self.bus.get_object("org.bluez", char_path), "org.bluez.GattCharacteristic1")

    def ble_scan_on(self):
        try:
            filter = dict()
            self.adapter_obj.SetDiscoveryFilter(filter, dbus_interface="org.bluez.Adapter1")
            self.adapter_obj.StartDiscovery(dbus_interface="org.bluez.Adapter1")
        except:
            raise Exception("scan on failed")
    
    def ble_scan_on_le_only(self, devaddr):
        try:
            filter = dict()
            filter.update({"Transport" :  "le"})
            self.adapter_obj.SetDiscoveryFilter(filter, dbus_interface="org.bluez.Adapter1")
            self.adapter_obj.StartDiscovery(dbus_interface="org.bluez.Adapter1")
        except:
            raise Exception("scan on failed")

    def ble_scan_on_bredr_only(self):
        try:
            filter = dict()
            filter.update({"Transport" :  "bredr"})
            filter.update({"UUIDs": ["00000001-0000-1000-8000-00805f9b34fb"]})
            self.adapter_obj.SetDiscoveryFilter(filter, dbus_interface="org.bluez.Adapter1")
            self.adapter_obj.StartDiscovery(dbus_interface="org.bluez.Adapter1")
        except:
            raise Exception("scan on failed")

    def ble_scan_off(self):
        try:
            self.adapter_obj.StopDiscovery(dbus_interface="org.bluez.Adapter1")
        except:
            raise Exception("scan off failed")
    
    def ble_connect_case(self, addr = "D0:14:11:20:20:18"):
        """Connect to a given address charging case, no matter whether it is cached"""
        print("Blue Connect Case...")
        self.ble_scan_on_le_only(addr)
        self.case, self.case_path = self.connect(addr)
        if self.case is None:
            self.ble_scan_off()
            return False 
        self.case_char_if = self.get_gatt_char(self.case_path, "service0019", "char001a")
        print("Case Char Interface", self.case_char_if)
        self.case_addr = addr
        self.ble_scan_off()
        return True
    
    def bt_connect_hearing_aids(self, devaddr):
        """Connect to classic bluetooth hearing aids"""
        print("Blue Connect Hearing Aids...")
        print("connecting bredr...")
        self.ble_scan_on_bredr_only()
        self.hearing_aids, self.hearing_aids_path = self.connect(devaddr)
        if self.hearing_aids is None:
            self.ble_scan_off()
            return False
        self.ble_scan_off()

        dbus_obj_mgr = dbus.Interface(self.bus.get_object(BLUEZ_SERVICE_NAME, '/'), DBUS_OM_IFACE)
        dbus_objs = dbus_obj_mgr.GetManagedObjects()
        
        for path, interfaces in dbus_objs.items():
            if MEDIA_SERVICE_IFACE in interfaces.keys():
                if path.startswith(self.hearing_aids_path):
                    print("bredr connected")
                    return True 
        print("bredr false connected")
        return False

    def ble_connect_hearing_aids(self, addr = "D0:14:11:20:20:18"):
        """Connect to low energy bluetooth hearing aids"""
        
        print("Blue Connect Hearing Aids...")
        self.ble_scan_on_le_only(addr)
        print("connecting le...")
        time.sleep(3)
        self.hearing_aids, self.hearing_aids_path = self.connect(addr)
        if self.hearing_aids is None:
            self.ble_scan_off()
            return False
        print("le connected")
        time.sleep(1)
        print("connecting char...")
        self.hearing_aids_char_if = self.get_gatt_char(self.hearing_aids_path, "service001a", "char001f")
        if self.hearing_aids_char_if is None :
            print("char not connected")
            self.ble_scan_off()
            return False
        self.hearing_aids_addr = addr
        self.ble_scan_off()
        print("char connected")
        return True
    
    def disconnect(self, devaddr):
        device_path = f"/org/bluez/hci{self.hci_id}/dev_" + devaddr.replace(":", "_")
        device = dbus.Interface(self.bus.get_object("org.bluez", device_path),"org.bluez.Device1")
        ret = False
        try:
            print('disconnecting device')
            props = dbus.Interface(self.bus.get_object("org.bluez", device_path), DBUS_PROP_IFACE)
            device_conn = props.Get(DEVICE_IFACE, 'Connected')
            if device_conn == 1:
                device.Disconnect(dbus_interface=DEVICE_IFACE)
                for cnt in range(10, 0, -1):
                    time.sleep(5)
                    device_conn = props.Get(DEVICE_IFACE, 'Connected')
                    if device_conn == 0:
                        print('device disconnected')
                        break
                    print('number of retries left ({})'.format(cnt - 1))
                if device_conn == 1:
                    print('failed to disconnect device')
            adapter_if = dbus.Interface(self.adapter_obj, "org.bluez.Adapter1")
            adapter_if.RemoveDevice(device)
            ret = True
        except dbus.DBusException as e:
            error(e)
        except Exception as e:
            error(e)
        finally:
            return ret 

    def ble_disconnect_case(self, dev_addr=None):
        """Disconnect from charging case"""
        if dev_addr is None:
            if self.case_addr is None:
                return True 
            dev_addr = self.case_addr
        return self.disconnect(dev_addr)
    
    def ble_disconnect_hearing_aids(self, dev_addr=None):
        """Disconnect from hearing aids"""
        if dev_addr is None:
            if self.hearing_aids_addr is None:
                return True
            dev_addr = self.hearing_aids_addr
        return self.disconnect(dev_addr)

    def ble_send_case(self, data):
        """Send data to connected charging case"""
        self.send(self.case_char_if, [self.charging_case_header] + data)
        return     

    def ble_send_hearing_aids(self, data):
        """Send data to connected hearing aids"""
        self.send(self.hearing_aids_char_if, data)
        return 
    
    def ble_case_connected(self, dev_addr=None):
        """Return True if charging case connected, otherwise False"""
        if dev_addr is None:
            dev_addr = self.case_addr
        dev_path = f"/org/bluez/hci{self.hci_id}/dev_" + dev_addr.replace(":", "_")
        try:
            device = dbus.Interface(self.bus.get_object("org.bluez", dev_path), "org.freedesktop.DBus.Properties")
            ret = device.Get("org.bluez.Device1", "Connected")
            return ret == dbus.Boolean(1)
        except dbus.exceptions as e: 
            print(e)
            return False

    def ble_hearing_aids_connected(self, dev_addr=None):
        """Return True if hearing aids connected, otherwise False"""
        if dev_addr is None:
            dev_addr = self.hearing_aids_addr
        dev_path = f"/org/bluez/hci{self.hci_id}/dev_" + dev_addr.replace(":", "_")
        try:
            device = dbus.Interface(self.bus.get_object("org.bluez", dev_path), "org.freedesktop.DBus.Properties")
            ret = device.Get("org.bluez.Device1", "Connected")
            return ret == dbus.Boolean(1)
        except dbus.exceptions as e: 
            print(e)
            return False
    
    def ble_pair(self, dev_addr=None):
        """Not Implemented Yet"""
        if dev_addr is None:
            dev_addr = self.hearing_aids_addr 
        dev_path = f"/org/bluez/hci{self.hci_id}/dev_" + dev_addr.replace(":", "_")
        print("dev path", dev_path)
        self.ble_scan_on()
        cached = len([x for x in self.om_if.GetManagedObjects() if dev_path in x]) != 0
        print("scan device")
        while not cached:
            print(".", end="")
            time.sleep(0.4)
            cached = len([x for x in self.om_if.GetManagedObjects() if dev_path in x]) != 0 
        ret = False 
        try:
            iface = dbus.Interface(self.bus.get_object("org.bluez", dev_path), "org.bluez.Device1")
            print(iface, type(iface))
            ret = iface.Pair({}) 
            print(ret ,type(ret))
        except dbus.DBusException as e:
            print(e)
        self.ble_scan_off()
        return ret 

    def ble_unpair(self, dev_addr=None):
        """Not Implemented Yet"""
        if dev_addr is None:
            dev_path = self.hearing_aids_addr
        else:
            dev_path = f"/org/bluez/hci{self.hci_id}/dev_{dev_addr}".replace(":","_")
        print("unpair", dev_path)
        hci_path = f"/org/bluez/hci{self.hci_id}"
        try:
            iface = dbus.Interface(self.bus.get_object("org.bluez", hci_path), "org.bluez.Adapter1")
            ret = iface.RemoveDevice(dev_path)
            return ret 
        except dbus.DBusException as e:
            print(e)
            return False
        
    def addr_remove_colon(self,dev_addr:str):
        """given a colon seperated bluetooth addres, return a string of the address without colon"""
        ble_address_without_colons = dev_addr.replace(':', '')
        return ble_address_without_colons
    
    def addr_insert_colon(self,dev_addr:str):
        """given a bluetooth adddress string without colon, return the address with colon seperation"""
        ble_address_with_colons = ':'.join([dev_addr[i:i+2] for i in range(0, len(dev_addr), 2)])
        return ble_address_with_colons
      
# if __name__ == "__main__":
#     ble = BluetoothLib()
#     if True == ble.bt_connect_hearing_aids("12:34:56:78:A0:B3"):
#         # wait some time better
#         time.sleep(5)
#         ble.ble_connect_hearing_aids("12:34:56:78:A0:B3")
#     output = subprocess.check_output(["busctl", "tree", "org.bluez"])
#     print(output.decode())
