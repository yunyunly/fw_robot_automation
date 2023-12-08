*** Setting ***
Documentation     Core Test Cases for testing both Charging Case and Hearing Aids' User Interface Functionality
...                Contains most items in checklist
...               
Suite Setup         Setup
Suite Teardown      Teardown
Test Setup
Test Teardown
Default Tags      Charge
Resource           util.resource 
Library            ../lib/ChargingCaseLib.py
Library    ../lib/SerialLib.py
Library     Collections

*** Keywords ***
Setup 
    Serial Open Case    /dev/ttyACM0    115200   
    Connect Charging Case     ${Charging Case BLE Addr}

Teardown 
    Serial Close Case  

*** Test Cases ***
Test Charge Function Trigger Single Side
    ${side}=    Set Variable     Left 
    ${want}=    Set Variable     SrvCharger L HA
    FOR    ${i}    IN RANGE    0    20    1
        Case Open
        Sleep     0.5s
        Undock    ${side}
        Sleep     0.5s 
        Dock      ${side}
        Sleep     0.5s 
        Case Close
        ${ret}=    Read Case   ${want}    timeout=${7}
        Should Be True     ${ret}
        IF    "${side}" == "Left" 
            ${side}=    Set Variable    Right
            ${want}=    Set Variable     SrvCharger R HA 
        ELSE
            ${side}=    Set Variable    Left
            ${want}=    Set Variable     SrvCharger L HA 
        END
    END
Test Charge Function Trigger Both Side
    ${want 1}=    Set Variable     SrvCharger L HA
    ${want 2}=    Set Variable     SrvCharger R HA
    FOR    ${i}    IN RANGE    0    20    1
        Case Open
        Sleep     0.5s
        Undock    Both
        Sleep     1s 
        Dock      Both
        Sleep     1s 
        Case Close
        ${find}    @{ret1}=    Read Case Regex   SrvCharger (.) HA, new   timeout=${6}
        Should Be True     ${find}
        ${find}    @{ret2}=    Read Case Regex   SrvCharger (.) HA, new    timeout=${2}
        Should Be True     ${find}
        ${ret}=    Combine Lists     ${ret1}    ${ret2}
        List Should Contain Value     ${ret}    L  
        List Should Contain Value     ${ret}    R
        
    END

Test Charge Keep Some Minutes 
    ${want 1}=    Set Variable     SrvCharger L HA
    ${want 2}=    Set Variable     SrvCharger R HA
    Case Open
    Sleep     0.5s
    Undock    Both
    Sleep     1s 
    Dock      Both
    Sleep     1s 
    Case Close
    ${list}=    Create List    
    FOR    ${i}    IN RANGE    0    72    1
        ${find}    @{ret1}=    Read Case Regex   SrvCharger (.) HA, new   timeout=${6}
        Should Be True     ${find}
        ${list}=    Combine Lists    ${list}    ${ret1}
    END
    ${L}=    Count Values In List     ${list}    L 
    Should Be True     ${L} > 36
    ${R}=    Count Values In List     ${list}    R 
    Should Be True     ${R} > 36

Test Charge Until Finish 
    ${want1}=    Set Variable    AppCharge L HA full
    ${want2}=    Set Variable    AppCharge R HA full
    Case Open
    Sleep     0.5s
    Undock    Both
    Sleep     1s 
    Dock      Both
    Sleep     1s 
    Case Close
    FOR    ${j}    IN RANGE    0    2    1
        FOR    ${i}    IN RANGE    0    120    1
            ${find}     @{ret1}=    Read Case Regex   AppCharge (.) HA full     timeout=${10}
            IF    ${find} == ${True}
                Log     ${ret1}
                BREAK
            END
        END
    END
    Case Open
    Sleep      0.5s 
    Request Hearing Aids Soc    Both
    ${find}    ${side}=    Read Case Regex    Uart: (left|right) soc (d+)    timeout=${5}
    Should Be True     ${find}
    Log     ${side}[0]
    Log     ${side}[1]
    ${find}    ${side}=    Read Case Regex    Uart: (left|right) soc (d+)    timeout=${5}
    Should Be True     ${find}
    Log     ${side}[0]
    Log     ${side}[1]
