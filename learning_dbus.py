import pgi
pgi.install_as_gi()
from gi.repository import Gio

bus_type = Gio.BusType.SYSTEM
bus_name = 'org.bluez'
object_path = '/'
mngr_iface = 'org.freedesktop.DBus.ObjectManager'
device_iface = 'org.bluez.Device1'
device_addr = 'D0:14:11:FF:21:98'

mngr_proxy = Gio.DBusProxy.new_for_bus_sync(
    bus_type=bus_type,
    flags=Gio.DBusProxyFlags.NONE,
    info=None,
    name=bus_name,
    object_path=object_path,
    interface_name=mngr_iface,
    cancellable=None
)

mngd_objs = mngr_proxy.GetManagedObjects()
for obj_path, obj_data in mngd_objs.items():
    address = obj_data.get(device_iface, {}).get('Address')
    if address and address == device_addr:
        print(f'Device [{device_addr}] on object path: {obj_path}')
        