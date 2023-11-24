import time
from pyftdi.ftdi import Ftdi
from pyftdi.usbtools import UsbToolsError
import robot.api.logger 

Console = robot.api.logger.console 
Debug = robot.api.logger.debug 
Info = robot.api.logger.info 

class PreludeControlLib:
    def __init__(self):
        self.RESET1 = 0x01
        self.RESET2 = 0x02
        self.VCHARGER1 = 0x04
        self.VCHARGER2 = 0x08
        self.POW1 = 0x10
        self.POW2 = 0x20
        self.ft_handle = Ftdi()
        self.ft_handle.open_bitbang_from_url("ftdi://ftdi:4232:FT66ORKA/1")
        self.ft_handle.set_bitmode(0xFF, Ftdi.BitMode.BITBANG)
        self.ft_handle.read_data_set_chunksize(4096)
        self.ft_handle.write_data_set_chunksize(4096)
        self.ft_handle.set_event_char(0, False)
        self.ft_handle.set_latency_timer(16)
        self.ft_handle.set_flowctrl("")
        self.ft_handle.set_baudrate(62500)
        self.__communicate_ftdi(0xff, 0)
    
    def __new__(cls):
        if not hasattr(cls, 'instance'):
            cls.instance = super(PreludeControlLib, cls).__new__(cls)
        return cls.instance
    
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
    prelude.charge("off", "lr")
    time.sleep(0.1)
    prelude.charge("on", "lr")
    time.sleep(1)
    prelude.reset("on", "lr")
    time.sleep(0.1)
    prelude.reset("off", "lr")
    prelude.close_ftdi()
