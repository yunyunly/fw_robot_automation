from pyftdi.ftdi import Ftdi
import time

class PreludeControl:
    def __init__(self):
        self.RESET1 = 0x01
        self.RESET2 = 0x02
        self.VCHARGER1 = 0x04
        self.VCHARGER2 = 0x08
        self.POW1 = 0x10
        self.POW2 = 0x20
        Ftdi.show_devices()
        self.ft_handle = Ftdi()
        self.ft_handle.open_bitbang_from_url("ftdi://ftdi:4232:FT66ORKA/1")
        self.ft_handle.set_bitmode(0xFF, Ftdi.BitMode.BITBANG)
        self.ft_handle.read_data_set_chunksize(4096)
        self.ft_handle.write_data_set_chunksize(4096)
        self.ft_handle.set_event_char(0, False)
        self.ft_handle.set_latency_timer(16)
        self.ft_handle.set_flowctrl("")
        self.ft_handle.set_baudrate(62500)
        self.communicate_ftdi(0xff, 0)
    
    def communicate_ftdi(self, gpio, state):
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
    
    def charge(self, enable):
        if enable:
            self.communicate_ftdi(self.VCHARGER1|self.VCHARGER2, 1)
        else:
            self.communicate_ftdi(self.VCHARGER1|self.VCHARGER2, 0)

    def reset(self, enable):
        if enable:
            self.communicate_ftdi(self.RESET1|self.RESET2, 1)
        else:
            self.communicate_ftdi(self.RESET1|self.RESET2, 0)
            
    def close_ftdi(self):
        self.ft_handle.close(freeze=True)


if __name__ == "__main__":
    prelude = PreludeControl()
    print("prelude inited.")
    time.sleep(0.5)
    prelude.reset(1)
    time.sleep(0.5)
    prelude.reset(0)
    time.sleep(0.5)
    prelude.reset(1)
    time.sleep(0.5)
    prelude.reset(0)
    prelude.close_ftdi()

# Assuming you have the necessary definitions for Ftdi class methods,
# you can use the class as follows:

# gpio_setter = GPIO_SetDxConfig()
# gpio_setter.set_dx_config(gpio_setter.DEVICE1PID, 0x04, 1)

# Assuming you have the necessary definitions for FT_OpenEx, FT_Close, FT_SetUSBParameters,
# FT_SetChars, FT_SetTimeouts, FT_SetLatencyTimer, FT_SetFlowControl, FT_SetBaudRate,
# FT_SetBitMode, FT_Read, and FT_Write, you can use the class as follows:

# gpio_setter = GPIO_SetDxConfig()
# gpio_setter.set_dx_config(gpio_setter.DEVICE1PID, 0x04, 1)