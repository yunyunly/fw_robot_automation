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
    def __init__(self):
        self.bus = dbus.SystemBus()
    # get bluez object
        self.bluez_obj = self.bus.get_object("org.bluez", "/org/bluez")
        self.adapter_obj = self.bus.get_object("org.bluez", "/org/bluez/hci0")
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
        dev_path = f'/org/bluez/hci0/dev_{dev_addr}'
        Console(f"Connect To {dev_path}")
        Console("Discovering Device")
        cached = len([x for x in self.om_if.GetManagedObjects() if dev_addr in x]) != 0
        while not cached:
            self.adapter_obj.StartDiscovery(dbus_interface="org.bluez.Adapter1")
            while not cached:
                print("Press Reset Let Device Discovable!!!")
                time.sleep(1)
                print("founded")
                cached = True 
            self.adapter_obj.StopDiscovery(dbus_interface="org.bluez.Adapter1")
        Console("Get Connection State")
        dev_obj = self.bus.get_object("org.bluez", dev_path)
        dev_prop = dbus.Interface(dev_obj, "org.freedesktop.DBus.Properties")
        dev_connected = dev_prop.Get("org.bluez.Device1", "Connected")
        if dev_connected == dbus.Boolean(0):
            print("do connecting...")
            dev_obj.Connect(dbus_interface="org.bluez.Device1")

        # print some info 
        dev_if = dbus.Interface(self.bus.get_object("org.bluez", dev_path), "org.bluez.Device1")
        dev_name = dev_prop.Get("org.bluez.Device1", "Name") 
        dev_addr = dev_prop.Get("org.bluez.Device1", "Address")
        dev_paired = dev_prop.Get("org.bluez.Device1", "Paired")
        dev_connected = dev_prop.Get("org.bluez.Device1", "Connected")

        print("dev info:")
        print("Name: ", dev_name)
        print("Address: ", dev_addr)
        print("Paired: ", dev_paired)
        print("Connected: ", dev_connected)

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
 
    def ble_connect_case(self, addr = "D0:14:11:20:20:18"):
        """Connect to a given address charging case, no matter whether it is cached"""
        print("Blue Connect Case...")
        self.case, self.case_path = self.connect(addr)
        char_path = f'{self.case_path}/service0019/char001a'
        print("Blue Discovering Char...")
        cached = len([x for x in self.om_if.GetManagedObjects() if char_path in x]) != 0
        while not cached:
            print("Discovering service and characteristic...")
            time.sleep(1)
            cached = len([x for x in self.om_if.GetManagedObjects() if char_path in x]) != 0
        self.case_char_if = dbus.Interface(self.bus.get_object("org.bluez", char_path), "org.bluez.GattCharacteristic1")
        print("Case Char Interface", self.case_char_if)
        return 
    
    def ble_connect_hearing_aids(self, addr = "D0:14:11:20:20:18"):
        """Connect to given address hearing aids, no matter whether it is cached"""
        self.hearing_aids, self.hearing_aids_path = self.connect(addr)
        char_path = f'{self.hearing_aids_path}/service0019/char001a' 
        cached = len([x for x in self.om_if.GetManagedObjects() if char_path in x]) != 0
        while not cached:
            print("Discovery service and characteristic")
            time.sleep(1)
            cached = len([x for x in self.om_if.GetManagedObjects() if char_path in x]) != 0
        self.hearing_aids_char_if = dbus.Interface(self.bus.get_object("org.bluez", char_path), "org.bluez.GattCharacteristic1")
        return 

    def ble_disconnect_hearing_aids(self):
        """Not implemented yet"""
        return 

    def ble_disconnect_case(self):
        """Not implemented yet"""
        return 

    def ble_send_case(self, data):
        """Send data to connected charging case"""
        Console("Send To Case")
        self.send(self.case_char_if, [self.charging_case_header] + data)
        return     

    def ble_send_hearing_aids(self, data):
        """Send data to connected hearing aids"""
        self.send(self.hearing_aids_char_if, data)
        return 
      
# if __name__ == "__main__":
#     ble = BluetoothLib()
#     ble.ble_connect_case("D0:14:11:20:20:18")
#     header = [9]
#     cmd = [0,11]
#     desc = [0,0]
#     param = [1] 
#     ble.ble_send_case(header+cmd+desc+param)
