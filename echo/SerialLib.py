import serial
import datetime 
import time 
import re 
import threading 

class Logger(object):
    def __init__(self):
        self._io_opened = False
        self._opened = False 
        self._wait_new_line = False
        self._has_new_line = threading.Semaphore(0)
        self._readed = None 
        self._logs = []
        return 
    
    @staticmethod
    def pr(msg):
        print("[Logger]", msg)

    def _io_handler(self):
        self._io_opened = True 
        while (True) :
            self.pr("check break...")
            if self._opened == False:
                    break
            try:
                Logger.pr("reading...")
                newline = self._serial.readline().decode("utf-8").strip()
                newline = newline.strip()
                if newline == "":
                    continue
                self.pr("check waiting...")
                if self._wait_new_line == True:
                    self.pr("notify wait flag...")
                    self._wait_new_line = False
                    self._has_new_line.release()

            except:
                newline = "serial closed"
            timestamp = datetime.datetime.now().strftime('%02H:%02M:%02S.%f')
            log_entry = f"[{timestamp}] {newline}"
            self._logs.append(log_entry)
        self._io_opened = False 

    def open(self, port, bard_rate):
        self._serial = serial.Serial(port, bard_rate)
        self._logs = []
        self._logs.clear()
        self._io = threading.Thread(target=self._io_handler)
        self._opened = True 
        self._io.start()
        self._readed = -1

    def close(self):
        self._opened = False
        self._serial.close()
        self._io.join()

    def read_latest(self):
        if len(self._logs) == 0:
            return None 
        idx = len(self._logs)-1
        self._readed = idx 
        return self._logs[idx]
    
    def read_latest_blocking(self):
        self._wait_new_line = True 
        self._has_new_line.acquire()
        return self.read_latest()

    def read_newest(self):
        if (self._readed + 1) == len(self._logs):
            return None 
        return self.read_latest()
    
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
            timestamp = datetime.datetime.now().strftime('%d_%H:%M:%S.%f')
            filename = f"log_{timestamp}.txt"
            with open(filename, "a") as file:
                for log_entry in self._logs:
                    file.write(log_entry+"\n")
        



class SerialLib(object):
    """Test library for control serial port

    """
    """
    _port = "/dev/ttyUSB0"
    _bard_rate = 115200
    _lock 
    _opened = False
    _logs = []
    """

    def __init__(self):
        self._logger = Logger()
        return 

    def open_serial_port(self, port, bard_rate):
        """Open serial port with specified bard rate.

        Examples:
        | Open Serial Port | "/dev/ttyUSB2" | 115200 |
        | Open Serial Port | "/dev/ttyUSB3" | 1152000 |
        """
        self._logger.open(port, bard_rate)

    def close_serial_port(self):
        """Close current serial port.

        Examples:
        | Stop Serial Port|
        """
        self._logger.close()
    
    def serial_read_latest(self):
        """Read the latest line of serial port 
        One line of serial data can be returned multi-times by this call
        
        Return:
        None if no serial data in cache 
        String otherwise 

        Examples:
        |${data}=|Serial Read Latest|
        """
        return self._logger.read_latest()
    
    def serial_read_newest(self):
        """Read the newest line of serial port 
        One line of serial data can be returned only once by this call 

        Return:
        None if no new serial data since last read 
        String otherwise 

        Examples:
        |${data}=|Serial Read Newest|
        """
        return self._logger.read_newest()
    
    def serial_read_blocking(self):
        return self._logger.read_latest_blocking()

    def serial_write_string(self, data):
        """Write string to serial port.

        Examples:
        | Serial Write String | Hello, World! |
        """
        return self._logger.write_string(data)
    
    def serial_write_hex(self, data):
        """Write hex data to serial port. 

        Examples:
        |Serial Write Hex| abcdeef |
        """
        return self._logger.write_hex(data) 

    def serial_read_until(self, expected, timeout=None):
        """Wait for a specific string from the serial port.

        This function will continuously listen for data until the expected string is received or the timeout is reached.

        Arguments:
        - expected: The exact string to wait for.
        - timeout: Maximum time (in seconds) to wait for the string.

        Examples:
        | Listen For String | Hello, World! | timeout=10 |
        """
        start_time = time.time()
        while True:
            newline = self.serial_read_blocking()
            if newline == None:
                continue
            match = re.search(expected, newline)

            if match:
                return match.string
            
            if timeout is not None and time.time() - start_time >= timeout:
                return None 
    
    def serial_read_until_regex(self, data_pattern, timeout=None):
        """Wait for string matching a given regular expression pattern.

        This function will continuously listen for data until data matching the specified pattern is received or the timeout is reached.

        Arguments:
        - data_pattern: The regular expression pattern to match against received data.
        - timeout: Maximum time (in seconds) to wait for data matching the pattern.

        Returns:
        - If a match is found, a tuple is returned with the first element being the matched string and subsequent elements being the regex capture groups.
        - If no match is found within the timeout, None is returned.

        Examples:
        | ${datas} = | Listen For String Regex | Received: (\d+) | timeout=5 |
        | ${datas} = | Listen For String Regex | Data: (\w+) (\d+) | timeout=10 |
        """
        start_time = time.time()
        while True:
            newline = self.serial_read_blocking()
            if newline == None:
                continue
            print("regex get nl", newline)
            match = re.search(data_pattern, newline)

            if match:
                print(match.groups)
                return match.groups()
            
            if timeout is not None and time.time() - start_time >= timeout:
                return None 

if __name__ == "__main__":
    sl = SerialLib()
    sl.open_serial_port("/dev/ttyACM0", 115200)
    for i in range(1, 40):
        print("newest",sl.serial_read_newest())
        time.sleep(0.1)
    
    for i in range(1, 5):
        print("latest", sl.serial_read_latest())

    for i in range(1, 5):
        print("blocking", sl.serial_read_blocking())
    for i in range(1, 5):
        print("string", sl.serial_read_until("heartbeat"))
    sl.close_serial_port()
