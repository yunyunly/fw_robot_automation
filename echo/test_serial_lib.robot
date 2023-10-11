*** Setting ***
Documentation 	Test cases for testing serial library
...
...							All keywords constructed from ``SerialLib.py``.
Library 				SerialLib.py 
Test Setup 			Open Serial Port 	/dev/ttyACM0 		115200 
Test Teardown 	Stop Serial Port 

*** Test Cases *** 
Open and stop serial port
	[Setup]
	Open Serial Port		/dev/ttyACM0		115200
	Stop Serial Port
	[Teardown]


Read line
	${data}= 		Serial Read Line 	

Read lines 
	${logs}= 		Serial Read Lines	10

Read many line 
	FOR	${i}	IN RANGE	1	100 
		${data}= 	Serial Read Line 
		Log	${data}
	END 

Read many lines 
	FOR	${i}	IN RANGE 	1	10
		${date}= 	Serial Read Lines 	10 
	END 

Wait string 
	${data}=		Serial Listen For String 		case open 	timeout=${5}
	Should Be Equal		${data}		case open 

Wait string regex 
	${data}=		Serial Listen For String Regex 	send event (d+) 	timeout=${5}
	Should Be Equal 	${data}		2
Write string 
	Serial Write	abcedfg 

