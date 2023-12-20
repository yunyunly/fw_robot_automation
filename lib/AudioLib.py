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
    ROBOT_LIBRARY_SCOPE = 'SUITE'
    def __init__(self):
        self.id_list = []
        return 
    
    def __new__(cls):
        if not hasattr(cls, 'instance'):
            cls.instance = super(AudioLib, cls).__new__(cls)
        return cls.instance

    def audio_get_dev_id(self):
        """ Check and update bluetooth sound card information
            
        Examples:
         |  Audio Get Dev Id |
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

    def audio_use_A2DP(self):
        """ Set current bluetooth sound card use profile A2DP 
        
        Examples:
         | Audio Use A2DP |
        """
        if len(self.id_list)==0 :
            raise Exception("No Device Id Found")
        ret = 1 
        try:
            ret = subprocess.check_call(["pactl","set-card-profile", str(self.id_list[0]), "a2dp-sink-sbc"])
        except:
            pass
        return ret 

    def audio_use_HFP(self):
        """ Set current bluetooth sound card use profile HFP 
        
        Examples:
         | Audio Use HFP |
        """
        if len(self.id_list)==0 :
            raise Exception("No Device Id Found")
        ret = 0
        try:
            ret = subprocess.check_call(["pactl","set-card-profile", str(self.id_list[0]), "headset-head-unit"])
        except:
            ret = -1 
        return ret

    def audio_play_simple_audio(self, timeout=None):
        """Examples:
         | Audio Play Simple Audio |
         | ${ret}= | Audio Play Simple Audio |
        """
        if len(self.id_list)==0 :
            raise Exception("No Device Id Found")
        return self.audio_play_audio("/home/firmware/audio/Big Band.wav", timeout) 

    def audio_play_audio(self, filepath:str, timeout=None):
        """Examples:
         | Audio Play Audio |
         | ${ret}=    | Audio Play Audio |
        """
        if len(self.id_list)==0 :
            raise Exception("No Device Id Found")
        ret = 0
        if timeout != None:
            if type(timeout) == type("0"):
                timeout = int(timeout)
        try:
            ret = subprocess.check_call(["paplay", filepath], timeout=timeout, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        except:
            ret = -1
        return ret


# if __name__ == "__main__":
#     a = AudioLib()
#     id = a.audio_get_dev_id()
#     if id > 0 :
#         a.audio_use_a2dp()
#         a.audio_play_simple_audio(3)
