from BluetoothLib import BluetoothLib 
import json 
import os
import sys 
from config.robot_defs import ROBOTC 
from config.robot_defs import SIDE 
from config.robot_defs import BUTTON
import robot.api.logger as Logger 

""" 
def struct{
    u16 cmd_id
    u16 cmd_params
    u8  params[16]
} ble msg
"""

__version__ = "0.2"
class ChargingCaseLib:
    """Library for control charging case

       Most operations are implemented as sending bluetooth low energy message to charging case    
    """
    ROBOT_LIBRARY_SCOPE = "SUITE"

    def __init__(self):
        self.blue = BluetoothLib()
        print("ChargingCase Inited")
        return 
    
    def reset(self):
        """Let charging case Reset to refresh state.
        
        Examples:
        |Reset|
        """
        cmd = [(ROBOTC.RESET.value >> 8) & 0xff, ROBOTC.RESET.value & 0xff]
        desc = [0,0]
        param = []
        self.blue.ble_send_case(cmd+desc+param)
        return 


    def connect_charging_case(self, addr="D0:14:11:20:20:18"):
        """Connect To charging case before you send any message to it.  
        
        Examples:
        |Connect Charging Case| D0:14:11:20:20:18|
        """
        Logger.info("Call Blue Connect Case")
        self.blue.ble_connect_case(addr)
        return 

    def disconnect_charging_case(self):
        """Disconnect charging case.  
        
        Examples:
        |Disconnect Charging Case|
        """
        print("Call Blue Disconnect Case")
        self.blue.ble_connect_case() 
 
    def print_info(self):
        """Print common information of charging case via serial port  
        
        No return, should handle the result via parsing serial port
        Examples:
        |Print Info|
        """
        cmd = [(ROBOTC.PRINT_INFO.value >> 8) & 0xff, ROBOTC.PRINT_INFO.value & 0xff]
        desc = [0, 0]
        self.blue.ble_send_case(cmd+desc)
        return 
    
    def plug_in(self):
        """Let charging case call plug in handler  

        Examples:
        |Plug In|
        """
        cmd = [(ROBOTC.PLUG_IN.value >> 8) & 0xff, ROBOTC.PLUG_IN.value & 0xff]
        desc = [0, 0]
        self.blue.ble_send_case(cmd+desc)       
        return 

    def plug_out(self):
        """Let charging case call plug out handler  

        Examples:
        |Plug Out|
        """
        cmd = [(ROBOTC.PLUG_OUT.value >> 8) & 0xff, ROBOTC.PLUG_OUT.value & 0xff]
        desc = [0, 0]
        self.blue.ble_send_case(cmd+desc)
        return

    def case_open(self):
        """Let charging case call case open handler  
 
        Examples:
        |Case Open|
        """        
        value = ROBOTC.CASE_OPEN.value 
        cmd = [(value >> 8) & 0xff, value & 0xff]
        desc = [0, 0]
        self.blue.ble_send_case(cmd+desc)
        return 
    
    def case_close(self):
        """Let charging case call case close handler 

        Examples:
        |Case Close|
        """        
        value = ROBOTC.CASE_CLOSE.value 
        cmd = [(value >> 8) & 0xff, value & 0xff]
        desc = [0, 0]
        self.blue.ble_send_case(cmd+desc)
        return 

    def dock(self, side: str):
        """Let charging case call dock hearing aids handler

        Examples:
        |Dock|Left|
        |Dock|Right|
        |Dock|Both|
        """
        value = ROBOTC.DOCK.value 
        param = []
        if side == "Left":
            param = [SIDE.LEFT.value]
        elif side == "Right":
            param = [SIDE.RIGHT.value]
        elif side == "Both":
            param = [SIDE.BOTH.value]
        else:
            raise Exception("Invalid Dock Side")
        cmd = [(value >> 8) & 0xff, value & 0xff]
        desc = [0, 0]
        self.blue.ble_send_case(cmd+desc+param)
        return 

    def undock(self, side: str):
        """Let charging case call undock hearing aids handler

        Examples:
        |Undock|Left|
        |Undock|Right|
        |Undock|Both|
        """        
        value = ROBOTC.UNDOCK.value
        param = []
        if side == "Left":
            param = [SIDE.LEFT.value]
        elif side == "Right":
            param = [SIDE.RIGHT.value]
        elif side == "Both":
            param = [SIDE.BOTH.value]
        else:
            raise Exception("Invalid Undock Side")
        cmd = [(value >> 8) & 0xff, value & 0xff]
        desc = [0, 0]
        self.blue.ble_send_case(cmd+desc+param)
        return 
    
    def press_button(self, button: str, long: str = ""):
        """Let charging case call button press handler
        
        Examples:
        |Press Button| Fn |
        |Press Button| Fn | Long|
        |Press Button| Left |
        |Press Button| Right |
        |Press Button| Reset |
        |Press Button| Reset | Long |
        """
        value = ROBOTC.PRESS_BUTTON.value 
        param = []
        if button == "Fn":
            param = [BUTTON.FN.value]
            if long == "Long":
                param = [BUTTON.FN_LONG.value]
        elif button == "Reset":
            param = [BUTTON.RST.value]
            if long == "Long":
                param = [BUTTON.RST_LONG.value]
        elif button == "Left":
            param = [BUTTON.LEFT.value]
        elif button == "Right":
            param = [BUTTON.RIGHT.value]
        else:
            raise Exception("Invalid Press Button")
        cmd = [(value >> 8) & 0xff, value & 0xff]
        desc = [0, 0]
        self.blue.ble_send_case(cmd+desc+param)
        return 

    def request_hearing_aids_soc(self, side: str):
        """Let charging case request hearing aids' soc 

        Examples:
        |Request Hearing Aids Soc| Left |
        |Request Hearing Aids Soc| Right |
        |Request Hearing Aids Soc| Both |
        """        
        value = ROBOTC.REQUEST_BATTERY.value 
        param = []
        if side == "Left":
            param = [SIDE.LEFT.value]
        elif side == "Right":
            param = [SIDE.RIGHT.value]
        elif side == "Both":
            param = [SIDE.BOTH.value]
        else:
            raise Exception("Invalid Soc Side")
        cmd = [(value >> 8) & 0xff, value & 0xff]
        desc = [0, 0]
        self.blue.ble_send_case(cmd+desc+param)
        return 
    
    def generate_pulse(self, side: str):
        """Let charging case generate a pulse sequence

        Exampls:
        |Generate Pulse| Left |
        |Generate Pulse| Right |
        |Generate Pulse| Both |
        """
        value = ROBOTC.GEN_PULSE.value
        param = []
        if side == "Left":
            param = [SIDE.LEFT.value]
        elif side == "Right":
            param = [SIDE.RIGHT.value]
        elif side == "Both":
            param = [SIDE.BOTH.value]
        else:
            raise Exception("Invalid Pulse Side")
        cmd = [(value >> 8) & 0xff, value & 0xff]
        desc = [0, 0]
        self.blue.ble_send_case(cmd+desc+param)       
        return 
    
    def charge_hearing_aids(self, side: str):
        """Let charging case call charging hearing aids handler 
        
        Examples:

        |Charge Hearing Aids| Left |
        |Charge Hearing Aids| Right|
        |Charge Hearing Aids| Both |
        """
        value = ROBOTC.CHARGE_HEARING_AIDS.value
        param = []
        if side == "Left":
            param = [SIDE.LEFT.value] 
        elif side == "Right":
            param = [SIDE.RIGHT.value] 
        elif side == "Both":
            param = [SIDE.BOTH.value]
        else:
            raise Exception("Invalid Chg Side")
        cmd = [(value >> 8) & 0xff, value & 0xff]
        desc = [0, 0]
        self.blue.ble_send_case(cmd+desc+param)       
        return 

    def charge_hearing_aids_stop(self, side: str):
        """Let charging case call stop charge hearing aids handler

        Examples:

        |Charge Hearing Aids Stop| Left |
        |Charge Hearing Aids Stop| Right |
        |Charge Hearing Aids Stop| Both |
        """        
        value = ROBOTC.CHARGE_HEARING_AIDS_STOP.value
        param = []
        if side == "Left":
            param = [SIDE.LEFT.value] 
        elif side == "Right":
            param = [SIDE.RIGHT.value] 
        elif side == "Both":
            param = [SIDE.BOTH.value]
        else:
            raise Exception("Invalid Chg Stop Side")
        cmd = [(value >> 8) & 0xff, value & 0xff]
        desc = [0, 0]
        self.blue.ble_send_case(cmd+desc+param)       
        return 

    def case_connect_hearing_aids(self):
        """Let charging case call connecting handler

        Examples:
        |Case Connect Hearing Aids|
        """ 
        value = ROBOTC.CONNECT_HEARING_AIDS.value 
        cmd = [(value >> 8) & 0xff, value & 0xff]
        desc = [0, 0]
        param = []
        self.blue.ble_send_case(cmd+desc+param)       
        return 
    
    def case_disconnect_hearing_aids(self):
        """Let charging case call disconnecing handler

        Examples:
        |Case Disconnect Hearing Aids|
        """ 
        value = ROBOTC.DISCONNECT_HEARING_AIDS.value 
        cmd = [(value >> 8) & 0xff, value & 0xff]
        desc = [0, 0]
        param = []
        self.blue.ble_send_case(cmd+desc+param)       
        return 

    def single_wire_send(self, side: str, data: str):
        """Let charging case send given message to hearing aids via single wire
        
        Examples:
        |Single Wire Send| Left | 01ff00 |
        |Single Wire Send| Right | 01ffff |
        |Single Wire Send| Both | 01ff06010203040506 |
        """
        value = ROBOTC.SINGLE_WIRE_SND.value 
        param = []
        if side == "Left":
            param = [SIDE.LEFT.value] 
        elif side == "Right":
            param = [SIDE.RIGHT.value] 
        elif side == "Both":
            param = [SIDE.BOTH.value]
        else:
            raise Exception("Invalid Snd Side")
        for i in range(0, len(data)):
            if (i & 0x1) == 1:
                continue
            v = int(data[i:i+2],16)
            param.append(v)
        cmd = [(value >> 8) & 0xff, value & 0xff]
        desc = [0,0]
        self.blue.ble_send_case(cmd+desc+param)       
        return 

    def single_wire_request(self, side:str, data:str):
        """Let charging case send given message to hearing aids and wait for response via single wire
        
        Examples:
        |Single Wire Request| Left | 01ff00 |
        |Single Wire Request| Right | 01ffff |
        |Single Wire Request| Both | 01ff06010203040506 |
        """
        value = ROBOTC.SINGLE_WIRE_REQ.value 
        param = []
        if side == "Left":
            param = [SIDE.LEFT.value] 
        elif side == "Right":
            param = [SIDE.RIGHT.value] 
        elif side == "Both":
            param = [SIDE.BOTH.value]
        else:
            raise Exception("Invalid Req Side")
        for i in range(0, len(data)):
            if (i & 0x1) == 1:
                continue
            v = int(data[i:i+2],16)
            param.append(v)
        cmd = [(value >> 8) & 0xff, value & 0xff]
        desc = [0,0]
        self.blue.ble_send_case(cmd+desc+param)       

        return 



# if __name__ == "__main__":
#     cc = ChargingCaseLib()
    #cc.single_wire_send()
    #cc.case_close()
    #cc.print_info()

