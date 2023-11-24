import os
import time
import subprocess
import PreludeControlLib
import robot.api.logger
import select
import fcntl

Console = robot.api.logger.console 
Debug = robot.api.logger.debug 
Info = robot.api.logger.info 

class BurnLib:
    def __init__(self, burn_tool_path=None):
        self.burning:dict = {"l":False, "r":False}
        self.burn_process:dict = {"l":None, "r":None}
        self.uart_port:dict = {"l":"/dev/ttyUSB2", "r":"/dev/ttyUSB3"}
        self.return_code:dict = {"l":None, "r":None}
        self.factory_section_bin:dict = {"l": "left.bin", "r": "right.bin"}
        if burn_tool_path:
            self.burn_tool_path = burn_tool_path
        else:
            self.burn_tool_path = os.path.join("/home/km4sh/dev/infra/tools/dldtool-ubuntu-v1.4")
        try:
            self.prelude = PreludeControlLib.PreludeControlLib()
        except PreludeControlLib.UsbToolsError:
            raise RuntimeError("PreludeControlLib init failed.")
        
    def __new__(cls):
        if not hasattr(cls, 'instance'):
            cls.instance = super(BurnLib, cls).__new__(cls)
        return cls.instance
        
    def __prelude_handshake(self, device):
        self.prelude.charge("off", device)
        time.sleep(0.5)
        self.prelude.charge("on", device)
        time.sleep(0.2)
        self.prelude.reset("on", device)
        time.sleep(0.5)
        self.prelude.reset("off", device)

    def __burn_one_side(self, device:str, programmer:str, filename:str, bootloader:str, factory_section_bin:str, erase_chip:bool):
        device = device.lower()
        if self.burning[device] == True:
            raise RuntimeError(f"Device: {device} already burning.")
        _burn_command = [f"{self.burn_tool_path}/dldtool"]
        if erase_chip:
            _burn_command.append(f"--erase-chip")
        _burn_command.append(f"-v -b 921600")
        _burn_command.append(f"{self.uart_port[device]}")
        _burn_command.append(f"{os.path.join(self.burn_tool_path, programmer)}")
        _burn_command.append(f"-m 0x34020000")
        _burn_command.append(f"{os.path.join(self.burn_tool_path, filename)}")
        _burn_command.append(f"{os.path.join(self.burn_tool_path, bootloader)}")
        _burn_command.append(f"{os.path.join(self.burn_tool_path, factory_section_bin)}")
        Info(f"Burn command({device}): {' '.join(_burn_command)}")
        self.burn_process[device] = subprocess.Popen(' '.join(_burn_command), stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
        self.burning[device] = True

    def burn(
        self,
        device:str="lr",
        programmer:str="programmer1600.bin",
        filename:str="best1600_tws.bin",
        bootloader:str="ota_boot_2700_20211216_5fca0c3e.bin",
        erase_chip:str="erase_chip",
        factory_section_bin:str="",
    ):
        device = device.lower()
        self.programmer = programmer
        self.filename = filename
        self.bootloader = bootloader
        self.erase_chip = erase_chip
        
        if "l" not in device and "r" not in device:
            raise ValueError("No valid device ('L' or 'R' or 'LR') found.")

        for d in device:
            self.__burn_one_side(
                device=d,
                programmer=programmer,
                filename=filename,
                bootloader=bootloader,
                factory_section_bin=self.factory_section_bin[d] if factory_section_bin=="" else factory_section_bin,
                erase_chip=True if erase_chip=="erase_chip" else False
            )
            Info(f"Waiting for {d.upper()} prelude handshake...")
            time.sleep(1)
            self.__prelude_handshake(d)
            Info(f"{d.upper()} prelude handshake done.")

        self.return_code["l"] = None
        self.return_code["r"] = None
        while True:
            for d in device:
                if self.burning[d] == True:
                    self.return_code[d] = self.burn_process[d].poll()
                    stdout = self.burn_process[d].stdout.read().decode('ascii')
                    stderr = self.burn_process[d].stderr.read().decode('ascii')
                    Info(f"[{d.upper()}:]{stdout}")
                    Debug(f"[{d.upper()}:]{stderr}")
                    if self.return_code[d] is not None:
                        self.burning[d] = False
                        if self.return_code[d] != 0:
                            raise RuntimeError(f"Burn failed. Return Code: {self.return_code[d]}")
            if not any(self.burning.values()):
                break
        return 0
    
# if __name__ == "__main__":
#     burn = BurnLib()
#     burn.burn(device="lr", erase_chip="erase_chip")
