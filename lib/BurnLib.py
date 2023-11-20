import os
import time
import subprocess
import PreludeControlLib
import robot.api.logger
import fcntl

Console = robot.api.logger.console 
Debug = robot.api.logger.debug 
Info = robot.api.logger.info 

class BurnLib:
    def __init__(self, burn_tool_path=None):
        
        self.burning:bool = False
        if burn_tool_path:
            self.burn_tool_path = burn_tool_path
        else:
            self.burn_tool_path = os.path.join("/home/km4sh/dev/infra/tools/dldtool-ubuntu-v1.4")
        self.prelude = PreludeControlLib.PreludeControlLib()
        
    def __new__(cls):
        if not hasattr(cls, 'instance'):
            cls.instance = super(BurnLib, cls).__new__(cls)
        return cls.instance
    
    def __non_blocking_read(self, output):
        fd = output.fileno()
        fl = fcntl.fcntl(fd, fcntl.F_GETFL)
        fcntl.fcntl(fd, fcntl.F_SETFL, fl | os.O_NONBLOCK)
        try:
            return output.read()
        except:
            return ""

    def burn(
        self,
        programmer:str="programmer1600.bin",
        filename:str="best1600_tws.bin",
        bootloader:str="ota_boot_2700_20211216_5fca0c3e.bin",
        erase_chip:bool=True,
    ):
        if self.burning:
            raise RuntimeError("Already burning.")
        self.burning = True
        
        _burn_command = [f"{self.burn_tool_path}/dldtool"]
        _burn_command.append(f"{'--erase-chip' if erase_chip else ''}")
        _burn_command.append(f"/dev/ttyUSB2")
        _burn_command.append(f"{os.path.join(self.burn_tool_path, programmer)}")
        _burn_command.append(f"{os.path.join(self.burn_tool_path, filename)}")
        _burn_command.append(f"{os.path.join(self.burn_tool_path, bootloader)}")
        burn_device_a = subprocess.Popen(_burn_command, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        self.prelude.charge("on")
        time.sleep(1)
        self.prelude.reset("on")
        time.sleep(0.1)
        self.prelude.reset("off")
        
        # wait burning process, and check if finished
        while True:
            ret = burn_device_a.poll()
            if ret is not None:
                Console(f"Return Value: {ret}")
                break
            time.sleep(0.1)

        self.burning = False
        return True
