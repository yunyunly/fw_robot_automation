from logging import error
import time
import dbus 
import robot.api.logger 
import subprocess

Console = robot.api.logger.console 
Debug = robot.api.logger.debug 
Info = robot.api.logger.info 
    
class BluetoothLib(object):
    """This class is the underlying impl for charging case and hearing aids bluetooth related libraries.

    Do not suggest you use its any API in test cases, you should use HearingAidsLib or ChargingCaseLib.
    """
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

    def connect(self, addr="D0:14:11:20:20:18"):
        """Connect Device via bluetoothctl
        
        Examples:
        | Connect | D0:11:22:33:44:55 |
        """
        dev_addr = addr.replace(":", "_")
        dev_path = f'/org/bluez/hci{self.hci_id}/dev_{dev_addr}'
        while dev_path not in self.om_if.GetManagedObjects().keys():
            time.sleep(0.4)
            #print(self.om_if.GetManagedObjects().keys())

        dev_obj = self.bus.get_object("org.bluez", dev_path)
        dev_prop = dbus.Interface(dev_obj, "org.freedesktop.DBus.Properties")
        try:
            print("connecting...")
            dev_obj.Connect(dbus_interface="org.bluez.Device1")
        except:
            try: 
                print("connecting...")
                dev_obj.Connect(dbus_interface="org.bluez.Device1")
            except Exception as e:
                error(e)
        print("post check connected: ", dev_prop.Get("org.bluez.Device1", "Connected"))
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
        while char_path not in self.om_if.GetManagedObjects():
            print("scan char...")
            time.sleep(1)
        return dbus.Interface(self.bus.get_object("org.bluez", char_path), "org.bluez.GattCharacteristic1")

    def ble_scan_on(self):
        try:
            filter = dict()
            self.adapter_obj.SetDiscoveryFilter(filter, dbus_interface="org.bluez.Adapter1")
            self.adapter_obj.StartDiscovery(dbus_interface="org.bluez.Adapter1")
        except:
            raise Exception("scan on failed")
    
    def ble_scan_on_le_only(self):
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
        self.ble_scan_on()
        self.case, self.case_path = self.connect(addr)
        self.case_char_if = self.get_gatt_char(self.case_path, "service0019", "char001a")
        print("Case Char Interface", self.case_char_if)
        self.case_addr = addr
        self.ble_scan_off()
        return 
    
    def ble_connect_hearing_aids(self, addr = "D0:14:11:20:20:18"):
        """Connect to given address hearing aids, no matter whether it is cached"""
        print("Blue Connect Hearing Aids...")
        managed_objects = self.om_if.GetManagedObjects()
        obj_path = f'/org/bluez/hci{self.hci_id}/dev_{addr.replace(":","_")}'
        if obj_path in managed_objects.keys():
            adapter_if = dbus.Interface(self.adapter_obj, "org.bluez.Adapter1")
            adapter_if.RemoveDevice(obj_path)
        time.sleep(1)
        print("conneting bredr...")
        self.ble_scan_on_bredr_only()
        self.hearing_aids, self.hearing_aids_path = self.connect(addr)
        self.ble_scan_off()
        print("bredr connected")
        
        self.ble_scan_on_le_only()
        print("connecting le...")
        time.sleep(5)
        self.hearing_aids, self.hearing_aids_path = self.connect(addr)
        self.ble_scan_off()
        print("le connected")

        time.sleep(1)
        print("connecting char...")
        self.ble_scan_on()
        self.hearing_aids_char_if = self.get_gatt_char(self.hearing_aids_path, "service001a", "char001f")
        self.hearing_aids_addr = addr
        self.ble_scan_off()
        print("char connected")
        return 
    
    def ble_disconnect_case(self, dev_addr=None):
        """Disconnect from charging case"""
        if dev_addr is None:
            dev_addr = self.case_addr
        device_path = f"/org/bluez/hci{self.hci_id}/dev_" + dev_addr.replace(":", "_")
        device = dbus.Interface(self.bus.get_object("org.bluez", device_path),"org.bluez.Device1")
        ret = False 
        try:
            device.Disconnect()
            ret = True 
        except dbus.DBusException as e:
            print(e)
        return ret  
    
    def ble_disconnect_hearing_aids(self, dev_addr=None):
        """Disconnect from hearing aids"""
        if dev_addr is None:
            dev_addr = self.hearing_aids_addr
        device_path = f"/org/bluez/hci{self.hci_id}/dev_" + dev_addr.replace(":", "_")
        device = dbus.Interface(self.bus.get_object("org.bluez", device_path),"org.bluez.Device1")
        device.Disconnect()
        return
    
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
      
#if __name__ == "__main__":
#    ble = BluetoothLib()
#    ble.ble_connect_hearing_aids("12:34:56:78:A0:B3")
#    ble.ble_send_hearing_aids([9,0,0,0,0])
