from BluetoothLib import BluetoothLib 
import json 
import os
import sys 
from config.robot_defs import ROBOTC 
from config.robot_defs import ROBOTE
from config.robot_defs import CHIP
from config.robot_defs import SIDE 
from config.robot_defs import MODE0 

from config.robot_defs import BUTTON
from config.robot_defs import CMD_TPYE, CHECK, CONTROL, AUDIO, CASE_RELATED_WITH_APP, ECHO_CONTROL
import robot.api.logger as Logger 

""" 
def struct{
    u8  class  
    u8  cmd_type
    u16 length 
    u8  params[16]
} ble msg
"""

def u16ToField(x:int) -> list:
    if x >= 0 and x <= 65535:
        return [(x & 0xff00) >> 8, x & 0x00ff]
    else:
        raise Exception("Over/Under flow")

__version__ = "0.1"
class HearingAidsLib:
    """Library for control hearing aids.

       Most operations are implemented as sending ble message to hearing aids.  

       The implementations of hearing aids callback are structed in BLE handler function, you can find whether a API's callback exist. 
    """
    ROBOT_LIBRARY_SCOPE = "SUITE"

    def __init__(self):
        self.blue = BluetoothLib()
        print("HearingAid Inited")
        return 

    def connect_hearing_aids(self, addr):
        """Connect To hearing aid before you send any message to it.  
        
        Examples:
        | Connect Hearing Aid | D0:14:11:20:20:18 |
        """
        self.blue.ble_connect_hearing_aids(addr)
        return 
    
    def connect_hearing_aids_classic(self, addr):
        """Connect To hearing aid classic bluetooth to access media point.  
        
        Examples:
        | Connect Hearing Aid | D0:14:11:20:20:18 |
        """
        self.blue.bt_connect_hearing_aids(addr)
        return 
    
    def disconnect_hearing_aids(self, addr):
        """Disconnect To hearing aids, both le and classic.  
        
        Examples:
        | Disconnect Hearing Aid | D0:14:11:20:20:18 |
        """
        self.blue.ble_disconnect_hearing_aids(addr)
        return 
    
    def hearing_aids_connected(self, addr=None)-> bool:
        """Return True if hearing aids connected via bluetooth, otherwise False

        Examples:
        | ${ret}=    | Hearing Aids Connected |
        """
        return self.blue.ble_hearing_aids_connected(addr)
    
    def log_innoise_state(self):
        """Let hearing aids print a log that shows innoise state 

        Examples:
        | Log Innoise State |
        """
        head = u16ToField(ROBOTE.LOG_INNOISE_STATE.value)
        cmd = head + [0,0]
        self.blue.ble_send_hearing_aids(cmd)
    
    def log_bf_state(self):
        """Let hearing aids print a log that shows beamforming state

        Examples:
        | Log Bf State |
        """
        head = u16ToField(ROBOTE.LOG_BF_STATE.value)
        cmd = head + [0,0]
        self.blue.ble_send_hearing_aids(cmd)
    
    def log_volume(self):
        """Let hearing aids print a log that shows volume

        Examples:
        | Log Volume |
        """
        head = u16ToField(ROBOTE.LOG_VOLUME.value)
        cmd = head + [0,0]
        self.blue.ble_send_hearing_aids(cmd)
    
    def log_wear_state(self):
        """Let hearing aids print a log that shows wear on/wear off state

        Examples:
        | Log Wear State |
        """
        head = u16ToField(ROBOTE.LOG_WEAR_STATE.value)
        cmd = head + [0,0]
        self.blue.ble_send_hearing_aids(cmd)

    def log_a2dp_state(self):
        """Let hearing aids print a log that shows a2dp state

        Examples:
        | Log A2dp State |
        """
        head = u16ToField(ROBOTE.LOG_A2DP_STATE.value)
        cmd = head + [0,0]
        self.blue.ble_send_hearing_aids(cmd)
    
    def log_hfp_state(self):
        """Let hearing aids print a log that shows hfp state

        Examples:
        | Log Hfp State |
        """
        head = u16ToField(ROBOTE.LOG_HFP_STATE.value)
        cmd = head + [0,0]
        self.blue.ble_send_hearing_aids(cmd)
    
    def log_tws_state(self):
        """Let hearing aids print a log that shows tws state (whether two hearing aids are connected?)

        Examples:
        | Log Tws State |
        """
        head = u16ToField(ROBOTE.LOG_TWS_STATE.value)
        cmd = head + [0,0]
        self.blue.ble_send_hearing_aids(cmd)
    
    def log_volt(self):
        """Let hearing aids print a log that shows battery voltage 

        Examples:
        | Log Volt |
        """
        head = u16ToField(ROBOTE.LOG_VOLT.value)
        cmd = head + [0,0]
        self.blue.ble_send_hearing_aids(cmd)
    
    def log_soc(self):
        """Let hearing aids print a log that shows soc 

        Examples:
        | Log Soc |
        """
        head = u16ToField(ROBOTE.LOG_SOC.value)
        cmd = head + [0,0]
        self.blue.ble_send_hearing_aids(cmd)
    
    def log_mcu_freq(self, core):
        """Let hearing aids print a log that shows mcu frequency

        Examples:
        | Log Mcu Freq | M55 |
        | Log Mcu Freq | M33 |
        """
        head = u16ToField(ROBOTE.LOG_MCU_FREQ.value)
        content: list
        if core == "M55":
            content = [CHIP.M55.value]
        elif core == "M33":
            content = [CHIP.M33.value]
        else:
            raise Exception()
        length = u16ToField(len(content))
        cmd = head + length + content 
        self.blue.ble_send_hearing_aids(cmd)
    
    def wear_on(self, side):
        """Let hearing aids somulate a wear on

        Examples:
        | Wear On | Left |
        | Wear On | Right |
        | Wear On | Both |
        """
        head = u16ToField(ROBOTE.WEAR_ON.value)
        content:list
        if side == "Left":
            content = [SIDE.LEFT.value]
        elif side == "Right":
            content = [SIDE.RIGHT.value]
        elif side == "Both":
            content = [SIDE.BOTH.value]
        else:
            raise Exception()
        length = u16ToField(len(content))
        cmd = head + length + content 
        self.blue.ble_send_hearing_aids(cmd)
    
    def wear_off(self, side):
        """Let hearing aids simulate a wear off 

        Examples:
        | Wear Off | Left |
        | Wear Off | Right |
        | Wear Off | Both |
        """
        head = u16ToField(ROBOTE.WEAR_OFF.value)
        content:list
        if side == "Left":
            content = [SIDE.LEFT.value]
        elif side == "Right":
            content = [SIDE.RIGHT.value]
        elif side == "Both":
            content = [SIDE.BOTH.value]
        else:
            raise Exception()
        length = u16ToField(len(content))
        cmd = head + length + content 
        self.blue.ble_send_hearing_aids(cmd)
    
    def double_tap(self, side):
        """Let hearing aids simulate a double tap 

        Examples:
        | Double Tap | Left |
        | Double Tap | Right |
        | Double Tap | Both |
        """
        head = u16ToField(ROBOTE.DOUBLE_TAP.value)
        content:list
        if side == "Left":
            content = [SIDE.LEFT.value]
        elif side == "Right":
            content = [SIDE.RIGHT.value]
        elif side == "Both":
            content = [SIDE.BOTH.value]
        else:
            raise Exception()
        length = u16ToField(len(content))
        cmd = head + length + content 
        self.blue.ble_send_hearing_aids(cmd)

    def reset(self, side):
        """Let hearing aids reset

        Examples:
        | Reset | Left |
        | Reset | Right |
        | Reset | Both |
        """
        head = u16ToField(ROBOTE.RESET.value)
        content:list
        if side == "Left":
            content = [SIDE.LEFT.value]
        elif side == "Right":
            content = [SIDE.RIGHT.value]
        elif side == "Both":
            content = [SIDE.BOTH.value]
        else:
            raise Exception()
        length = u16ToField(len(content))
        cmd = head + length + content 
        self.blue.ble_send_hearing_aids(cmd)

    def power_off(self, side):
        """Let hearing aids power off

        Examples:
        | Power Off | Left |
        | Power Off | Right | 
        | Power Off | Both |
        """
        head = u16ToField(ROBOTE.POWER_OFF.value)
        content:list
        if side == "Left":
            content = [SIDE.LEFT.value]
        elif side == "Right":
            content = [SIDE.RIGHT.value]
        elif side == "Both":
            content = [SIDE.BOTH.value]
        else:
            raise Exception()
        length = u16ToField(len(content))
        cmd = head + length + content 
        self.blue.ble_send_hearing_aids(cmd)

    def switch_mode(self, mode):
        """Let hearing aids switch to a given mode

        Examples:
        |  Switch Mode | Normal |
        |  Switch Mode | Innoise | 
        |  Switch Mode | Remote Fitting |
        |  Switch Mode | ANSI |
        |  Switch Mode | Hearing Test |
        """
        head = u16ToField(ROBOTE.SWITCH_DEVICE_MODE.value)
        content:list 
        match mode:
            case "Normal":
                content = [MODE0.NORMAL.value]
            case "Innoise":
                content = [MODE0.INNOISE.value]
            case "Remote Fitting":
                content = [MODE0.REMOTE_FITTING.value]
            case "ANSI":
                content = [MODE0.ANSI.value]
            case "Hearing Test":
                content = [MODE0.HEARING_TEST.value]
            case _:
                raise Exception() 
        length = u16ToField(len(content))
        cmd = head + length + content
        self.blue.ble_send_hearing_aids(cmd)
    
    def switch_beamforming(self, on):
        """Let hearing aids turn on/turn off beamforming

        Examples:
        |  Switch Beamforming | On |
        |  Switch Beamforming | Off | 
        """
        head = u16ToField(ROBOTE.SWITCH_BEAMFORMING.value)
        content:list 
        match on:
            case "On":
                content = [1]
            case "Off":
                content = [0]
            case _:
                raise Exception() 
        length = u16ToField(len(content))
        cmd = head + length + content
        self.blue.ble_send_hearing_aids(cmd)
    
    def switch_afc(self, on):
        """Not Supported by Orka now, Don't Use It!
        Let hearing aids turn on/turn off AFC

        Examples:
        |  Switch Beamforming | On |
        |  Switch Beamforming | Off | 
        """
        head = u16ToField(ROBOTE.SWITCH_BEAMFORMING.value)
        content:list 
        match on:
            case "On":
                content = [MODE0.NORMAL.value]
            case "Off":
                content = [MODE0.INNOISE.value]
            case _:
                raise Exception() 
        length = u16ToField(len(content))
        cmd = head + length + content
        self.blue.ble_send_hearing_aids(cmd)

    # def check_general_status(self):
    #     cmd = [CMD_TPYE.STATUS_CHECK.value, CHECK.CHECK_GENERAL_STATUS.value,0x00,0x00]
    #     self.blue.ble_send_hearing_aids(cmd)
    #     return 
    # 
    # def check_startup_info(self):
    #     cmd = [CMD_TPYE.STATUS_CHECK.value, CHECK.START_UP_CHECK_STATUS.value]
    #     self.blue.ble_send_hearing_aids(cmd)
    #     return
    # 
    # def fetch_bt_device_info(self):
    #
    #     cmd = [CMD_TPYE.STATUS_CHECK.value, CHECK.START_UP_CHECK_STATUS.value]
    #     self.blue.ble_send_hearing_aids(cmd)
    #     return
    



# if __name__ == "__main__":
#     cc = HearingAidsLib()
#     cc.connect_hearing_aids("12:34:56:78:A0:B3")
#     cc.log_soc()
#     cc.log_volt()
#     cc.switch_mode("Normal")
#     cc.switch_mode("Innoise")
#     cc.switch_beamforming("On")
