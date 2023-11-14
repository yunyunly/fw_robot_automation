import time
import dbus 
import robot.api.logger 
 

Console = robot.api.logger.console 
Debug = robot.api.logger.debug 
Info = robot.api.logger.info 
    
class BluetoothLib(object):
    """This class is the underlying impl for charging case and hearing aids libraries.

    Do not suggest you use its any API in test cases.
    """
    charging_case_header = 9
    hci_id = 0
    case_addr:str 
    hearing_aids_addr:str
    def __init__(self):
        self.bus = dbus.SystemBus()
    # get bluez object
        self.bluez_obj = self.bus.get_object("org.bluez", "/org/bluez")
        self.adapter_obj = self.bus.get_object("org.bluez", f"/org/bluez/hci{self.hci_id}")
        self.om_if = dbus.Interface(
            self.bus.get_object("org.bluez", "/"), 
            "org.freedesktop.DBus.ObjectManager"
        )
        Console("Bluetooth Inited")
        return 

    def connect(self, addr="D0:14:11:20:20:18"):
        """Connect Device via BLE
        
        Examples:
        |Connect| D0:11:22:33:44:55 |
        """
        dev_addr = addr.replace(":", "_")
        dev_path = f'/org/bluez/hci{self.hci_id}/dev_{dev_addr}'
        Console(f"Connect To {dev_path}")
        Console("scan device")
        cached = len([x for x in self.om_if.GetManagedObjects() if dev_addr in x]) != 0
        while not cached:
            print(".", end="")
            time.sleep(0.4)
            cached = len([x for x in self.om_if.GetManagedObjects() if dev_addr in x]) != 0

        # for i in self.om_if.GetManagedObjects():
        #     print(type(i), i)
        Console("Get Connection State")
        dev_obj = self.bus.get_object("org.bluez", dev_path)
        dev_prop = dbus.Interface(dev_obj, "org.freedesktop.DBus.Properties")
        dev_name = dev_prop.Get("org.bluez.Device1", "Name") 
        dev_addr = dev_prop.Get("org.bluez.Device1", "Address")
        dev_paired = dev_prop.Get("org.bluez.Device1", "Paired")
        dev_connected = dev_prop.Get("org.bluez.Device1", "Connected")

        print("dev info:")
        print("Name: ", dev_name)
        print("Address: ", dev_addr)
        print("Paired: ", dev_paired)
        print("Connected: ", dev_connected)
        if dev_connected == dbus.Boolean(0):
            print("do connecting...")
            dev_obj.Connect(dbus_interface="org.bluez.Device1")

        # print some info 
        dev_if = dbus.Interface(self.bus.get_object("org.bluez", dev_path), "org.bluez.Device1")

        return (dev_obj, dev_path)
    
    def send(self, iface, data):
        """Send data to connected device via BLE 
        
        You should not use it in test cases
        """
        Console(f"WriteValue: {bytearray(data)}")
        iface.WriteValue(bytearray(data), {})
    
    def read(self, iface):
        """Read properties, not recieving
        You should not use it in test cases 
        """
        return iface.ReadValue("")
    
    def get_gatt_char(self, dev_path, srv_id, char_id):
        char_path = f"{dev_path}/{srv_id}/{char_id}"
        cached = len([x for x in self.om_if.GetManagedObjects() if char_path in x]) != 0
        print("scan char")
        while not cached:
            print(".", end="")
            time.sleep(1)
            cached = len([x for x in self.om_if.GetManagedObjects() if char_path in x]) != 0
        return dbus.Interface(self.bus.get_object("org.bluez", char_path), "org.bluez.GattCharacteristic1")

    def ble_scan_on(self):
        try:
            # try add a filter, but failed
            #filter = dict()
            #uuids = []
            #ha_uuid = "77425F8F-A696-7968-9038-35E1531ADC77"
            #cc_uuid = "12121212-1212-1212-1212-121212121212"
            #uuids.append(dbus.String(ha_uuid))
            #uuids.append(dbus.String(cc_uuid))
            #filter.update({"UUIDs" :  uuids})
            #self.adapter_obj.SetDiscoveryFilter(filter, dbus_interface="org.bluez.Adapter1")
            #print(self.adapter_obj.GetDiscoveryFilters(dbus_interface="org.bluez.Adapter1"))
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
        self.ble_scan_on()
        self.hearing_aids, self.hearing_aids_path = self.connect(addr)
        self.hearing_aids_char_if = self.get_gatt_char(self.hearing_aids_path, "service001a", "char001f")
        print("HA Char Interface", self.hearing_aids_char_if)
        self.hearing_aids_addr = addr
        self.ble_scan_off()
        return 
    
    def ble_disconnect_case(self, dev_addr=None):
        """Not implemented yet"""
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
        """Not work well"""
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
        """Not work well"""
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
      
# if __name__ == "__main__":
#     ble = BluetoothLib()
#     ble.ble_connect_hearing_aids("12:34:56:78:A0:B3")
#     print(ble.ble_hearing_aids_connected("12:34:56:78:A0:B3"))
#
#     ble.ble_disconnect_hearing_aids()

