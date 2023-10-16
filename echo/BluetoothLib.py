from gi.repository import GLib 
import dbus 
import dbus.mainloop.glib 

class BluetoothLib(object):
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

