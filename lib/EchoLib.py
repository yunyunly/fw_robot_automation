from BluetoothLib import BluetoothLib 
import json 

""" 
def struct{
    u16 cmd_id
    u16 cmd_params
    u8  params[16]
}
"""

raw_map_file = open("bluepigeon_defs.json")
cmd_map = json.load(raw_map_file)


class ChargingCaseLib(object):
    """Library for control charging case

       Most operations are implemented as sending bluetooth low energy message to charging case    
    """

    def __init__(self):
        return 
    
    def _send(self, cmd):

        return 
    
    def connect_case(self, addr="D0:14:11:20:20:18"):
        self.blue = BluetoothLib()
        self.blue.ble_connect_case(addr)

    def print_info(self):
        """Print common information of charging case via serial port  
        
        No return, should handle the result via parsing serial port
        Examples:
        |Print Info|
        """
        self.blue.ble_send_case([01,00,00])
        return 
    
    def plug_in(self):
        """Let charging case call plug in handler  

        Examples:
        |Plug In|
        """
        return 

    def plug_out(self):
        """Let charging case call plug out handler  

        Examples:
        |Plug Out|
        """

        return

    def case_open(self):
        """Let charging case call case open handler  

        Examples:
        |Case Open|
        """
        return 
    
    def case_close(self):
        """Let charging case call case close handler 

        Examples:
        |Case Close|
        """
        return 

    def dock(self, side: str):
        """Let charging case call dock hearing aids handler

        Examples:
        |Dock|Left|
        |Dock|Right|
        |Dock|Both|
        """
        return 

    def undock(self, side: str):
        """Let charging case call undock hearing aids handler

        Examples:
        |Undock|Left|
        |Undock|Right|
        |Undock|Both|
        """
        return 
    
    def press_button(self, button: str, long: str = None):
        """Let charging case call button press handler
        
        Examples:
        |Press Button| Fn |
        |Press Button| Fn | Long|
        |Press Button| Left |
        |Press Button| Right |
        |Press Button| Reset |
        |Press Button| Reset | Long |
        """
        
        return 

    def get_hearing_aids_soc(self):
        """Let charging case request hearing aids' soc 

        Examples:
        |Get Hearing Aids Soc|
        """
        return 
    
    def generate_pulse(self):
        """Let charging case generate a pulse sequence

        Exampls:
        |Generate Pulse|
        """
        return 

    def discharge(self, side:str):
        """Let charging case call discharge handler

        Examples:
        |Discharge|
        """
        return 

    def connect_hearing_aids(self):
        """Let charging case call connecting handler

        Examples:
        |Connect Hearing Aids|
        """
        return 

    def disconnect_hearing_aids(self):
        """Let charging case call disconnecing handler

        Examples:
        |Disconnect Hearing Aids|
        """
        return 

