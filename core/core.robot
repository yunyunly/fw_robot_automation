*** Setting ***
Documentation     Core Test Cases for testing both Charging Case and Hearing Aids' User Interface Functionality
...                Contains most items in checklist
...               
Suite Setup         Serial and bluetooth setup
Suite Teardown      Serial and bluetooth teardown
Test Setup
Test Teardown
Default Tags      Unit
Library            ../lib/SerialLib.py
Library            ../lib/BluetoothLib.py
Library            ../lib/ChargingCaseLib.py
Library            ../lib/AudioLib.py


*** Keywords *** 
Serial and bluetooth setup 
    Serial Open Port    Case     /dev/ttyACM0    115200
    Serial Open Port    Left     /dev/ttyUSB0    1152000 
    Serial Open Port    Right    /dev/ttyUSB1    1152000
    Connect Charging Case 

Serial and bluetooth teardown
    Serial Close Port    Case 
    Serial Close Port    Left 
    Serial Close Port    Right 
    Disconnect Charging Case 

*** Test Cases ***
Case binding hearing aids
    Case Close    
    Press Button    Reset    Long 
    ${ret}=     Serial Read Until    Case   Binding: binding success    20
    Should Contain    ${ret}    Binding: binding success


Case open three Leds on
    Case Open 
    Serial Parallel Read Until    Case     Led: turn on both led
    Serial Parallel Read Until    Case     Led: turn on front led case open
    ${map}=    Serial Parallel Wait    Case     
    Should Contain    ${map}[Case][0]     turn on both led 
    Should Contain    ${map}[Case][1]     turn on front led  

Case close front led off 
    Case Open 
    Sleep    1s   delay between case open and case close
    Case Close
    ${ret}=    Serial Read Until    Case     Led: turn off front led case close     timeout=3
    Should Contain    ${ret}    turn off front led

Case control pairing 
    Press Button    Fn    Long 
    Connect Hearing Aids   
    
Case control volume 
    Press Button    Left    
    ${res}=    Serial Read Until     Case     Btn: vol up    timeout=${3}
    Should Not Be True     ${res} is None
    Should Not Be Equal     ${res}    None
    ${res}=    Serial Read Until    Right     vol up     timeout=${3}
    Should Not Be Equal     ${res}    None
    ${res}=    Serial Read Until    Left     vol up     timeout=${3}
    Should Not Be Equal     ${res}    None

    Press Button    Right    
    ${res}=    Serial Read Until     Case     Btn: vol down    timeout=${3}
    Should Not Be Equal     ${res}    None
    ${res}=    Serial Read Until    Right     vol down 
    Should Not Be Equal     ${res}    None
    ${res}=    Serial Read Until    Left     vol down 
    Should Not Be Equal     ${res}    None
    

Case control mode switch 
    Press Button    Fn 
    ${res}=    Serial Read Until    Case     Btn: mode switch     timeout=${3}
    Should Not Be True    ${res} is None 
    ${res}=    Serial Read Until     Right     mode switch     timeout=${3}
    Should Not Be True    ${res} is None 
    ${res}=    Serial Read Until     Left     mode switch     timeout=${3}
    Should Not Be True    ${res} is None 

Case single dock
    Comment     dock left hearing aids and right hearing aids one by one
    Dock    Left 
    ${res}=    Serial Read Until    Case     Action: dock left    timeout=${3}
    Should Not Be True    ${res} is None 
    ${res}=    Serial Read Until    Case     Led: turn on left led    timeout=${3}
    Should Not Be True    ${res} is None 
    Dock    Right 
    ${res}=    Serial Read Until    Case     Action: dock right    timeout=${3}
    Should Not Be True    ${res} is None 
    ${res}=    Serial Read Until    Case     Led: turn on right led    timeout=${3}
    Should Not Be True    ${res} is None 

Case double dock 
    Dock     Both 
    ${res}=    Serial Read Until    Case     Action: dock both    timeout=${3}
    Should Not Be True    ${res} is None 
    ${res}=    Serial Read Until    Case     Led: turn on both led    timeout=${3}
    Should Not Be True    ${res} is None 

Auto reconnect
    Comment    hearing aids reconnect phone when it undock 

Play music 
    Comment     play music 
    ${id}=    Audio Get Dev Id
    Should Be True     ${id}>0
    Audio Use A2DP
    Audio Play Simple Audio    timeout=${10}
