from BluetoothLib import BluetoothLib 
import json 
import os
import sys 
from config.robot_defs import ROBOTC 
from config.robot_defs import SIDE 
from config.robot_defs import BUTTON
from config.robot_defs import CMD_TPYE, CHECK, CONTROL, AUDIO, CASE_RELATED_WITH_APP, ECHO_CONTROL
import robot.api.logger as Logger 

""" 
def struct{
    u16 cmd_id
    u16 cmd_params
    u8  params[16]
} ble msg
"""

__version__ = "0.1"
class HearingAidLib:
    """Library for control HA

       Most operations are implemented as sending ble message to HA  
    """
    ROBOT_LIBRARY_SCOPE = "SUITE"

    def __init__(self):
        self.blue = BluetoothLib()
        print("HearingAid Inited")
        return 

    def connect_hearing_aid(self, addr="11:11:22:33:33:81"):
        """Connect To hearing aid before you send any message to it.  
        
        Examples:
        |Connect Hearing Aid| D0:14:11:20:20:18|
        """
        Logger.info("Call Blue Connect HA")
        self.blue.ble_connect_hearing_aids(addr)
        return 
    
    def disconnect_hearing_aids(self, addr="11:11:22:33:33:81"):
        """Disconnect To hearing aid before you send any message to it.  
        
        Examples:
        |Disconnect Hearing Aid| D0:14:11:20:20:18|
        """
        Logger.info("Call Blue Disconnect HA")
        self.blue.ble_disconnect_hearing_aids(addr)
        return 
    
    def check_ble_conn_with_HA(self, addr="11:11:22:33:33:81"):
        """Check if ble connected with HA """
        return self.blue.is_ble_connect_hearing_aids(addr)
    
    
    def check_general_status(self):
        """Let HA check general status  

        Examples:
        |Check General Status|
        """
        cmd = [CMD_TPYE.STATUS_CHECK.value, CHECK.CHECK_GENERAL_STATUS.value]
        self.blue.ble_send_hearing_aids(cmd)
        return 
    
    def check_startup_info(self):
        """Let HA check startup info  

        Examples:
        |Check Startup Info|
        """
        cmd = [CMD_TPYE.STATUS_CHECK.value, CHECK.START_UP_CHECK_STATUS.value]
        self.blue.ble_send_hearing_aids(cmd)
        return
    
    def fetch_bt_device_info(self):

        cmd = [CMD_TPYE.STATUS_CHECK.value, CHECK.START_UP_CHECK_STATUS.value]
        self.blue.ble_send_hearing_aids(cmd)
        return
    
    def switch_to_normal_mode(self):
        
        cmd = [CMD_TPYE.AUDIO_CHAIN.value, AUDIO.SWITCH_RUNNING_MODE.value, 0, 1, 0]
        self.blue.ble_send_hearing_aids(cmd)
        return

    def switch_to_innoise_mode(self):
        
        cmd = [CMD_TPYE.AUDIO_CHAIN.value, AUDIO.SWITCH_RUNNING_MODE.value, 0, 1, 1]
        self.blue.ble_send_hearing_aids(cmd)
        return
    
    def turn_on_beamforming(self):
        
        cmd = [CMD_TPYE.AUDIO_CHAIN.value, AUDIO.SET_BEAMFORMING_ONOFF.value, 0, 1, 1]
        self.blue.ble_send_hearing_aids(cmd)
        return
    
    def turn_off_beamforming(self):

        cmd = [CMD_TPYE.AUDIO_CHAIN.value, AUDIO.SET_BEAMFORMING_ONOFF.value, 0, 1, 0]
        self.blue.ble_send_hearing_aids(cmd)
        return
    
    def turn_off_AFC(self):
        # NotImplemented
        # cmd = []
        # self.blue.ble_send_hearing_aids(cmd)
        return

    def turn_on_AFC(self):
        # NotImplemented
        # cmd = []
        # self.blue.ble_send_hearing_aids(cmd)
        return


# if __name__ == "__main__":
#     cc = HearingAidLib()
#     cc.connect_hearing_aid()
#     cc.check_general_status()
