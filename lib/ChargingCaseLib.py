from BluetoothLib import BluetoothLib 
import json 
import os
import sys 
sys.path.append("../config")
from cmd_defs import ROBOTC
import robot.api.logger as Logger 

""" 
def struct{
    u16 cmd_id
    u16 cmd_params
    u8  params[16]
}
"""

root_path = os.path.abspath(os.path.join(os.path.abspath(__file__), os.path.pardir, os.path.pardir))
print(root_path)
raw_map_file = open(os.path.join(root_path,"config", "blue_pigeon_defs.json"))
#raw_map = json.load(raw_map_file)

cmd_map = json.load(raw_map_file)
print(cmd_map)
print(int(cmd_map["robotc"]["Request Battery Left"], 16))

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
     
    def connect_charging_case(self, addr="D0:14:11:20:20:18"):
        Logger.info("Call Blue Connect Case")
        self.blue.ble_connect_case(addr)
        return 

    def disconnect_charging_case(self):
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
        value = 0
        if side == "Left":
            value = ROBOTC.DOCK_LEFT.value 
        elif side == "Right":
            value = ROBOTC.DOCK_RIGHT.value 
        elif side == "Both":
            value = ROBOTC.DOCK_BOTH.value
        else:
            raise Exception("Invalid Dock Side")
        cmd = [(value >> 8) & 0xff, value & 0xff]
        desc = [0, 0]
        self.blue.ble_send_case(cmd+desc)
        return 

    def undock(self, side: str):
        """Let charging case call undock hearing aids handler

        Examples:
        |Undock|Left|
        |Undock|Right|
        |Undock|Both|
        """        
        value = 0
        if side == "Left":
            value = ROBOTC.UNDOCK_LEFT.value 
        elif side == "Right":
            value = ROBOTC.UNDOCK_RIGHT.value 
        elif side == "Both":
            value = ROBOTC.UNDOCK_BOTH.value
        else:
            raise Exception("Invalid Dock Side")
        cmd = [(value >> 8) & 0xff, value & 0xff]
        desc = [0, 0]
        self.blue.ble_send_case(cmd+desc)
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
        value = 0
        if button == "Fn":
            value = ROBOTC.PRESS_FN.value 
            if long == "Long":
                value = ROBOTC.PRESS_FN_LONG.value 
        elif button == "Reset":
            value = ROBOTC.PRESS_RESET.value
            if long == "Long":
                value = ROBOTC.PRESS_RESET_LONG.value 
        elif button == "Left":
            value = ROBOTC.PRESS_LEFT.value
        elif button == "Right":
            value = ROBOTC.PRESS_RIGHT.value 
        else:
            raise Exception("Invalid Press Button")
        cmd = [(value >> 8) & 0xff, value & 0xff]
        desc = [0, 0]
        self.blue.ble_send_case(cmd+desc)
        return 

    def get_hearing_aids_soc(self, side: str):
        """Let charging case request hearing aids' soc 

        Examples:
        |Get Hearing Aids Soc| Left |
        |Get Hearing Aids Soc| Right |
        |Get Hearing Aids Soc| Both |
        """        
        value = 0
        if side == "Left":
            value = ROBOTC.REQUEST_BATTERY_LEFT.value 
        elif side == "Right":
            value = ROBOTC.REQUEST_BATTERY_RIGHT.value 
        elif side == "Both":
            value = ROBOTC.REQUEST_BATTERY_BOTH.value 
        else:
            raise Exception("Invalid Battery Side")
        cmd = [(value >> 8) & 0xff, value & 0xff]
        desc = [0, 0]
        self.blue.ble_send_case(cmd+desc)
        return 
    
    def generate_pulse(self):
        """Let charging case generate a pulse sequence

        Exampls:
        |Generate Pulse|
        """
        value = ROBOTC.NOT_IMPLEMENTED_YET.value
        cmd = [(value >> 8) & 0xff, value & 0xff]
        desc = [0, 0]
        self.blue.ble_send_case(cmd+desc)       
        return 

    def discharge(self, side:str):
        """Let charging case call discharge handler

        Examples:
        |Discharge|
        """        
        value = ROBOTC.NOT_IMPLEMENTED_YET.value
        cmd = [(value >> 8) & 0xff, value & 0xff]
        desc = [0, 0]
        self.blue.ble_send_case(cmd+desc)       
        return 
    def case_connect_hearing_aids(self):
        """Let charging case call connecting handler

        Examples:
        |Case Connect Hearing Aids|
        """ 
        return 
    
    def case_disconnect_hearing_aids(self):
        """Let charging case call disconnecing handler

        Examples:
        |Case Disconnect Hearing Aids|
        """    
        return 



if __name__ == "__main__":
    cc = ChargingCaseLib()
    cc.connect_charging_case()
    cc.print_info()
