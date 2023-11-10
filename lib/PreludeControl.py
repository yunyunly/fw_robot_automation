from pyftdi.ftdi import Ftdi
from pyftdi import usbtools

class PreludeControl:
    def __init__(self):
        self.DEVICE1PID = 0xACE1
        self.DEVICE2PID = 0xACE2
        self.SWITCHPID = 0xACE3
        self.SCANNERPID = 0xA4A7

        self.DEVICE1SN = "FT66ORKAC"
        self.DEVICE2SN = "FT66ORKAD"
        self.SWITCHSN = "FT66ORKAA"

        self.RESET1 = 0x01
        self.RESET2 = 0x02
        self.VCHARGER1 = 0x04
        self.VCHARGER2 = 0x08
        self.POW1 = 0x10
        self.POW2 = 0x20
        self.NumberOfDevice = 2
        self.SPEAKP = 1
        self.SPEAKN = 0

    def set_dx_config(self, pid, gpio_name, state):
        ftdi = Ftdi()
        
        device_des = b" "

        if pid == self.DEVICE1PID:
            device_des = b"DEVICE1"
        elif pid == self.DEVICE2PID:
            device_des = b"DEVICE2"
        elif pid == self.SWITCHPID:
            device_des = b"SWITCH"

        try:
            ftdi.open_from_url(usbtools.usb_devstr_url(device_des))

            w_data_len = 7
            data_out = bytearray([0] * w_data_len)
            data_read = ftdi.read_data_bytes(w_data_len)

            for x in range(7):
                data_out[x] = data_read[x]

            if state == 1:
                data_out[6] |= gpio_name
            elif state == 0:
                data_out[6] &= ~gpio_name

            ftdi.write_data(data_out)

            print("FT_Write successful")

        except Exception as e:
            print(f"Error: {e}")
            return False

        finally:
            ftdi.close()

        return True

# Assuming you have the necessary definitions for Ftdi class methods,
# you can use the class as follows:

# gpio_setter = GPIO_SetDxConfig()
# gpio_setter.set_dx_config(gpio_setter.DEVICE1PID, 0x04, 1)

# Assuming you have the necessary definitions for FT_OpenEx, FT_Close, FT_SetUSBParameters,
# FT_SetChars, FT_SetTimeouts, FT_SetLatencyTimer, FT_SetFlowControl, FT_SetBaudRate,
# FT_SetBitMode, FT_Read, and FT_Write, you can use the class as follows:

# gpio_setter = GPIO_SetDxConfig()
# gpio_setter.set_dx_config(gpio_setter.DEVICE1PID, 0x04, 1)