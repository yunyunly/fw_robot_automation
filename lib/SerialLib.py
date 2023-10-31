import serial
import datetime 
import time 
import re 
import threading 
import asyncio
from uuid import uuid4 

class Logger(object):
    def __init__(self):
        self.io_opened = False
        self.opened = False 
        self.logs = []
        self.total_idx = 0
        self.clients = {}
        self.client_history = 0
        self.more = threading.Event()
        return 

    # def __new__(cls):
    #     if not hasattr(cls, 'instance'):
    #         cls.instance = super(Logger, cls).__new__(cls)
    #     return cls.instance

    def io_handler(self):
        self.io_opened = True 
        while (True) :
            # print("check break...")
            if self.opened == False:
                    break
            try:
                # print("reading...")
                newline = self._serial.readline().decode("utf-8").strip()
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

    def open(self, port, bard_rate):
        self._serial = serial.Serial(port, bard_rate)
        self.logs = []
        self.logs.clear()
        self.io = threading.Thread(target=self.io_handler)
        self.opened = True 
        self.more.clear()
        self.io.start()

    def close(self):
        self.opened = False
        self._serial.close()
        self.io.join()
    
    def wait_newline(self):
        self.more.clear()
        self.more.wait()
        return 
    
    def is_newline_waited(self):
        return not self.more.is_set() 

    def notify_newline(self):
        self.more.set()
        return 

    def read_latest(self, id)->str|None:
        if id not in self.clients.keys():
            self.clients[id] = self.client_history 
        if len(self.logs) == self.clients[id]:
            return None 
        newline = self.logs[self.clients[id]]
        self.clients[id] += 1
        if self.client_history < self.clients[id]:
            self.client_history = self.clients[id]
        return newline
    
    def read_latest_blocking(self, id)->str:
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
    
    def write_string(self, data):
            data_bytes = data.encode()
            self._serial.write(data_bytes)

    def write_hex(self, data):
        data_bytes = bytes.fromhex(data)
        self._serial.write(data_bytes)

    def save(self, filepath):
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
        return 

    # def __init__(self):
    #     self.case = Logger() 
    #     self.left = Logger() 
    #     self.right = Logger() 
    #
    #     self.logger = Logger()
    #     self.results = []
    #     self.threads = []
    #     self.threads_cnt = 0
    #     return 

    def open_serial_port(self, port, bard_rate):
        """Open serial port with specified bard rate.

        Examples:
        | Open Serial Port | "/dev/ttyUSB2" | 115200 |
        | Open Serial Port | "/dev/ttyUSB3" | 1152000 |
        """
        self.logger.open(port, bard_rate)
        return self.logger

    def close_serial_port(self):
        """Close current serial port.

        Examples:
        | Close Serial Port|
        """
        self.logger.close()

    def serial_save(self, filepath=None):
        """Save current log into files.
        The log file named log-{time}.txt and are stored in current working dir.
        """
        self.logger.save(filepath)
    
    def serial_read_latest(self):
        """Read the latest line of serial port 
        One line of serial data can be returned multi-times by this call
        
        Return:
        None if no serial data in cache 
        String otherwise 

        Examples:
        |${data}=|Serial Read Latest|
        """
        return self.logger.read_latest(uuid4())
    
    def serial_read_blocking(self)->str:
        return self.logger.read_latest_blocking(uuid4())
    
    def serial_write_string(self, data):
        """Write string to serial port.

        Examples:
        | Serial Write String | Hello, World! |
        """
        return self.logger.write_string(data)
    
    def serial_write_hex(self, data):
        """Write hex data to serial port. 

        Examples:
        |Serial Write Hex| abcdeef |
        """
        return self.logger.write_hex(data) 

    def serial_read_until(self, expected, timeout=None, parallel_idx = None):
        """Wait for a specific string from the serial port.

        This function will continuously listen for data until the expected string is received or the timeout is reached.

        Arguments:
        - expected: The exact string to wait for.
        - timeout: Maximum time (in seconds) to wait for the string.

        Examples:
        | Serial Read Until | hello, world | 
        | Serial Read Until | Hello, World! | timeout=10 |
        """
        start_time = time.time()
        ret = ""
        id =uuid4()
        while True:
            newline = self.logger.read_latest_blocking(id)
            print("until check", newline)
            match = re.search(expected, newline)

            if match:
                ret = match.string 
                break
            
            if timeout is not None and time.time() - start_time >= timeout:
                ret = None 
                break 
        if parallel_idx == None :
            return ret 
        else:
            self.results[parallel_idx] = ret
    
    def serial_read_until_regex(self, data_pattern, timeout=None, parallel_idx = None):
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
        start_time = time.time()
        ret = None
        id = uuid4()
        while True:
            newline = self.logger.read_latest_blocking(id)
            match = re.search(data_pattern, newline)

            if match:
                ret = match.groups()
                break
            
            if timeout is not None and time.time() - start_time >= timeout:
                ret = None 
                break
        if parallel_idx == None :
            return ret 
        else:
            self.results[parallel_idx] = ret
        
    def serial_parallel_read_until(self, expected, timeout=None):
        self.results.append(None)
        self.threads.append(threading.Thread(target = self.serial_read_until, args = (expected, timeout, self.threads_cnt)))
        self.threads_cnt += 1
    
    def serial_parallel_read_until_regex(self, data_pattern, timeout = None): 
        self.results.append(None)
        self.threads.append(threading.Thread(target = self.serial_read_until_regex, args = (data_pattern, timeout, self.threads_cnt)))
        self.threads_cnt += 1

    def serial_parallel_wait(self):
        for i in self.threads:
            i.start()
        for i in self.threads:
            i.join()
        ret = self.results.copy()
        self.threads_cnt = 0
        self.threads.clear()
        self.results.clear()
        return ret


if __name__ == "__main__":
    case = SerialLib() 
    ha = SerialLib() 
    case.open_serial_port("/dev/ttyACM0", 115200)
    ha.open_serial_port("/dev/ttyUSB0", 1152000)
    # for i in range(1, 40):
    #     print("newest",sl.serial_read_newest())
    #     time.sleep(0.1)
    # 
    # for i in range(1, 5):
    #     print("latest", sl.serial_read_latest())
    #
    # for i in range(1, 5):
    #     print("blocking", sl.serial_read_blocking())
    # for i in range(1, 5):
    #     print("string", sl.serial_read_until("heartbeat"))
    #
    # for i in range (1, 5):
    #     print("int", sl.serial_read_until_regex("shutdown count down ([0-9]+)"))
    # sl.save()
    # sl.serial_parallel_read_until_regex("Btn: ([a-zA-Z]+)")
    # # print(a)
    # sl.serial_parallel_read_until("Btn: wait")
    # # print(b)
    # results = sl.serial_parallel_wait()
    # print(results)
    # sl.serial_parallel_read_until("Btn: notified")
    # sl.serial_parallel_read_until("Btn: wait")
    # results = sl.serial_parallel_wait()
    # print(results)
    for i in range(100):
        #print(case.serial_read_blocking())
        print(ha.serial_read_blocking())
    # # results = await asyncio.gather(*tasks)
    case.close_serial_port()
    ha.close_serial_port()
