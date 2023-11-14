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

class SerialLogger(object):
    def __init__(self, port, bard_rate):
        self.io_opened = False
        self.opened = False 
        self.logs = []
        self.total_idx = 0
        self.clients = {}
        self.client_history = 0
        self.more = threading.Event()

        self.serial = serial.Serial(port, bard_rate)
        self.io = threading.Thread(target=self.io_handler)
        self.opened = True 
        self.more.clear()
        self.io.start()
        
        print("constructor")
        return 
    
    def release(self):
        self.opened = False
        self.io.join()
        self.serial.close()

    def io_handler(self):
        self.io_opened = True 
        while (True) :
            # print("check break...")
            if self.opened == False:
                print("io handler exit")
                break
            try:
                # print("reading...")
                newline = self.serial.readline().decode("utf-8").strip()
            except:
                newline = "serial closed"
            if newline == "":
                continue
            timestamp = datetime.datetime.now().strftime('%02H:%02M:%02S.%f')[:-3]
            log_entry = f"{self.total_idx}[{timestamp}] {newline}"
            self.total_idx +=1
            self.logs.append(log_entry)
            # print(f"readline {newline}")
            #print("check waiting...")
            if self.is_newline_waited():
                # print("notify wait flag...")
                self.notify_newline()
        self.io_opened = False 

    def wait_newline(self):
        self.more.clear()
        self.more.wait()
        return 
    
    def is_newline_waited(self):
        return not self.more.is_set() 

    def notify_newline(self):
        self.more.set()
        return 

    def read(self, id)->str|None:
        if id not in self.clients.keys():
            self.clients[id] = self.client_history 
        if len(self.logs) == self.clients[id]:
            return None 
        newline = self.logs[self.clients[id]]
        self.clients[id] += 1
        if self.client_history < self.clients[id]:
            self.client_history = self.clients[id]
        return newline
    
    def read_blocking(self, id)->str:
        if id not in self.clients.keys():
            self.clients[id] = self.client_history
        if len(self.logs) == self.clients[id]:
            self.wait_newline()
        newline = self.logs[self.clients[id]]
        self.clients[id] = self.clients[id] + 1
        print(id, "read", newline)
        if newline == None:
            raise TypeError("Should not be None type")
        if self.client_history < self.clients[id]:
            self.client_history = self.clients[id]
        return newline
    
    def write_str(self, data):
            data_bytes = data.encode()
            self.serial.write(data_bytes)

    def write_hex(self, data):
        data_bytes = bytes.fromhex(data)
        self.serial.write(data_bytes)

    def save(self, filepath=None):
        if filepath :
            print("filepath not implemented yet")
            pass
        else:
            timestamp = datetime.datetime.now().strftime('%d:%H:%M:%S')
            filename = f"log-{timestamp}.txt"
            with open(filename, "a") as file:
                for log_entry in self.logs:
                    file.write(log_entry+"\n")



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
        self.case_threads = []
        self.left_threads = []
        self.right_threads = []
        return 
    def __new__(cls):
        if not hasattr(cls, 'instance'):
            cls.instance = super(SerialLib, cls).__new__(cls)
        return cls.instance

    def release(self):
        for i in self.case_threads +self.left_threads+self.right_threads:
            i.start()
        for i in self.case_threads +self.left_threads+self.right_threads:
            i.join()
        if hasattr(self, "case"):
            self.case.release() 
        if hasattr(self, "left"):
            self.left.release()
        if hasattr(self, "right"):
            self.right.release()

    def serial_open_port(self, kind, port, bard_rate):
        """Open serial port with specified bard rate.

        Examples:
        | Open Serial Port | Case | "/dev/ttyUSB2" | 115200 |
        | Open Serial Port | Ha   | "/dev/ttyUSB3" | 1152000 |
        """
        match kind:
            case "Case":
                Console("open Case")
                self.case = SerialLogger(port, bard_rate)
                self.case_results = []
                self.case_threads = []
                self.case_thread_count = 0
            case "Left":
                Console("open Left")
                self.left = SerialLogger(port, bard_rate)
                self.left_results = []
                self.left_thread_count = 0
            case "Right":
                Console("open Right")
                self.right = SerialLogger(port, bard_rate)
                self.right_results = []
                self.right_thread_count = 0
            case _:
                raise Exception("Invalid kind")
        return 

    def serial_close_port(self, kind):
        """Close current serial port.

        Examples:
        | Close Serial Port|
        """
        match kind:
            case "Case":
                self.case.release() 
            case "Left":
                self.left.release()
            case "Right":
                self.right.release()
            case _:
                raise Exception("Invalid kind")
        return 

    def serial_save(self, kind):
        """Save current log into files.
        The log file named log-{time}.txt and are stored in current working dir.
        """
        match kind:
            case "Case":
                self.case.save()
            case "Left":
                self.left.save()
            case "Right":
                self.right.save()
            case _:
                raise Exception("Invalid kind")
        return 
    
    def serial_read(self, kind):
        """Read the latest line of serial port 
        One line of serial data can be returned multi-times by this call
        
        Return:
        None if no serial data in cache 
        String otherwise 

        Examples:
        |${data}=|Serial Read Latest|
        """
        ret = ""
        match kind:
            case "Case":
                ret = self.case.read(uuid4()) 
            case "Left":
                ret = self.left.read(uuid4())
            case "Right":
                ret = self.right.read(uuid4())
            case _:
                raise Exception("Invalid kind")
        return ret 
    
    def serial_read_blocking(self, kind):
        ret = ""
        match kind:
            case "Case":
                ret = self.case.read_blocking(uuid4()) 
            case "Left":
                ret = self.left.read_blocking(uuid4())
            case "Right":
                ret = self.right.read_blocking(uuid4())
            case _:
                raise Exception("Invalid kind")
        return ret 

    def serial_write_str(self, kind, data):
        """Write string to serial port.

        Examples:
        | Serial Write String | Hello, World! |
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
        |Serial Write Hex| abcdeef |
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

    def serial_read_until(self, kind, exp, timeout=None, parallel_idx = None):
        """Wait for a specific string from the serial port.

        This function will continuously listen for data until the expected string is received or the timeout is reached.

        Arguments:
        - expected: The exact string to wait for.
        - timeout: Maximum time (in seconds) to wait for the string.

        Examples:
        | Serial Read Until | hello, world | 
        | Serial Read Until | Hello, World! | timeout=10 |
        """
        inst = self.case 
        results = self.case_results 
        if timeout != None:
            timeout = float(timeout)
        match kind:
            case "Case":
                inst = self.case
                results = self.case_results
            case "Left":
                inst = self.left
                results = self.left_results
            case "Right":
                inst = self.right
                results = self.right_results
            case _:
                raise Exception("Invalid kind")
        start_time = time.time()
        ret = None
        id =uuid4()
        while True:
            newline = inst.read_blocking(id)
            print("until check", newline)
            match = re.search(exp, newline)

            if match:
                ret = match.string 
                break
            
            if timeout is not None and time.time() - start_time >= timeout:
                ret = None 
                break 
        if parallel_idx == None :
            return ret 
        else:
            results[parallel_idx] = ret
    
    def serial_read_until_regex(self, kind, patt, timeout=None, parallel_idx=None):
        """Wait for string matching a given regular expression pattern.

        This function will continuously listen for data until data matching the specified pattern is received or the timeout is reached.

        Arguments:
        - data_pattern: The regular expression pattern to match against received data.
        - timeout: Maximum time (in seconds) to wait for data matching the pattern.

        Returns:
        - If a match is found, a tuple is returned with the first element being the matched string and subsequent elements being the regex capture groups.
        - If no match is found within the timeout, None is returned.

        Examples:
        | ${datas} = | Serial Read Until Regex | Received: (\d+) | 
        | ${datas} = | Serial Read Until Regex | Data: (\w+) (\d+) | timeout=10 |
        """
        inst = self.case 
        results = self.case_results
        match kind:
            case "Case":
                inst = self.case
                results = self.case_results
            case "Left":
                inst = self.left
                results = self.left_results
            case "Right":
                inst = self.right
                results = self.right_results
            case _:
                raise Exception("Invalid kind")
        start_time = time.time()
        ret = None
        id = uuid4()
        while True:
            newline = inst.read_blocking(id)
            match = re.search(patt, newline)

            if match:
                ret = list(match.groups())
                break
            
            if timeout is not None and time.time() - start_time >= timeout:
                ret = None 
                break
        if parallel_idx == None :
            return ret 
        else:
            results[parallel_idx] = ret

    def serial_parallel_read_until(self, kind, exp, timeout=None):
        """Register a read event 

        Examples:
        |Serial Parallel Read Until| Case | say hello | timeout=${3}|
        """
        match kind:
            case "Case":
                new_thread = threading.Thread(target = self.serial_read_until, args = (kind, exp, timeout, self.case_thread_count))
                self.case_results.append(None)
                self.case_threads.append(new_thread)
                self.case_thread_count += 1 
            case "Left":
                new_thread = threading.Thread(target = self.serial_read_until, args = (kind, exp, timeout, self.left_thread_count))
                self.left_results.append(None)
                self.left_threads.append(new_thread)
                self.left_thread_count += 1 
            case "Right":
                new_thread = threading.Thread(target = self.serial_read_until, args = (kind, exp, timeout, self.right_thread_count))
                self.right_results.append(None)
                self.right_threads.append(new_thread)
                self.right_thread_count += 1 
            case _:
                raise Exception("Invalid kind")
    
    def serial_parallel_read_until_regex(self, kind, patt, timeout=None):
        """Register a read event 

        Examples:
        |Serial Parallel Read Until Regex| Case | say ([a-zA-Z]+) | timeout=${3}|
        """
        match kind:
            case "Case":
                new_thread = threading.Thread(target = self.serial_read_until_regex, args = (kind, patt, timeout, self.case_thread_count))
                self.case_results.append(None)
                self.case_threads.append(new_thread)
                self.case_thread_count += 1 
            case "Left":
                new_thread = threading.Thread(target = self.serial_read_until_regex, args = (kind, patt, timeout, self.left_thread_count))
                self.left_results.append(None)
                self.left_threads.append(new_thread)
                self.left_thread_count += 1 
            case "Right":
                new_thread = threading.Thread(target = self.serial_read_until_regex, args = (kind, patt, timeout, self.right_thread_count))
                self.right_results.append(None)
                self.right_threads.append(new_thread)
                self.right_thread_count += 1 
            case _:
                raise Exception("Invalid kind")

    def serial_parallel_wait(self, kind_list):
        """Execute all read event in parallel and wait complete 

        Examples:
        |${ret}=|Serial Parallel Wait| Case Left Right|
        """
        total = []
        if "Case" in kind_list:
            total += self.case_threads
        if "Left" in kind_list:
            total += self.left_threads 
        if "Right" in kind_list:
            total += self.right_threads 

        for i in total:
            i.start()
        for i in total:
            i.join()
        results = {}
        if "Case" in kind_list:
            results["Case"] = self.case_results.copy()
            self.case_results.clear()
            self.case_threads.clear()
            self.case_thread_count = 0
        if "Left" in kind_list:
            results["Left"] = self.left_results.copy()
            self.left_results.clear()
            self.left_threads.clear()
            self.left_thread_count = 0
        if "Right" in kind_list:
            results["Right"] = self.right_results.copy()
            self.right_results.clear()
            self.right_threads.clear()
            self.right_thread_count = 0
        return results 



# if __name__ == "__main__":
#     sl = SerialLib()
#     sl.serial_open_port("Case", "/dev/ttyACM0", 115200)
#     sl.serial_open_port("Left", "/dev/ttyUSB0", 1152000)
#     for i in range(100):
#         print(sl.serial_read_blocking("Case"))
#         print(sl.serial_read_blocking("Left"))
#
#     sl.release()
