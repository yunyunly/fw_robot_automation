import serial
import datetime 
import time 
import re 

class SerialLib(object):
    """Test library for control serial port

    """
    _port = "/dev/ttyUSB0"
    _bard_rate = 115200
    
    _logs = []

    def __init__(self):
        self._port = "/dev/ttyUSB0"
        self._bard_rate = 115200
        return
    
    def _readline(self):
        if self._serial is not None:
            log = self._serial.readline().decode("utf-8").strip()
            timestamp = datetime.datetime.now().strftime('%m-%d %H:%M:%S.%f')
            log_entry = f"{timestamp} - {log}"
            self._logs.append(log_entry)
            return log
        else:
            raise Exception("Serial port not open")

    def open_serial_port(self, port, bard_rate):
        """Open serial port with specified bard rate.

        Examples:
        | Open Port | "/dev/ttyUSB2" | 115200 |
        | Open Port | "/dev/ttyUSB3" | 1152000 |
        """
        self._serial = serial.Serial(port, bard_rate)
        self._port = port 
        self._bard_rate = bard_rate
        self._logs.clear()

    def stop_serial_port(self):
        """Stop current serial port.

        Examples:
        | Stop Port|
        """
        self._serial.close()
        timestamp = datetime.datetime.now().strftime('%m-%d_%H:%M:%S.%f')
        filename = f"log_{timestamp}.txt"
        with open(filename, "w") as file:
            for log_entry in self._logs:
                file.write(log_entry+"\n")

    def serial_read_line(self):
        """Read 1 line from current port.

        Examples:
        | ${date} = | Read Line |
        """
        if self._serial is not None:
            data = self._serial.readline().decode("utf-8").strip()
        else:
            raise Exception("Serial port not open")

        return data 
    
    def serial_read_lines(self, num_lines):
        """Read many lines from current port.

        Examples:
        | ${data} = | Read Lines | 10 |
        """
        try:
            num_lines = int(num_lines)
        except ValueError:
            raise Exception("Number of lines should be integer")

        if num_lines < 0 or num_lines == 0:
            raise Exception("Number of lines should gearter then zero")

        if self._serial is not None:
            data_list = []
            for _ in range(0, num_lines):
                data = self._serial.readline().decode("utf-8").strip()
                data_list.append(data)
            return data_list
        else:
            raise Exception("Serial port not open")
    def serial_write(self, data, is_hex=False):
        """Write data to serial port.

        Examples:
        | Write | Hello, World! |
        | Write | 48656C6C6F2C20576F726C6421 | ${is_hex}=True |
        """
        if self._serial is not None:
            if is_hex:
                data_bytes = bytes.fromhex(data)
            else:
                data_bytes = data.encode()
            
            self._serial.write(data_bytes)
        else:
            raise Exception("Serial port is not open.")

    def serial_listen_for_string(self, expected, timeout=None):
        """Wait for a specific string from the serial port.

        This function will continuously listen for data until the expected string is received or the timeout is reached.

        Arguments:
        - expected: The exact string to wait for.
        - timeout: Maximum time (in seconds) to wait for the string.

        Examples:
        | Listen For String | Hello, World! | timeout=10 |
        """
        if self._serial is not None:
            start_time = time.time()
            while True:
                data = self._serial.readline().decode().strip()
                
                if expected in data:
                    return data
                
                if timeout is not None and time.time() - start_time >= timeout:
                    return None
        else:
            raise Exception("Serial port is not open.")
    
    def serial_listen_for_string_regex(self, data_pattern, timeout=None):
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
        if self._serial is not None:
            start_time = time.time()
            while True:
                data = self._serial.readline().decode().strip()
                match = re.match(data_pattern, data)
                
                if match:
                    return match.groups()
                
                if timeout is not None and time.time() - start_time >= timeout:
                    return None
        else:
            raise Exception("Serial port is not open.")

