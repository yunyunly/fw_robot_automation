from re import escape
import time
import os
import dbus 
import robot.api.logger 
import subprocess

Console = robot.api.logger.console 
Debug = robot.api.logger.debug 
Info = robot.api.logger.info 
    
class AudioLib(object):
    """
    RPI Audio Control 
    """
    def __init__(self):
        self.id_list = []
        return 
    
    def get_dev_id(self):
        """ Check and update bluetooth sound card information
            
        Examples:
        |Get Dev Id|
        """
        output = ""
        self.id_list = []
        try:
            output = subprocess.check_output(["pactl", "list","cards","short"])
            output = output.decode()
        except:
            output = ""
        for line in output.splitlines():
            if "module-bluez5-device.c" in line:
                line = line.split()
                self.id_list.append(int(line[0]))
        if len(self.id_list) > 0 :
            return self.id_list[0]
        else:
            return -1

    def use_a2dp(self):
        """ Set current bluetooth sound card use profile A2DP 
        
        Examples:
        |Use A2dp|
        """
        if len(self.id_list)==0 :
            raise Exception("No Device Id Found")
        ret = 1 
        try:
            ret = subprocess.check_call(["pactl","set-card-profile", str(self.id_list[0]), "a2dp-sink"])
        except:
            pass
        return ret 

    def use_hfp(self):
        """ Set current bluetooth sound card use profile HFP """
        if len(self.id_list)==0 :
            raise Exception("No Device Id Found")
        ret = 1
        try:
            ret = subprocess.check_call(["pactl","set-card-profile", str(self.id_list[0]), "headset-head-unit"])
        except:
            pass 
        return ret
    
    def play_simple_audio(self, timeout=None):
        if len(self.id_list)==0 :
            raise Exception("No Device Id Found")
        return self.play_audio("/home/firmware/audio/Big Band.wav", timeout) 

    def play_audio(self, filepath:str, timeout=None):
        if len(self.id_list)==0 :
            raise Exception("No Device Id Found")
        ret = 0
        try:
            ret = subprocess.check_call(["paplay", filepath], timeout=timeout, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        except:
            pass
        return ret


if __name__ == "__main__":
    a = AudioLib()
    id = a.get_dev_id()
    if id > 0 :
        a.use_a2dp()
        a.play_simple_audio(3)
