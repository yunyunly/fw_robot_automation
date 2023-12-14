from typing import SupportsInt
import serial
import datetime 
import time 
import re 
import threading 
import asyncio
from uuid import uuid4 
import robot.api.logger 
 

Console = robot.api.logger.console 

ENCODE = "ISO-8859-1"

class CondRead:
    def __init__(self):
        self.expected = None 
        self.timeout = None
        self.result = None
        self.is_matched = False
        self.is_timeouted = False 

class SerialLib(object):
    """Test library for control serial port
    
    default:
    port: /dev/ttyACM0
    bard rate: 115200 
    """
    def __init__(self):
        self.case :SerialLogger
        self.left :SerialLogger
        self.right :SerialLogger
        self.case_waiting_list = []
        self.left_waiting_list = []
        self.right_waiting_list = []
        self.case_waiting_thread = None 
        self.left_waiting_thread = None 
        self.right_waiting_thread = None
        return 
    def __new__(cls):
        if not hasattr(cls, 'instance'):
            cls.instance = super(SerialLib, cls).__new__(cls)
        return cls.instance

    def serial_open_port(self, kind, port, bard_rate):
        """Open serial port with specified bard rate.

        Examples:
        | Open Serial Port | Case | "/dev/ttyUSB2" | 115200 |
        | Open Serial Port | Left  | "/dev/ttyUSB3" | 1152000 |
        | Open Serial Port | Right  | "/dev/ttyUSB3" | 1152000 |
        """
        match kind:
            case "Case":
                Console("open Case")
                self.case = SerialLogger(port, bard_rate)
            case "Left":
                Console("open Left")
                self.left = SerialLogger(port, bard_rate)
            case "Right":
                Console("open Right")
                self.right = SerialLogger(port, bard_rate)
            case _:
                raise Exception("Invalid kind")
        return 

    def serial_close_port(self, kind):
        """Close current serial port.

        Examples:
        | Close Serial Port | Case |
        | Close Serial Port | Left |
        | Close Serial Port | Right |
        """
        match kind:
            case "Case":
                del self.case
            case "Left":
                del self.left
            case "Right":
                del self.right
            case _:
                raise Exception("Invalid kind")
        return 

    def serial_write_str(self, kind, data):
        """Write string to serial port.

        Examples:
        | Serial Write String | Case | Hello, World! |
        | Serial Write String | Left | Hello, World! |
        | Serial Write String | Right | Hello, World! |
        """
        ret = 0
        match kind:
            case "Case":
                ret = self.case.write_str(data) 
            case "Left":
                ret = self.left.write_str(data)
            case "Right":
                ret = self.right.write_str(data)
            case _:
                raise Exception("Invalid kind")
        return ret 
    
    def serial_write_hex(self, kind, data):
        """Write hex data to serial port. 

        Examples:
        | Serial Write Hex | Case | abcdeef |
        | Serial Write Hex | Left | abcdeef |
        | Serial Write Hex | Right |abcdeef |
        """
        ret = 0
        match kind:
            case "Case":
                ret = self.case.write_hex(data) 
            case "Left":
                ret = self.left.write_hex(data)
            case "Right":
                ret = self.right.write_hex(data)
            case _:
                raise Exception("Invalid kind")
        return ret 

    def serial_read_until(self, kind, exp=None, timeout=None):
        """Wait for a specific string from the serial port.

        This function will continuously listen for data until the expected string is received or the timeout is reached.

        Arguments:
        - expected: The exact string to wait for.
        - timeout: Maximum time (in seconds) to wait for the string.
        
        I sugguest you always set a timeout value to avoid infinite blocking while test case failed.

        Examples:
        | ${ret}=    | Serial Read Until | Case | hello, world | 
        | ${ret}=    | Serial Read Until | Left | Hello, World! | timeout=10 |
        | ${ret}=    | Serial Read Until | Right | Hello, World! | timeout=10 |

        Special case to read a new line:
        | ${ret}=    | Serial Read Until | Case |
        """
        if timeout != None:
            timeout = float(timeout)
        match kind:
            case "Case":
                inst = self.case
            case "Left":
                inst = self.left
            case "Right":
                inst = self.right
            case _:
                raise Exception("Invalid kind")
        ret = None
        inst.set_read_timeout(1)
        time_cost = 0
        while True:
            pretime = time.time()
            line = inst.readline()
            postime = time.time()
            time_cost = time_cost + (postime - pretime)
            #print("time cost", time_cost)
            if line is None and timeout is None:
                continue
            elif line is None and time_cost >= timeout:
                break 
            elif line is None:
                continue
            else:
                pass
            if exp is None:
                ret = line 
                break
            else:
                match = re.search(exp, line)
                if match:
                    ret = match.string 
                    break
            if timeout is None:
                continue
            if time_cost >= timeout:
                break
        inst.clear_read_timeout()
        return ret 

    def serial_read_until_regex(self, kind, patt, timeout=None):
        """Wait for string matching a given regular expression pattern.

        This function will continuously listen for data until data matching the specified pattern is received or the timeout is reached.

        Arguments:
        - data_pattern: The regular expression pattern to match against received data.
        - timeout: Maximum time (in seconds) to wait for data matching the pattern.

        Returns:
        - If a match is found, a list is returned with elements be the regex capture groups.
        - If no match is found within the timeout, None is returned.

        Examples:
        | ${datas} = | Serial Read Until Regex | Case | Received: (\d+) | 
        | ${datas} = | Serial Read Until Regex | Left | Data: (\w+) (\d+) | timeout=10 |
        | ${datas} = | Serial Read Until Regex | Right | Data: (\w+) (\d+) | timeout=10 |
        """
        if timeout != None:
            timeout = float(timeout)
        match kind:
            case "Case":
                inst = self.case
            case "Left":
                inst = self.left
            case "Right":
                inst = self.right
            case _:
                raise Exception("Invalid kind")
        ret = None
        inst.set_read_timeout(1)
        time_cost = 0
        while True:
            pretime = time.time()
            line = inst.readline()
            postime = time.time()
            time_cost = time_cost + (postime - pretime)
            #print("time cost", time_cost)
            if line is None and timeout is None:
                continue
            elif line is None and time_cost >= timeout:
                break 
            elif line is None:
                continue
            else:
                pass
            match = re.search(patt, line)
            if match:
                ret = list(match.groups()) 
                break
            if timeout is None:
                continue
            if time_cost >= timeout:
                break
        inst.clear_read_timeout()
        return ret 

    def serial_parallel_read_until(self, kind, exp, timeout=None):
        """Register a read event, this event is pushed to a queue but not executed.

        Examples:
        | Serial Parallel Read Until | Case | say hello | timeout=${3} |
        | Serial Parallel Read Until | Left | say hello | timeout=${3} |
        | Serial Parallel Read Until | Right | say hello | timeout=${3} |
        """
        def parallel_read_until(serial_inst, waiting_list):
            ret = None
            serial_inst.set_read_timeout(1)
            time_cost = 0
            while True:
                pretime = time.time()
                line = serial_inst.readline()
                postime = time.time()
                time_cost = time_cost + (postime - pretime)
                #print("time cost", time_cost)
                for i in waiting_list:
                    if i.is_matched or i.is_timeouted:
                        continue 
                    if line is None:
                        match = None 
                    else: 
                        match = re.search(i.expected, line)
                    if match:
                        i.result = match.string
                        i.is_matched = True 
                        continue 
                    if i.timeout is None:
                        continue 
                    elif time_cost >= i.timeout:
                        i.is_timeouted = True 
                        continue
                if all( i.is_timeouted or i.is_matched for i in waiting_list):
                    break
            serial_inst.clear_read_timeout()
        match kind:
            case "Case":
                if self.case_waiting_thread is None:
                    self.case_waiting_thread = threading.Thread(target = parallel_read_until, args = (self.case, self.case_waiting_list))      
                one = CondRead()
                one.expected = exp 
                one.timeout = timeout 
                self.case_waiting_list.append(one)
            case "Left":
                if self.left_waiting_thread is None:
                    self.left_waiting_thread = threading.Thread(target = parallel_read_until, args = (self.left, self.left_waiting_list))      
                one = CondRead()
                one.expected = exp 
                one.timeout = timeout 
                self.left_waiting_list.append(one)
            case "Right":
                if self.right_waiting_thread is None:
                    self.right_waiting_thread = threading.Thread(target = parallel_read_until, args = (self.right, self.right_waiting_list))      
                one = CondRead()
                one.expected = exp 
                one.timeout = timeout 
                self.right_waiting_list.append(one)
            case _:
                raise Exception("Invalid kind")
    
    def serial_parallel_read_until_regex(self, kind, patt, timeout=None):
        """Register a read event, this event is pushed to a queue but not executed.

        Examples:
        | Serial Parallel Read Until Regex | Case | say ([a-zA-Z]+) | timeout=${3} |
        | Serial Parallel Read Until Regex | Left | say ([a-zA-Z]+) | timeout=${3} |
        | Serial Parallel Read Until Regex | Right | say ([a-zA-Z]+) | timeout=${3} |
        """
        def parallel_read_until_regex(serial_inst, waiting_list):
            ret = None
            serial_inst.set_read_timeout(1)
            time_cost = 0
            while True:
                pretime = time.time()
                line = serial_inst.readline()
                postime = time.time()
                time_cost = time_cost + (postime - pretime)
                #print("time cost", time_cost)
                for i in waiting_list:
                    if i.is_matched or i.is_timeouted:
                        continue 
                    if line is None:
                        match = None 
                    else: 
                        match = re.search(i.expected, line)
                    if match:
                        i.result = list(match.groups())
                        i.is_matched = True 
                        continue 
                    if i.timeout is None:
                        continue 
                    elif time_cost >= i.timeout:
                        i.is_timeouted = True 
                        continue
                if all( i.is_timeouted or i.is_matched for i in waiting_list):
                    break
            serial_inst.clear_read_timeout()
        match kind:
            case "Case":
                if self.case_waiting_thread is None:
                    self.case_waiting_thread = threading.Thread(target = parallel_read_until_regex, args = (self.case, self.case_waiting_list))      
                one = CondRead()
                one.expected = patt 
                one.timeout = timeout 
                self.case_waiting_list.append(one)
            case "Left":
                if self.left_waiting_thread is None:
                    self.left_waiting_thread = threading.Thread(target = parallel_read_until_regex, args = (self.left, self.left_waiting_list))      
                one = CondRead()
                one.expected = patt
                one.timeout = timeout 
                self.left_waiting_list.append(one)
            case "Right":
                if self.right_waiting_thread is None:
                    self.right_waiting_thread = threading.Thread(target = parallel_read_until_regex, args = (self.right, self.right_waiting_list))      
                one = CondRead()
                one.expected = patt
                one.timeout = timeout 
                self.right_waiting_list.append(one)
            case _:
                raise Exception("Invalid kind")
        
    def serial_parallel_wait(self, kind_list):
        """Execute all read event in parallel and wait complete 

        Examples:
        | ${ret}= | Serial Parallel Wait | Case |
        | ${ret}= | Serial Parallel Wait | Left |
        | ${ret}= | Serial Parallel Wait | Left Right |
        | ${ret}= | Serial Parallel Wait | Case Left Right |
        """
        total = []
        total += [self.case_waiting_thread] if self.case_waiting_thread else [] 
        total += [self.left_waiting_thread] if self.left_waiting_thread else [] 
        total += [self.right_waiting_thread] if self.right_waiting_thread else [] 
        
        results = {"Case": list(), "Left": list(), "Right": list()}
        
        for i in total:
            i.start()
        for i in total:
            i.join()
        
        if "Case" in kind_list:
            for i in self.case_waiting_list:
                results["Case"].append(i.result)
        if "Left" in kind_list:
            for i in self.left_waiting_list:
                results["Left"].append(i.result)
        if "Right" in kind_list:
            for i in self.right_waiting_list:
                results["Right"].append(i.result)
        return results 

class SerialLogger(object):
    def __init__(self, port, bard_rate):
        self.logs = []
        self.serial = serial.Serial(port, bard_rate)
        self.cnt = 0
        return 
    
    def __del__(self):
        self.serial.cancel_read()
        if self.serial.is_open:
            self.serial.close()
        print("Serial Exit")

    def readline(self) -> str|None:
        line = ""
        if self.serial.timeout is None:
            while line == "":
                line = self.serial.readline().decode(ENCODE).strip()
        else:
            while True:
                line_without_strip = self.serial.readline().decode(ENCODE) 
                if line_without_strip != "":
                    line = line_without_strip.strip()
                    if line == "":
                        continue
                    else:
                        break 
                else:
                    line = None 
                    break
        print("Rd",self.cnt, line)
        if not line is None:
            self.cnt = self.cnt + 1
        return line 

    def write_str(self, data):
            data_bytes = data.encode()
            self.serial.write(data_bytes)

    def write_hex(self, data):
        data_bytes = bytes.fromhex(data)
        self.serial.write(data_bytes)

    def set_read_timeout(self, timeout: float):
        self.serial.timeout = timeout 

    def clear_read_timeout(self):
        self.serial.timeout = None

# if __name__ == "__main__":
#     sl = SerialLib()
#     sl.serial_open_port("Case", "/dev/ttyACM0", 115200)
#     print(sl.serial_read_until("Case", "charge", timeout=8))
#     sl.serial_parallel_read_until("Case", "charge", timeout=8)
#     sl.serial_parallel_read_until("Case", "charge", timeout=3)
#     print(sl.serial_parallel_wait("Case"))
