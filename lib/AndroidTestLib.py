import signal
import socket
import sys
import time
import threading
import subprocess
from datetime import datetime
import robot.api.logger

from config.robot_defs import CHIP, MODE0, ROBOTE

Console = robot.api.logger.console 
Debug = robot.api.logger.debug 
Info = robot.api.logger.info 

def adb_start_app(dev:str):
    return f"adb -s {dev} shell am start -n com.hiorka.testsocketserevr/.MainActivity"

def adb_stop_app(dev:str):
    return f"adb -s {dev} shell am force-stop com.hiorka.testsocketserevr"

def adb_forward_port(dev:str, port:int=65432):
    return f"adb -s {dev} reverse tcp:65432 tcp:{port}"

class AndroidTestLib:
    ROBOT_LIBRARY_SCOPE = 'SUITE'
    def __init__(self):
        self.androidDeviceSn = None
        self.socketPort = 65432
        self.androidSocket: socket = None
        self.androidConnected = False
        self.androidBleConnected:str = None
        self.androidBtConnected:str = None
        self.addr = ""
        self.heartBeatThread = None
        self.serverThread = None
        
    def set_android_device(self,sn:str, port=65432):
        """set the android device to be tested

        Args:
            sn (str): the serial number of the android device, which can be found by running 'adb devices' in terminal
            port (int, optional): port on android device to be used for socket connection. Defaults to 65432.
        """
        self.androidDeviceSn = sn
        self.socketPort = port
        if not port is int:
            port = int(port)
        self.run_adb_cmd(adb_forward_port(sn,port))
        try:
            self.run_adb_cmd(adb_stop_app(self.androidDeviceSn))
        except:
            pass
        
    def bt_connect_ha(self,addr,timeout:int=20):
        """Command Android to connect hearing aid via OrkaSDK

        Args:
            addr (_type_): HA bluetooth address, e.g. "12:12:12:12:12:11"
            timeout (int, optional): Connection timeout Defaults to 20.

        Returns:
            Bool: True if connection is successful, False otherwise
        """
        self.__send_message(f"connect bt {addr}")
        for _ in range(timeout*10):
            if self.androidBtConnected == addr:
                return True
            time.sleep(0.1)
        return False
        
    def ble_connect_ha(self,addr:str,timeOut:int=10):
        """Command Android to connect hearing aid via OrkaSDK

        Args:
            addr (str): HA bluetooth address, e.g. "12:12:12:12:12:11"
            timeOut (int, optional): Connection timeout. Defaults to 10.

        Returns:
            Bool: True if connection is successful, False otherwise
        """
        self.__send_message(f"connect ble {addr}")
        for _ in range(timeOut*10):
            if addr == self.androidBleConnected:
                self.addr = addr
                return True
            time.sleep(0.1)
        return False
    
    def ble_disconnect_ha(self,addr:str,timeOut:int=10):
        self.__send_message(f"disconnect")
        for _ in range(timeOut*10):
            if addr != self.androidBleConnected:
                return True
            time.sleep(0.1)
        return False
    
    def android_send_cmd(self,cmd:str):
        """Let android device send a command to hearing aids

        Args:
            cmd (str): command to be sent to hearing aids, in hex string format. e.g. "01010000"

        Returns:
            Bool: True if the command is sent to Android successfully, False otherwise. Does not guarantee the command is executed successfully on hearing aids.
        """
        if self.androidBleConnected != None:
            self.__send_message(f"cmd {cmd}")
            return True
        else:
            Console("Android device or HA not connected.")
            return False
        
    def android_a2dp_start(self):
        """
        Command Android to start A2DP audio streaming
        """
        self.__send_message(f"a2dp play {self.androidBleConnected}")
    
    def android_a2dp_stop(self):
        """
        Command Android to stop A2DP audio streaming
        """
        self.__send_message(f"a2dp stop {self.androidBleConnected}")
        
    def android_hfp_start(self):
        """
        Command Android to start HFP audio streaming
        """
        self.__send_message(f"hfp play {self.androidBleConnected}")
        
    def android_hfp_stop(self):
        """
        Command Android to stop HFP audio streaming
        """
        self.__send_message(f"hfp stop {self.androidBleConnected}")
    
    def run_adb_cmd(self,cmd:str):

        try:
            # Run the command and capture the output and error streams
            result = subprocess.run(cmd, shell=True, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)

            # Access the exit code
            exit_code = result.returncode

            # Check the exit code
            if exit_code == 0:
                Console("Command executed successfully: ",cmd)
            else:
                Console(f"Command failed with exit code {exit_code}: {cmd}")

        except subprocess.CalledProcessError as e:
            # Handle exceptions if the command returns a non-zero exit code
            Console(f"Command failed with exit code {e.returncode}. Error: {e.stderr}, cmd: {cmd}")

    def start_server(self, host='127.0.0.1'):
        def signal_handler(sig, frame):
            print('Stopping server...')
            self.stop_android()
            sys.exit(0)

        signal.signal(signal.SIGINT, signal_handler)
        def server_thread():
            with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
                s.bind((host, self.socketPort))
                s.listen()
                Console(f"Server started on {host}:{self.socketPort}. Waiting for a connection...")
                self.androidConnected = False
                s.settimeout(30)
                try:
                    conn, addr = s.accept()
                except socket.timeout:
                    Console("Connection timed out.")
                    self.stop_android()
                    return
                self.androidSocket = conn
                self.androidSocket.settimeout(15)
                self.androidConnected = True
                with conn:
                    Console(f"Connected by {addr}")
                    while self.androidConnected:
                        try:
                            data = conn.recv(1024)
                        except:
                            Console("Connection lost.")
                            self.stop_android()
                            break
                        if not data:
                            Console("No more data received. Connection closed.")
                            break
                        msg = data.decode()
                        self.__handle_message(msg)
                        if msg.endswith("No audio device found\n"):
                            raise SystemError("Fatal: no bluetooth audio device found.")
                            
                        
        def heartbeat_thread():
            while self.androidConnected:
                self.__send_message("ping")
                Console(datetime.now(),"ping")
                time.sleep(3)
                
        thread = threading.Thread(target=server_thread)
        self.serverThread = thread
        thread.start()
        self.run_adb_cmd(adb_start_app(self.androidDeviceSn))
        while not self.androidConnected:
            if not thread.is_alive():
                Console("Server thread terminated.")
                raise SystemError("Fatal: Server thread terminated.")
                #return
            time.sleep(1)
        heartbeat_thread = threading.Thread(target=heartbeat_thread)
        self.heartBeatThread = heartbeat_thread
        heartbeat_thread.start()
    
    def __signal_client_stop(self):
        self.androidSocket.sendall(b"server_terminate\n")
        
    def stop_android(self):
        if self.androidConnected:
            self.__signal_client_stop()
            self.androidConnected = False
            if(self.heartBeatThread != None):
                self.heartBeatThread.join()
            if(self.serverThread != None):
                self.serverThread.join()
            self.run_adb_cmd(adb_stop_app(self.androidDeviceSn))
            self.androidSocket.close()

        for thread in threading.enumerate():
            if thread.name == "server_thread":
                thread.join()
                Console("Server thread terminated.")
                break
            
    def __send_message(self, msg: str):
        if self.androidConnected:
            msg = msg+"\n"
            self.androidSocket.sendall(msg.encode())
            Console(f"{datetime.now()} send android msg: {msg}")
        else:
            Console("Android device not connected.")

    def __handle_message(self,msg: str):
        Console(f"{datetime.now()} recv android msg:{msg}")
        msg = msg.replace("\n","")
        match(msg.split(" ")[0]):
            case "connected":
                connType = msg.split(" ")[1]
                addr = msg.split(" ")[2]
                match connType:
                    case "ble":
                        self.androidBleConnected = addr
                    case "bt":
                        self.androidBtConnected = addr
            case "disconnected":
                connType = msg.split(" ")[1]
                addr = msg.split(" ")[2]
                match connType:
                    case "ble":
                        self.androidBleConnected = None
                    case "bt":
                        self.androidBtConnected = None
            case _:
                pass
            
    def log_volt(self):
        """Let hearing aids Console a log that shows battery voltage 

        Examples:
        | Log Volt |
        """
        head = format(ROBOTE.LOG_VOLT.value,'04X')
        cmd = head + "00"
        self.android_send_cmd(cmd)

    def log_soc(self):
        """Let hearing aids Console a log that shows soc 

        Examples:
        | Log Soc |
        """
        head = format(ROBOTE.LOG_SOC.value,'04X')
        cmd = head + "00"
        self.android_send_cmd(cmd)

    def log_mcu_freq(self, core):
        """Let hearing aids Console a log that shows mcu frequency

        Examples:
        | Log Mcu Freq | M55 |
        | Log Mcu Freq | M33 |
        """
        head = format(ROBOTE.LOG_MCU_FREQ.value,'04X')
        content: list
        if core == "M55":
            content = CHIP.M55.value
        elif core == "M33":
            content = CHIP.M33.value
        else:
            raise Exception()
        contentStr = format(content,'02X')
        length = format(len(format(content,'01X')),'04X')
        cmd = head + length + contentStr
        self.android_send_cmd(cmd)
        
    def switch_mode(self, mode):
        """Let hearing aids switch to a given mode

        Examples:
        |  Switch Mode | Normal |
        |  Switch Mode | Innoise | 
        |  Switch Mode | Remote Fitting |
        |  Switch Mode | ANSI |
        |  Switch Mode | Hearing Test |
        """
        head = format(ROBOTE.SWITCH_DEVICE_MODE.value,'04X')
        content:list 
        match mode:
            case "Normal":
                content = MODE0.NORMAL.value
            case "Innoise":
                content = MODE0.INNOISE.value
            case "Remote Fitting":
                content = MODE0.REMOTE_FITTING.value
            case "ANSI":
                content = MODE0.ANSI.value
            case "Hearing Test":
                content = MODE0.HEARING_TEST.value
            case _:
                raise Exception() 
        contentStr = format(content,'02X')
        length = format(len(format(content,'01X')),'04X')
        cmd = head + length + contentStr
        print("switch mode"+cmd)
        self.android_send_cmd(cmd)
    
    def switch_beamforming(self, on):
        """Let hearing aids turn on/turn off beamforming

        Examples:
        |  Switch Beamforming | On |
        |  Switch Beamforming | Off | 
        """
        head = format(ROBOTE.SWITCH_BEAMFORMING.value,'04X')
        content:list 
        match on:
            case "On":
                content = "01"
            case "Off":
                content = "00"
            case _:
                raise Exception() 
        length = format(len(content),'04X')
        cmd = head + length + content
        self.android_send_cmd(cmd)
    
    def switch_afc(self, on):
        """Not Supported by Orka now, Don't Use It!
        Let hearing aids turn on/turn off AFC

        Examples:
        |  Switch Beamforming | On |
        |  Switch Beamforming | Off | 
        """
        head = hex(ROBOTE.SWITCH_BEAMFORMING.value)[2:]
        content:list 
        match on:
            case "On":
                content = [MODE0.NORMAL.value]
            case "Off":
                content = [MODE0.INNOISE.value]
            case _:
                raise Exception() 
        length = format(len(format(content,'01X')),'2X')
        cmd = head + length + content
        self.android_send_cmd(cmd)
            
# def test_android(sn:str,port:str,haAddr:str):
#     droidServer = AndroidTestLib()
#     droidServer.set_android_device(sn,port)
#     droidServer.start_server()
    # for i in range(3):
    #     time.sleep(3)
        # if (droidServer.ble_connect_ha(haAddr)):
        #     droidServer.android_send_cmd("01010000")
        #     droidServer.log_soc()
            # droidServer.log_volt()
            # droidServer.log_mcu_freq("M55")
            # droidServer.log_mcu_freq("M33")
            # droidServer.switch_mode("Normal")
    #         time.sleep(3)
    #         droidServer.bt_connect_ha(haAddr)
    #         droidServer.android_hfp_start()
    #         time.sleep(15)
    #         droidServer.android_hfp_stop()
    #         droidServer.ble_disconnect_ha(haAddr)
    #         break
    #     else: 
    #         Console("Connection failed.")
    # droidServer.stop_android()

# if __name__ == "__main__":
    # test_android("LMQ620VA18853978",65432,"12:12:12:12:12:11")
    # test_android("R38M20B9D2R",65433,"15:15:15:15:15:11")