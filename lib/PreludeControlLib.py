import time
from pyftdi.ftdi import Ftdi
import usb.core
import robot.api.logger 

Console = robot.api.logger.console 
Debug = robot.api.logger.debug 
Info = robot.api.logger.info 

class PreludeControlLib:
    ROBOT_LIBRARY_SCOPE = 'SUITE'
    def __init__(self):
        self.RESET1 = 0x01
        self.RESET2 = 0x02
        self.VCHARGER1 = 0x04
        self.VCHARGER2 = 0x08
        self.POW1 = 0x10
        self.POW2 = 0x20
        self.ft_handle = Ftdi()
        self.usb_devices = list()
        self.__find_all_prelude()
    
    def __new__(cls):
        if not hasattr(cls, 'instance'):
            cls.instance = super(PreludeControlLib, cls).__new__(cls)
        return cls.instance

    def __find_all_prelude(self):
        devices = usb.core.find(find_all=True)
        if not devices:
            raise FileNotFoundError("No USB device detected.")
        for device in devices:
            try:
                if device.serial_number == "FT66ORKA":
                    self.usb_devices.append(device)
            except Exception as e:
                pass
        if len(self.usb_devices) == 0:
            raise FileNotFoundError("No Prelude device detected.")
            

    def __communicate_ftdi(self, gpio, state):
        w_data_len = 7
        data_out = bytearray([0] * w_data_len)
        data_read = bytearray([0] * w_data_len)

        data_read = self.ft_handle.read_data(w_data_len)
        for x in range(7):
            data_out[x] = data_read[x]
        data_out[6] = self.ft_handle.read_pins()

        if state == 1:
            data_out[6] |= gpio
        elif state == 0:
            data_out[6] &= ~gpio
        self.ft_handle.write_data(data_out)

        return True
    
    def get_usb_device_descriptor(self, bus, device):
        # Find the USB device by bus and device ID
        dev = usb.core.find(bus=bus, address=device)
        if dev:
            # Get the device descriptor
            return dev
        else:
            return None
    
    def open_device(self, i:str="1"):
        if type(eval(i)) != int:
            raise TypeError
        else:
            index = eval(i)
        if index > len(self.usb_devices):
            raise IndexError("Exceed the number of connected Prelude")
        device = self.usb_devices[index-1]
        Info(f"Opening Prelude: BUS:{device.bus} ADDRESS:{device.address}")
        print(f"Opening Prelude: BUS:{device.bus} ADDRESS:{device.address}")
        try:
            self.ft_handle.open_bitbang_from_device(device)
        except Exception as e:
            Info(f"Open Prelude failed, raise error: {e}")
            raise e
        self.ft_handle.set_bitmode(0xFF, Ftdi.BitMode.BITBANG)
        self.ft_handle.read_data_set_chunksize(4096)
        self.ft_handle.write_data_set_chunksize(4096)
        self.ft_handle.set_event_char(0, False)
        self.ft_handle.set_latency_timer(16)
        self.ft_handle.set_flowctrl("")
        self.ft_handle.set_baudrate(62500)
        self.__communicate_ftdi(0xff, 0)
    
    def open_device_with_bus(self, bus:str="1", dev:str="1"):
        # if type(eval(bus)) != int or type(eval(dev))!= int:
        #     raise TypeError
        # else:
        #     bus_id = eval(bus.lstrip('0'))
        #     dev_id = hex(eval(dev))
            
        # if index > len(self.usb_devices):
        #     raise IndexError("Exceed the number of connected Prelude")
        # device = self.usb_devices[index-1]
        # Info(f"Opening Prelude: BUS:{device.bus} ADDRESS:{device.address}")
        # print(f"Opening Prelude: BUS:{device.bus} ADDRESS:{device.address}")
        # url=f"ftdi://ftdi:4232h:{bus_id}:{dev_id}/1"
        try:
            device = self.get_usb_device_descriptor(int(bus),int(dev))
            self.ft_handle.open_bitbang_from_device(device)
        except Exception as e:
            Info(f"Open Prelude failed, raise error: {e}")
            raise e
        self.ft_handle.set_bitmode(0xFF, Ftdi.BitMode.BITBANG)
        self.ft_handle.read_data_set_chunksize(4096)
        self.ft_handle.write_data_set_chunksize(4096)
        self.ft_handle.set_event_char(0, False)
        self.ft_handle.set_latency_timer(16)
        self.ft_handle.set_flowctrl("")
        self.ft_handle.set_baudrate(62500)
        self.__communicate_ftdi(0xff, 0)

    def charge(self, enable:str="on", device:str="lr"):
        device_pin = 0x00
        enable = enable.lower()
        device = device.lower()
        
        if "l" not in device and "r" not in device:
            raise ValueError("No valid device ('L' or 'R' or 'LR') found.")
        
        if "l" in device:
            device_pin |= self.VCHARGER1
        if "r" in device:
            device_pin |= self.VCHARGER2
    
        if enable == "on" or enable == "true":
            self.__communicate_ftdi(device_pin, 1)
        elif enable == "off" or enable == "false":
            self.__communicate_ftdi(device_pin, 0)
        else:
            raise ValueError("Only 'ON' or 'OFF' is accepted.")

    def reset(self, enable:str="on", device:str="lr"):
        device_pin = 0x00
        enable = enable.lower()
        device = device.lower()
        
        if "l" not in device and "r" not in device:
            raise ValueError("No valid device ('L' or 'R' or 'LR') found.")
        
        if "l" in device:
            device_pin |= self.RESET1
        if "r" in device:
            device_pin |= self.RESET2
            
        if enable == "on" or enable == "true":
            self.__communicate_ftdi(device_pin, 1)
        elif enable == "off" or enable == "false":
            self.__communicate_ftdi(device_pin, 0)
        else:
            raise ValueError("Only 'ON' or 'OFF' is accepted.")
            
    def close_ftdi(self, freeze:str="on"):
        freeze = freeze.lower()
        if freeze == "on" or freeze == "true":
            keep_status = True
        else:
            keep_status = False
        self.ft_handle.close(freeze=keep_status)


if __name__ == "__main__":
    Ftdi.show_devices()
    prelude = PreludeControlLib()
    prelude.open_device("2")
    prelude.charge("off", "lr")
    time.sleep(0.1)
    prelude.charge("off", "lr")
    time.sleep(1)
    prelude.reset("on", "lr")
    time.sleep(0.1)
    prelude.reset("off", "lr")
    prelude.close_ftdi()
