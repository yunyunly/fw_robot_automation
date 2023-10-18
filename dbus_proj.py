import time
import dbus
import pgi 
pgi.install_as_gi()
from gi.repository import GLib
from dbus import mainloop
import dbus.mainloop.glib

class BluetoothController:
    def __init__(self):
        dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
        self.bus = dbus.SystemBus()
        self.adapter_path = self.find_adapter()
        self.device_interface = 'org.bluez.Device1'
        self.connected_device = None

    def find_adapter(self):
        remote_om = dbus.Interface(self.bus.get_object('org.bluez', '/'), 'org.freedesktop.DBus.ObjectManager')
        objects = remote_om.GetManagedObjects()
        for path, interfaces in objects.items():
            if 'org.bluez.Adapter1' in interfaces:
                return path
        raise Exception('Bluetooth adapter not found')

    def is_device_existed(self, device_address):
        try:
            device_path = f'{self.adapter_path}/{device_address.replace(":", "_")}'
            device = dbus.Interface(self.bus.get_object('org.bluez', device_path), self.device_interface)
            return True
        except dbus.exceptions.DBusException:
            return False

    def connect_to_device(self, device_address):
        if self.connected_device:
            self.disconnect_device()
        device_path = f'{self.adapter_path}/{device_address.replace(":", "_")}'
        device = dbus.Interface(self.bus.get_object('org.bluez', device_path), self.device_interface)
        device.Connect()
        self.connected_device = device

    def disconnect_device(self):
        if self.connected_device:
            self.connected_device.Disconnect()
            self.connected_device = None

    def send_gatt_command(self, command):
        if self.connected_device:
            gatt_service_uuid = 'your_gatt_service_uuid'  # Replace with your GATT service UUID
            characteristic_path = 'your_characteristic_path'  # Replace with the actual characteristic path
            device_path = self.connected_device.object_path
            device = dbus.Interface(self.bus.get_object('org.bluez', device_path), self.device_interface)
            services = device.Get('org.bluez.Device1', 'UUIDs', dbus_interface='org.freedesktop.DBus.Properties')
            service_path = None
            for service in services:
                if gatt_service_uuid in service:
                    service_path = service
                    break
            if not service_path:
                raise Exception('GATT service not found')
            characteristic = dbus.Interface(
                self.bus.get_object('org.bluez', service_path),
                'org.bluez.GattService1'
            ).GetCharacteristic(characteristic_path)
            characteristic.WriteValue(command, {})
        else:
            raise Exception('Not connected to any device')

    def register_gatt_callback(self, device_address, callback):
        if not self.is_device_existed(device_address):
            raise Exception('Device not found')
        device_path = f'{self.adapter_path}/{device_address.replace(":", "_")}'
        device = dbus.Interface(self.bus.get_object('org.bluez', device_path), self.device_interface)
        services = device.Get('org.bluez.Device1', 'UUIDs', dbus_interface='org.freedesktop.DBus.Properties')
        gatt_service_uuid = 'your_gatt_service_uuid'  # Replace with your GATT service UUID
        service_path = None
        for service in services:
            if gatt_service_uuid in service:
                service_path = service
                break
        if not service_path:
            raise Exception('GATT service not found')
        characteristic_path = 'your_characteristic_path'  # Replace with the actual characteristic path
        char_properties = dbus.Interface(
            self.bus.get_object('org.bluez', characteristic_path),
            'org.freedesktop.DBus.Properties'
        )
        char_properties.Set('org.bluez.GattCharacteristic1', 'Value', dbus.Array([], signature='y'))

        def notification_handler(interface, changed_properties, invalidated_properties):
            if 'Value' in changed_properties:
                value = changed_properties['Value']
                callback(value)  # Call the provided callback function with the received value

        self.bus.add_signal_receiver(
            notification_handler,
            dbus_interface='org.freedesktop.DBus.Properties',
            signal_name='PropertiesChanged',
            arg0='org.bluez.GattCharacteristic1',
            path=characteristic_path
        )

if __name__ == '__main__':
        # def gatt_callback(value):
        #     print(f'Received GATT command: {value}')
        #
        # controller = BluetoothController()
        # device_address = 'D8:3A:DD:5C:0A:B3'  # Replace with the BLE device address you want to connect to
        #
        # if controller.is_device_existed(device_address):
        #     controller.connect_to_device(device_address)
        #     controller.register_gatt_callback(device_address, gatt_callback)
        #     print(f'Connected to device with address: {device_address}')
        #     print('Listening for GATT commands. Press Ctrl+C to exit.')
        #     try:
        #         while True:
        #             time.sleep(1)  # Keep the program running
        #     except KeyboardInterrupt:
        #         pass
        #     finally:
        #         controller.disconnect_device()
        # else:
    dbus.mainloop.glib.DBusGMainLoop(set_as_default = True)
    sys_bus = dbus.SystemBus()
    print("SystemBus :", sys_bus)
    
    # get bluez object
    bluezObj = sys_bus.get_object("org.bluez", "/org/bluez")

    dev_addr = "D0:14:11:20:20:18"
    dev_path = f'/org/bluez/hci0/dev_{dev_addr.replace(":", "_")}'
    # get device1 interface
    dev_obj = sys_bus.get_object("org.bluez", dev_path)
    dev_if = dbus.Interface(sys_bus.get_object("org.bluez", dev_path), "org.bluez.Device1")
    dev_prop = dbus.Interface(dev_if, "org.freedesktop.DBus.Properties")
    print("dev Name :", dev_prop.Get("org.bluez.Device1", "Name"))
    print("dev All :", dev_prop.GetAll("org.bluez.Device1"))
    char_path = f'{dev_path}/service0019/char001a' 
    # get gatt interface
    char_obj = sys_bus.get_object("org.bluez", char_path)
    char_if = dbus.Interface(sys_bus.get_object("org.bluez", char_path), "org.bluez.GattCharacteristic1")
    print("dev if:", dev_if)
    print("char if:", char_if)
    #print(char_if.get_dbus_method("Connect", dbus_interface="org.bluez.Device1")(["ee","as"]))
    #dev_if.Connect()
    print("dict", char_if.ReadValue.__dict__)
    print("dir", char_if.ReadValue.__dir__())
    #help(char_if.ReadValue)
    #dbus.Interface(sys_bus.get_object("org.bluez", )
    print(char_obj.ReadValue("", dbus_interface="org.bluez.GattCharacteristic1"))
    print(char_obj.WriteValue(bytearray([00,00,00]), {}, dbus_interface="org.bluez.GattCharacteristic1"))
    #mainloop = GLib.MainLoop()
    #mainloop.run()
    #char_if.StartNotify()
    # --
    #bluezIf = dbus.Interface(bluezObj, "org.freedesktop.DBus.ObjectManager")
    #print(bluezIf)

    # --
    #bluezObjs = bluezIf.GetManagedObjects()
    #print(type(bluezObjs))
    #print(bluezObjs.__dir__())
    #adapter_path = "/org/bluez/hci0"
    #for k, v in bluezObjs.items():
        
        #char_uuid = v.get("org.bluez.GattCharacteristic1", {}).get("UUID")
        # if char_uuid == "21212121-2121-2121-2121-212121212121":         
        #print("path/UUID", k, char_uuid)
    
    

        # device_path = f'{self.adapter_path}/{device_address.replace(":", "_")}'
        #     device = dbus.Interface(self.bus.get_object('org.bluez', device_path), self.device_interface)
        #     device.Connect()
        #     self.connected_device = device

