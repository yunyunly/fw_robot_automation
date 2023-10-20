import time
import dbus
    

class BluetoothLib(object):
    charging_case_header = 9
    def __init__(self):
        self.bus = dbus.SystemBus()
        print("SystemBus :", self.bus)
    
    # get bluez object
        self.bluez_obj = self.bus.get_object("org.bluez", "/org/bluez")
        self.adapter_obj = self.bus.get_object("org.bluez", "/org/bluez/hci0")
        self.om_if = dbus.Interface(
            self.bus.get_object("org.bluez", "/"), 
            "org.freedesktop.DBus.ObjectManager"
        )
    
        return 

    def connect(self, addr="D0:14:11:20:20:18"):
            dev_addr = addr.replace(":", "_")
            dev_path = f'/org/bluez/hci0/dev_{dev_addr}'
            cached = len([x for x in self.om_if.GetManagedObjects() if dev_addr in x]) != 0
            if not cached:
                self.adapter_obj.StartDiscovery(dbus_interface="org.bluez.Adapter1")
                while not cached:
                    print("Press Reset Let Device Discovable!!!")
                    time.sleep(1)
                    print("founded")
                    cached = True 
                self.adapter_obj.StopDiscovery(dbus_interface="org.bluez.Adapter1")
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
        iface.WriteValue(bytearray(data), {})
    
    def read(self, iface):
        return iface.ReadValue("")
 
    def ble_connect_case(self, addr = "D0:14:11:20:20:18"):
        self.case, self.case_path = self.connect(addr)
        char_path = f'{self.case_path}/service0019/char001a' 
        cached = len([x for x in self.om_if.GetManagedObjects() if char_path in x]) != 0
        while not cached:
            print("Discovery service and characteristic")
            time.sleep(1)
            cached = len([x for x in self.om_if.GetManagedObjects() if char_path in x]) != 0
        self.case_char_if = dbus.Interface(self.bus.get_object("org.bluez", char_path), "org.bluez.GattCharacteristic1")
        return 
    
    def ble_connect_hearing_aids(self, addr = "D0:14:11:20:20:18"):
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
        return 

    def ble_disconnect_case(self):
        return 

    def ble_send_case(self, data):
        self.send(self.case_char_if, [self.charging_case_header] + data)
        return     

    def ble_send_hearing_aids(self, data):
        self.send(self.hearing_aids_char_if, data)
        return 
      
    # check and connect dev 

if __name__ == "__main__":
    ble = BluetoothLib()
    ble.ble_connect_case("D0:14:11:20:20:18")
    header = [9]
    cmd = [0,0]
    desc = [0,0]
    param = [] 
    ble.ble_send_case(header+cmd+desc+param)

