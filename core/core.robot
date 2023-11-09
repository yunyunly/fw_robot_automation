*** Setting ***
Documentation     Core Test Cases for testing both Charging Case and Hearing Aids' User Interface Functionality
...                Contains most items in checklist
...               
Suite Setup         Setup
Suite Teardown      Teardown
Test Setup
Test Teardown
Default Tags      Unit
Library            ../lib/SerialLib.py
Library            ../lib/BluetoothLib.py
Library            ../lib/ChargingCaseLib.py
Library            ../lib/HearingAidsLib.py
Library            ../lib/AudioLib.py


*** Keywords *** 
Setup 
    Serial Open Port    Case     /dev/ttyACM0    115200
    Serial Open Port    Left     /dev/ttyUSB0    1152000 
    Serial Open Port    Right    /dev/ttyUSB1    1152000
    Connect Charging Case 

Teardown
    Serial Close Port    Case 
    Serial Close Port    Left 
    Serial Close Port    Right 
    #Disconnect Charging Case 

Read Case 
    [Arguments]    ${str} 
    ${res}=    Serial Read Until    Case    ${str}    timeout=${3}
    ${ret}=    Set Variable If    "${res}"=="None"    ${False}    ${True}
    RETURN    ${ret}

*** Test Cases ***
Case information
    Print Info
    ${matched}=    Serial Read Until Regex    Case    SOC ([0-9]+) Volt ([0-9]+) Curr ([\\+\\-]?[0-9]+\\.[0-9]+) Temp ([\\+\\-]?[0-9]+) Charge ([0-9]+)    timeout=${3}
    ${soc}=    Set Variable    ${matched}[0]
    ${volt}=    Set Variable    ${matched}[1]
    ${curr}=    Set Variable    ${matched}[2]
    ${temp}=    Set Variable    ${matched}[3]
    ${charge}=    Set Variable    ${matched}[4]
    IF    ${charge} == 1
        Should Be True    ${curr} >= 0
    ELSE
        Should Be True    ${curr} < 0
    END
    Should Be True    ${soc} >= 0 and ${soc} <= 100
Case binding hearing aids
    Case Close    
    Press Button    Reset    Long 
    ${ret}=     Serial Read Until    Case   Binding: binding success    20
    Should Contain    ${ret}    Binding: binding success

Case open turn on Leds
    Case Open 
    Serial Parallel Read Until    Case     Led: turn on both led    timeout=${3}
    Serial Parallel Read Until    Case     Led: turn on front led case open    timeout=${3}
    ${map}=    Serial Parallel Wait    Case     
    Should Not Be Equal    "${map}[Case][0]"     "None" 
    Should Not Be Equal    "${map}[Case][1]"         "None"  

Case close turn off front led 
    Case Open 
    Sleep    1s   delay between case open and case close
    Case Close
    ${ret}=    Serial Read Until    Case     Led: turn off front led case close     timeout=3
    Should Contain    ${ret}    turn off front led

Case single dock and undock 
    Comment     dock and undock left hearing aids and right hearing aids one by one
    Case Open
    sleep    0.5s
    Undock    Left 
    ${res}=    Serial Read Until    Case     Action: undock left    timeout=${5}
    Should Not Be Equal    "${res}"    "None" 
    Dock    Left 
    ${res}=    Serial Read Until    Case     Action: dock left    timeout=${3}
    Should Not Be Equal    "${res}"    "None" 
    ${res}=    Serial Read Until    Case     Led: turn on left led    timeout=${3}
    Should Not Be Equal    "${res}"    "None" 
    
    Undock    Right 
    ${res}=    Serial Read Until    Case     Action: undock right    timeout=${3}
    Should Not Be Equal    "${res}"    "None" 
    Dock    Right 
    ${res}=    Serial Read Until    Case     Action: dock right    timeout=${3}
    Should Not Be Equal    "${res}"     "None" 
    ${res}=    Serial Read Until    Case     Led: turn on right led    timeout=${3}
    Should Not Be Equal    "${res}"     "None" 

Case double dock and undock
    Comment     dock and undock both left and right right hearing aids
    Case Open
    sleep    0.5s
    Undock    Both 
    ${res}=    Serial Read Until    Case     Action: undock both    timeout=${5}
    Should Not Be Equal    "${res}"    "None" 
    Dock    Both
    ${res}=    Serial Read Until    Case     Action: dock both    timeout=${3}
    Should Not Be Equal    "${res}"    "None" 
    ${res}=    Serial Read Until    Case     Led: turn on both led    timeout=${3}
    Should Not Be Equal    "${res}"    "None" 

    sleep    1.5s
    Undock    Both 
    ${res}=    Serial Read Until    Case     Action: undock both    timeout=${5}
    Should Not Be Equal    "${res}"    "None" 
    Dock    Both
    ${res}=    Serial Read Until    Case     Action: dock both    timeout=${3}
    Should Not Be Equal    "${res}"    "None" 
    ${res}=    Serial Read Until    Case     Led: turn on both led    timeout=${3}
    Should Not Be Equal    "${res}"    "None" 

Case charger plug in and plug out 
    Comment     charge plugin and plugout should have led appearance
    Plug In
    ${res}=    Read Case    Action: plug in 
    Should Be True    ${res}
    ${res}=    Read Case    Led: turn on front led plug in 
    Should Be True    ${res}
    
    Sleep    1.5s 
    Plug Out
    ${res}=     Read Case    Action: plug out 
    Should Be True    ${res}
    ${res}=    Read Case    Led: turn off front led plug out 
    Should Be True    ${res}

Case control volume 
    Press Button    Left    
    ${res}=    Serial Read Until     Case     Btn: vol up    timeout=${3}
    Should Not Be Equal     "${res}"    "None"
    ${res}=    Serial Read Until    Right     left vol up     timeout=${3}
    Should Not Be Equal     "${res}"    "None"
    ${res}=    Serial Read Until    Left     right vol up     timeout=${3}
    Should Not Be Equal     "${res}"    "None"

    Press Button    Right    
    ${res}=    Serial Read Until     Case     Btn: vol down    timeout=${3}
    Should Not Be Equal     "${res}"    "None"
    ${res}=    Serial Read Until    Right     left vol down     timeout=${3}
    Should Not Be Equal     "${res}"    "None"
    ${res}=    Serial Read Until    Left     right vol down        timeout=${3} 
    Should Not Be Equal     "${res}"    "None"

Case control mode switch 
    Comment     press mode switch button twice
    Press Button    Fn 
    ${res}=    Serial Read Until    Case     Btn: mode switch     timeout=${3}
    Should Not Be Equal     "${res}"    "None"
    ${res}=    Serial Read Until     Right     mode switch     timeout=${3}
    Should Not Be Equal     "${res}"    "None"
    ${res}=    Serial Read Until     Left     mode switch     timeout=${3}
    Should Not Be Equal     "${res}"    "None"
    
    Press Button     Fn
    ${res}=    Serial Read Until    Case     Btn: mode switch     timeout=${3}
    Should Not Be Equal     "${res}"    "None"
    ${res}=    Serial Read Until     Right     mode switch     timeout=${3}
    Should Not Be Equal     "${res}"    "None"
    ${res}=    Serial Read Until     Left     mode switch     timeout=${3}
    Should Not Be Equal     "${res}"    "None"
Case control pairing 
    Press Button    Fn    Long 
    ${res}=    Serial Read Until    Case     Led: tws pairing
    Should Not Be True    "${res}"     None
    Connect Hearing Aids    12:34:56:78:A0:B3 
Ha reconnect phone
    Comment    hearing aids reconnect phone when it undock 

Case open with case close 
    Case Open 
    ${res}=    Read Case    Action: case open
    Should Be True     ${res}
    Sleep    3s 
    Case Close
    ${res}=    Read Case    Action: case close 
    Should Be True     ${res}

Ha play music 
    ${id}=    Audio Get Dev Id
    Should Be True     ${id}>0
    Audio Use A2DP
    Audio Play Simple Audio    timeout=${10}

Ha play phone call 