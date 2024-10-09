import os
import re
import time
import subprocess
import PreludeControlLib
import robot.api.logger
import pty

Console = robot.api.logger.console 
Debug = robot.api.logger.debug 
Info = robot.api.logger.info 

class BurnLib:
    ROBOT_LIBRARY_SCOPE = 'SUITE'
    def __init__(self, burn_tool_path=None):
        self.burning:dict = {"l":False, "r":False, "c":False}
        self.burn_process:dict = {"l":None, "r":None, "c":None}
        self.uart_port:dict = {"l":"/dev/ttyUSB2", "r":"/dev/ttyUSB3"}
        self.return_code:dict = {"l":None, "r":None, "c":None}
        self.factory_section_bin:dict = {"l": "left.bin", "r": "right.bin"}
        if burn_tool_path:
            self.burn_tool_path = burn_tool_path
        else:
            pwd = os.path.dirname(os.path.abspath(__file__))
            self.burn_tool_path = os.path.join(os.path.dirname(pwd), "tools")
        self.orka_tool_path = os.path.join(self.burn_tool_path, "dldtool")
        self.echo_tool_path = os.path.join(self.burn_tool_path, "echo")
        self.prelude = None
        self.master,self.slave = pty.openpty()
        
    def __del__(self):
        if self.prelude:
            self.prelude.close_ftdi()

    def __new__(cls):
        if not hasattr(cls, 'instance'):
            cls.instance = super(BurnLib, cls).__new__(cls)
        return cls.instance
    
    def __remove_ansi_escape_codes(self, text):
        """ Remove ansi escape codes.
            Args:
                text: text to remove ansi escape codes
        """
        ansi_escape = re.compile(r'\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])')
        return ansi_escape.sub('', text)
        
    def __prelude_handshake(self, device, prelude_id:str="1"):
        """ Handshake with prelude.
            Args:
                device: device to burn, 'l' or 'r'
        """
        if self.prelude is None:
            self.prelude = PreludeControlLib.PreludeControlLib()
            self.prelude.open_device(prelude_id)
        self.prelude.reset("off", device)
        time.sleep(0.5)
        self.prelude.reset("on", device)
        time.sleep(0.5)
        self.prelude.reset("off", device)
        time.sleep(0.5)
        self.prelude.charge("off", device)
        time.sleep(0.5)
        self.prelude.charge("on", device)
        time.sleep(0.2)

    def __prelude_handshake_with_bus(self, device, bus:str="1", dev:str="1"):
        """ Handshake with prelude.
            Args:
                device: device to burn, 'l' or 'r'
        """
        if self.prelude is None:
            self.prelude = PreludeControlLib.PreludeControlLib()
            self.prelude.open_device_with_bus(bus,dev)
        self.prelude.reset("off", device)
        time.sleep(0.5)
        self.prelude.reset("on", device)
        time.sleep(0.5)
        self.prelude.reset("off", device)
        time.sleep(0.5)
        self.prelude.charge("off", device)
        time.sleep(0.5)
        self.prelude.charge("on", device)
        time.sleep(0.2)

    def __burn_one_side(self, device:str, programmer:str, filename:str, bootloader:str, factory_section_bin:str, erase_chip:bool):
        """ Burn one side of orka device.
            Args:
                device: device to burn, 'l' or 'r'
                programmer: programmer bin file name
                filename: firmware bin file name
                bootloader: bootloader bin file name
                factory_section_bin: factory section bin file name (bt/ble names and addresses)
                erase_chip: erase chip before burn
        """
        device = device.lower()
        if self.burning[device] == True:
            raise RuntimeError(f"Device: {device} already burning.")
        _burn_command = [f"{self.orka_tool_path}/dldtool"]
        if erase_chip:
            _burn_command.append(f"--erase-chip")
        _burn_command.append(f"-v -b 921600")
        _burn_command.append(f"{self.uart_port[device]}")
        _burn_command.append(f"{os.path.join(self.orka_tool_path, programmer)}")
        _burn_command.append(f"-m 0x34020000")
        _burn_command.append(f"{os.path.join(self.orka_tool_path, filename)}")
        _burn_command.append(f"{os.path.join(self.orka_tool_path, bootloader)}")
        _burn_command.append(f"{os.path.join(self.orka_tool_path, factory_section_bin)}")
        Info(f"Burn command({device}): {' '.join(_burn_command)}")
        self.burn_process[device] = subprocess.Popen(' '.join(_burn_command), stdin=self.slave, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
        self.burning[device] = True
    
    def update_ha_port(self, port_left:str="/dev/ttyUSB2", port_right:str="/dev/ttyUSB3"):
        self.uart_port["l"]=port_left
        self.uart_port["r"]=port_right

    def burn_orka(
        self,
        prelude_id: str="1",
        device:str="lr",
        programmer:str="programmer1600.bin",
        filename:str="best1600_tws.bin",
        bootloader:str="ota_boot_2700_20211216_5fca0c3e.bin",
        erase_chip:str="erase_chip",
        factory_section_bin:str="",
    ):
        """ Burn orka device.
            Args:
                device: device to burn, 'l' or 'r' or 'lr'
                programmer: programmer bin file name
                filename: firmware bin file name
                bootloader: bootloader bin file name
                erase_chip: erase chip before burn
                factory_section_bin: factory section bin file name (bt/ble names and addresses)
        """
        device = device.lower()
        self.programmer = programmer
        self.filename = filename
        self.bootloader = bootloader
        self.erase_chip = erase_chip
        if self.prelude is None:
            self.prelude = PreludeControlLib.PreludeControlLib()
            self.prelude.open_device(prelude_id)
        if "l" not in device and "r" not in device:
            raise ValueError("No valid device ('L' or 'R' or 'LR') found.")
        self.prelude.charge("off", device)
        time.sleep(0.5)
        self.prelude.charge("on", device)
        time.sleep(3)
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
            self.__prelude_handshake(d,prelude_id=prelude_id)
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
        time.sleep(0.5)               #additional prelude commands to make sure has is on
        self.prelude.charge("off", device)
        time.sleep(0.5)
        self.prelude.charge("on", device)
        time.sleep(0.2)
        self.prelude.reset("on", device)
        time.sleep(0.5)
        self.prelude.reset("off", device)
        time.sleep(0.5)
        self.prelude.charge("off", device)
        return 0
    
    def reset_orka_by_5v(
        self,
        prelude_id: str="1",
        device:str="lr",
    ):
        """ Reset orka device by 5v.
            Args:
                device: device to burn, 'l' or 'r' or 'lr'
        """
        device = device.lower()

        if self.prelude is None:
            self.prelude = PreludeControlLib.PreludeControlLib()
            self.prelude.open_device(prelude_id)
        if "l" not in device and "r" not in device:
            raise ValueError("No valid device ('L' or 'R' or 'LR') found.")
        self.prelude.charge("on", device)
        time.sleep(0.5)
        print('***** start reset ******')
        # ...0101 0100 1101 010...
        self.prelude.charge("off", device)
        time.sleep(0.005)
        self.prelude.charge("on", device)
        time.sleep(0.005)
        self.prelude.charge("off", device)
        time.sleep(0.005)
        self.prelude.charge("on", device)
        time.sleep(0.005)

        self.prelude.charge("off", device)
        time.sleep(0.005)
        self.prelude.charge("on", device)
        time.sleep(0.005)
        self.prelude.charge("off", device)
        time.sleep(0.005)
        self.prelude.charge("off", device)
        time.sleep(0.005)

        self.prelude.charge("on", device)
        time.sleep(0.005)
        self.prelude.charge("on", device)
        time.sleep(0.005)
        self.prelude.charge("off", device)
        time.sleep(0.005)
        self.prelude.charge("on", device)
        
        time.sleep(0.005)
        self.prelude.charge("off", device)
        time.sleep(0.005)
        self.prelude.charge("on", device)
        time.sleep(0.005)
        self.prelude.charge("off", device)
        time.sleep(0.005)
        self.prelude.charge("on", device)
        time.sleep(0.5)
        self.prelude.charge("off", device)
        print('***** end reset ******')
        return 0
        
    def burn_orka_with_bus(
        self,
        bus:str="1", 
        dev:str="1",
        device:str="lr",
        programmer:str="programmer1600.bin",
        filename:str="best1600_tws.bin",
        bootloader:str="ota_boot_2700_20211216_5fca0c3e.bin",
        erase_chip:str="erase_chip",
        factory_section_bin:str="",
    ):
        """ Burn orka device.
            Args:
                device: device to burn, 'l' or 'r' or 'lr'
                programmer: programmer bin file name
                filename: firmware bin file name
                bootloader: bootloader bin file name
                erase_chip: erase chip before burn
                factory_section_bin: factory section bin file name (bt/ble names and addresses)
        """
        device = device.lower()
        self.programmer = programmer
        self.filename = filename
        self.bootloader = bootloader
        self.erase_chip = erase_chip
        if self.prelude is None:
            self.prelude = PreludeControlLib.PreludeControlLib()
            self.prelude.open_device_with_bus(bus,dev)
        if "l" not in device and "r" not in device:
            raise ValueError("No valid device ('L' or 'R' or 'LR') found.")
        self.prelude.charge("off", device)
        time.sleep(0.5)
        self.prelude.charge("on", device)
        time.sleep(3)
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
            self.__prelude_handshake_with_bus(d,bus=bus,dev=dev)
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
        time.sleep(0.5)               #additional prelude commands to make sure has is on
        self.prelude.charge("off", device)
        time.sleep(0.5)
        self.prelude.charge("on", device)
        time.sleep(0.2)
        self.prelude.reset("on", device)
        time.sleep(0.5)
        self.prelude.reset("off", device)
        time.sleep(0.5)
        self.prelude.charge("off", device)
        return 0
    
    def burn_echo(
        self,
        filename:str="CC-v2.0.9.0.hex",
        bootloader:str="CC-OTA_bootloader.hex",
    ):
        """ Burn echo device.
            Args:
                tool_path: path of STM32_Programmer.sh
                filename: firmware hex file name
                bootloader: bootloader hex file name
        """
        if self.burning["c"] == True:
            raise RuntimeError(f"Device: c already burning.")
        
        _burn_command = [f"STM32_Programmer.sh"]
        _burn_command.append(f"-c  port=SWD freq=4000 ap=0 mode=UR -hardRst")
        _burn_command.append(f"-d {os.path.join(self.echo_tool_path, filename)}")
        _burn_command.append(f"-d {os.path.join(self.echo_tool_path, bootloader)}")
        _burn_command.append(f"--start 0x08000000")
        Info(f"Burn command(c): {' '.join(_burn_command)}")
        self.burn_process["c"] = subprocess.Popen(' '.join(_burn_command), stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
        self.burning["c"] = True
        self.return_code["c"] = None
        while True:
            if self.burning["c"] == True:
                self.return_code["c"] = self.burn_process["c"].poll()
                stdout = self.burn_process["c"].stdout.read().decode('ascii')
                stderr = self.burn_process["c"].stderr.read().decode('ascii')
                Info(f"[C:]{self.__remove_ansi_escape_codes(stdout)}")
                Debug(f"[C:]{self.__remove_ansi_escape_codes(stderr)}")
                if self.return_code["c"] is not None:
                    self.burning["c"] = False
                    if self.return_code["c"] != 0:
                        raise RuntimeError(f"Burn failed. Return Code: {self.return_code['c']}")
            if not any(self.burning.values()):
                break
        return 0
if __name__ == "__main__":
    burn = BurnLib()
    burn.reset_orka_by_5v(device="lr")
