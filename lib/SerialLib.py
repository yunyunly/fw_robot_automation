import multiprocessing
import os
from typing import SupportsInt
import serial
import datetime 
import time 
import re 
import threading 
import asyncio
from uuid import uuid4 
import robot.api.logger 
from multiprocessing import Process 

Console = robot.api.logger.console 

ENCODE = "ISO-8859-1"

class CondRead:
    def __init__(self):
        self.expected = None 
        self.timeout = None
        self.result = None
        self.is_matched = False
        self.is_timeouted = False 

class LogEntry(object):
    def __init__(self):
        self.ts = None 
        self.val = None
    def __init__(self, ts, val):
        self.ts = ts 
        self.val = val 

class SerialDevice(object):
    """each serial port created matches one SerialDevice

    Properties:
    - logger: IO thread used to read and write data to serial port
    - waiting_list: a list of CondRead, each CondRead is a read event
    - waiting_thread: a thread to execute all read event in waiting_list
        
    """
    def __init__(self, port, bard_rate):
        self.logger: SerialLogger = SerialLogger(port, bard_rate)
        self.waiting_list = []
        self.waiting_thread = None
    
    def __del__(self):
        del self.logger
        self.waiting_list.clear()
        self.waiting_thread = None


class SerialLib(object):
    """Test library for control serial port
    
    default:
    port: /dev/ttyACM0
    bard rate: 115200 
    """
    ROBOT_LIBRARY_SCOPE = 'SUITE'
    def __init__(self):
        self.serialDevices: dict[str, SerialDevice] = dict()
        return 
    def __new__(cls):
        if not hasattr(cls, 'instance'):
            cls.instance = super(SerialLib, cls).__new__(cls)
        return cls.instance

    def serial_open_port(self, tag, port, bard_rate):
        """Open a serial port.

        Args:
            tag (Str): The tag name of the serial port.
            port (Str): The port name of the serial port.
            bard_rate (Str): The bard rate of the serial port.
        
        Examples:
        | Serial Open Port | Case | /dev/ttyACM0 | 115200 |
        """
        print("open port", tag, port, bard_rate)
        if tag in self.serialDevices:
            self.serial_close_port(tag)
        self.serialDevices[tag] = SerialDevice(port=port, bard_rate=bard_rate)
        print("open port done", tag)
        return

    def serial_close_port(self, tag):
        """Close current serial port.
        Examples:
        | Close Serial Port | Case |
        | Close Serial Port | Left |
        | Close Serial Port | Right |
        """
        print("close port", tag)
        item = self.serialDevices.pop(tag)
        if item is None:
            raise Exception(f'Try to close a port with invalid tag {tag}, possible tags are {self.serialDevices.keys()}')
        del item 
        print("close port done", tag)
        return

    def serial_write_str(self, tag, data):
        """Write string to serial port.

        Examples:
        | Serial Write String | Case | Hello, World! |
        | Serial Write String | Left | Hello, World! |
        | Serial Write String | Right | Hello, World! |
        """
        ret = 0
        if tag in self.serialDevices:
            ret = self.serialDevices[tag].logger.write_str(data)
        else:
            raise Exception(f'Try to write data to a port with invalid tag {tag}, possible tags are {self.serialDevices.keys()}')
        return ret
    
    def serial_write_hex(self, tag, data):
        """Write hex data to serial port. 

        Examples:
        | Serial Write Hex | Case | abcdeef |
        | Serial Write Hex | Left | abcdeef |
        | Serial Write Hex | Right |abcdeef |
        """
        ret = 0
        if tag in self.serialDevices:
            ret = self.serialDevices[tag].logger.write_hex(data)
        else:
            raise Exception(f'Try to write data to a port with invalid tag {tag}, possible tags are {self.serialDevices.keys()}')
        return ret

    def serial_read_until(self, tag, exp=None, timeout=None):
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
        if tag in self.serialDevices:
            inst = self.serialDevices[tag].logger
        else:
            raise Exception(f'Try to read data to a port with invalid tag {tag}, possible tags are {self.serialDevices.keys()}')
        ret = None
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
        return ret 

    def serial_read_until_regex(self, tag, patt, timeout=None):
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
        if tag in self.serialDevices:
            inst = self.serialDevices[tag].logger
        else:
            raise Exception(f'Try to read data to a port with invalid tag {tag}, possible tags are {self.serialDevices.keys()}')
        ret = None
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
        return ret 

    def serial_parallel_read_until(self, tag, exp, timeout=None):
        """Register a read event, this event is pushed to a queue but not executed.

        Examples:
        | Serial Parallel Read Until | Case | say hello | timeout=${3} |
        | Serial Parallel Read Until | Left | say hello | timeout=${3} |
        | Serial Parallel Read Until | Right | say hello | timeout=${3} |
        """
        def parallel_read_until(serial_inst, waiting_list):
            ret = None
            time_cost = 0
            while True:
                pretime = time.time()
                line = serial_inst.readline()
                postime = time.time()
                time_cost = time_cost + (postime - pretime)
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
        if tag in self.serialDevices:
            serialDev = self.serialDevices[tag]
            if serialDev.waiting_thread is None:
                serialDev.waiting_thread = threading.Thread(target = parallel_read_until, args = (serialDev.logger, serialDev.waiting_list))
            one = CondRead()
            one.expected = exp
            one.timeout = timeout
            serialDev.waiting_list.append(one)
        else:
            raise Exception(f'Try to assign a parallel read task to a port with invalid tag {tag}, possible tags are {self.serialDevices.keys()}')
    
    def serial_parallel_read_until_regex(self, tag, patt, timeout=None):
        """Register a read event, this event is pushed to a queue but not executed.

        Examples:
        | Serial Parallel Read Until Regex | Case | say ([a-zA-Z]+) | timeout=${3} |
        | Serial Parallel Read Until Regex | Left | say ([a-zA-Z]+) | timeout=${3} |
        | Serial Parallel Read Until Regex | Right | say ([a-zA-Z]+) | timeout=${3} |
        """
        def parallel_read_until_regex(serial_inst, waiting_list):
            ret = None
            time_cost = 0
            while True:
                pretime = time.time()
                line = serial_inst.readline()
                postime = time.time()
                time_cost = time_cost + (postime - pretime)
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
        if tag in self.serialDevices:
            serialDev = self.serialDevices[tag]
            if serialDev.waiting_thread is None:
                serialDev.waiting_thread = threading.Thread(target = parallel_read_until_regex, args = (serialDev.logger, serialDev.waiting_list))
            one = CondRead()
            one.expected = patt
            one.timeout = timeout
            serialDev.waiting_list.append(one)
        else:
            raise Exception(f'Try to assign a parallel read task to a port with invalid tag {tag}, possible tags are {self.serialDevices.keys()}')
        
    def serial_parallel_wait(self, tag_list):
        """Execute all read event in parallel and wait complete 
        Input all the target tags in a string and seperated by a space.

        Examples:
        | ${ret}= | Serial Parallel Wait | Case |
        | ${ret}= | Serial Parallel Wait | Left |
        | ${ret}= | Serial Parallel Wait | Left Right |
        | ${ret}= | Serial Parallel Wait | Case Left Right |
        """
        if type(tag_list) is str:
            tag_list = tag_list.split()
        elif type(tag_list) is list:
            pass
        else:
            raise Exception(f'Invalid type of tags, should be str or list[str]')
        total = []
        if set(tag_list) - set(self.serialDevices.keys()):
            raise Exception(f'Try to parallelly read data to ports with invalid tag {tag_list}, possible tags are {self.serialDevices.keys()}')
        else:
            for i in tag_list:
                total += [self.serialDevices[i].waiting_thread] if self.serialDevices[i].waiting_thread else []
        
        results = {i:[] for i in tag_list}
        
        for i in total:
            i.start()
        for i in total:
            i.join()

        for i in tag_list:
            for j in self.serialDevices[i].waiting_list:
                results[i].append(j.result)
            self.serialDevices[i].waiting_thread = None
            self.serialDevices[i].waiting_list = []
        return results 
           
    def serial_parallel_read_start(self, tag_list):
        if set(tag_list) - set(self.serialDevices.keys()):
            raise Exception("Invalid tag")
        else:
            for i in tag_list:
                self.serialDevices[i].waiting_thread.start() if self.serialDevices[i].waiting_thread else None

    
    def serial_parallel_read_wait(self, tag_list):
        """Execute all read event in parallel and wait complete 

        Examples:
        | ${ret}= | Serial Parallel Wait | Case |
        | ${ret}= | Serial Parallel Wait | Left |
        | ${ret}= | Serial Parallel Wait | Left Right |
        | ${ret}= | Serial Parallel Wait | Case Left Right |
        """
        total = []
        if set(tag_list) - set(self.serialDevices.keys()):
            raise Exception("Invalid tag")
        else:
            for i in tag_list:
                total += [self.serialDevices[i].waiting_thread] if self.serialDevices[i].waiting_thread else []
        
        results = {i:[] for i in tag_list}
        
        for i in total:
            i.join()

        for i in tag_list:
            for j in self.serialDevices[i].waiting_list:
                results[i].append(j.result)
            self.serialDevices[i].waiting_thread = None
            self.serialDevices[i].waiting_list = [] 
        return results 


class SerialFetcher(threading.Thread):
    def __init__(self, port, rate, log_path, log_cache):
        print("    to construct", self.__class__.__name__)
        super(SerialFetcher, self).__init__()
        self._stop_event = threading.Event()
        self._stop_event.clear()
        self.port = port
        self.rate = rate
        self.path = log_path
        self.cache = log_cache
        self.serial: serial.Serial
        self._run_event = threading.Event()
        self._run_event.clear()
        print("    done construct", self.__class__.__name__)
    
    def get_serial(self):
        return self.serial

    def stop(self):
        print("    notify stop", self.__class__.__name__)
        self._stop_event.set()
    
    def stopped(self):
        return self._stop_event.is_set()
    
    def wait_until_running(self):
        self._run_event.wait()
        self._run_event.clear()

    def run(self):
        print("    to run", self.__class__.__name__)
        with (
            serial.Serial(self.port, self.rate) as self.serial, 
            open(self.path, 'a', buffering=1000) as log
        ):
            print(f'    to loop at time {datetime.datetime.now().strftime("%02H:%02M:%02S.%f")[:-3]}')
            self.serial.timeout = 0.5
            lines = []
            rest = ''
            self._run_event.set()
            while True:
                if self.stopped():
                    print("    stop notified")
                    self._stop_event.clear()
                    break
                if self.serial.readable():
                    print("in waiting", self.serial.in_waiting)
                    data = self.serial.read(self.serial.in_waiting or 1)
                    if data:
                        mess = data.decode(ENCODE)
                        mess = rest + mess 
                        if mess.find('\n') == -1:
                            rest = mess 
                            continue 
                        lines = mess.split('\n')
                        if mess.endswith('\n'):
                            rest = ''
                        else:
                            rest = lines.pop() if len(lines) > 0 else ''
                        if len(lines) > 0:
                            lines = [x.strip() for x in lines if x.strip()]
                            log_entries = [LogEntry(datetime.datetime.now().strftime('%02H:%02M:%02S.%f')[:-3], line) for line in lines]
                            self.cache.extend(log_entries)
                            for log_entry in log_entries:
                                log.write(f'[{log_entry.ts}] {log_entry.val}\n')
                        lines = list()
                else:
                    time.sleep(self.serial.timeout)
        if not self.serial is None:               
            if not self.serial.closed:
                self.serial.close()
        if not log is None:
            if not log.closed:
                log.close()
        print("    done run", self.__class__.__name__)

class SerialLogger(object):

    def __init__(self, port, bard_rate):
        print("  to construct", self.__class__.__name__)
        created_time = datetime.datetime.now().strftime('%02H-%02M-%02S')
        pwd = os.path.dirname(os.path.abspath(__file__))
        serial_log_dir = os.path.join(os.path.dirname(pwd), "serial_logs")
        if os.path.exists(serial_log_dir) == False:
            os.mkdir(serial_log_dir)
        
        log_file = os.path.join(serial_log_dir, f"{created_time}-{port}.txt".replace('/dev/', ''))
        
        self.cache = []
        self.fetcher = SerialFetcher(port, bard_rate, log_file, self.cache)
        self.next = 0
        self.fetcher.start()
        self.fetcher.wait_until_running()
        print("  done construct", self.__class__.__name__)
        return 
    
    def __del__(self):
        print("  to destory", self.__class__.__name__)
        self.fetcher.stop()
        self.fetcher.join()
        print("  done destory", self.__class__.__name__)
    
    def readline(self) -> str|None:
        ret = None
        if self.next < len(self.cache):
            ret = self.cache[self.next].val 
            self.next = self.next + 1 
        else:
            time.sleep(0.2)
        return ret 

    def write_str(self, data):
        print("  to write_str", data)
        data_bytes = data.encode()
        while not self.fetcher.get_serial().writable():
            time.sleep(0.2)
        self.fetcher.get_serial().write(data_bytes)
        print("  done write_str")

    def write_hex(self, data):
        print("  to write_hex", data)
        if not len(data) % 2 == 0 :
            raise Exception("Hex data should have even length")
        data_bytes = bytes.fromhex(data)
        while not self.fetcher.get_serial().writable():
            time.sleep(0.2)
        self.fetcher.get_serial().write(data_bytes)
        print("  done write_hex")

if __name__ == "__main__":
    sl = SerialLib()
    sl.serial_open_port("Case", "/dev/ttyACM0", 115200)
    sl.serial_open_port("Left", "/dev/ttyUSB2", 1152000)
    print(sl.serial_read_until("Case", "btn", 10))
    print(sl.serial_read_until("Case", "btn", 10))
    print(sl.serial_read_until("Case", "btn", 10))
    print(sl.serial_read_until("Left", "feed", 10))
    sl.serial_close_port("Case")
    sl.serial_close_port("Left")
    #print(sl.serial_parallel_wait("Case"))
