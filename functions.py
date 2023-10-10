import re
import signal

def timeout_handler(signum, frame):
    raise TimeoutError

def call(content):
    pass
    # print(call.__name__ + ' called with ' + str(content) + ' as argument')
    
def timeout(seconds):
    signal.signal(signal.SIGALRM, timeout_handler)
    signal.alarm(0)
    signal.alarm(seconds)
    
def capture(log_string, log_template):
    result = dict()
    log_string = log_string.replace("[", "##").replace("]", "##").replace("=", "##").replace(":", "##")
    log_template = log_template.replace("[", "##").replace("]", "##").replace("=", "##").replace(":", "##")
    # Extract the variable name from the template
    var_names = re.findall("{{(.*?)}}", log_template)
    for var_name in var_names:
        # Replace the log_template placeholder with a regex pattern
        pattern = log_template.replace("{{" + var_name + "}}", "(.*)")
        pattern = re.sub(r"{{.*}}", ".*", pattern)

        # Compile the pattern into a regular expression
        regex = re.compile(pattern)
        
        # Use the regex to search the log line
        match = regex.search(log_string)
        
        # If a match was found, return the first group (the variable)
        if match:
            result[var_name] = match.group(1)

    return result

def require(op, var_name, value, var_dict):
    if op == 'equal':
        if var_name in var_dict and var_dict[var_name] == value:
            return True
        else:
            return False
    
def ensure(op, var_name, value, var_dict):
    if op == 'equal':
        if var_name in var_dict and var_dict[var_name] == value:
            return True
        else:
            return False
