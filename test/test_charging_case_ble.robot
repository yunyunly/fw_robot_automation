
*** Settings ***
Documentation     Stress Test Cases for Charging Case's BLE
Suite Setup       Setup
Suite Teardown    Teardown
Test Setup        
Test Teardown     
Library           ../lib/ChargingCaseLib.py
Library           ../lib/SerialLib.py

*** Variables ***
${CC_BLE_ADDR}    D0:14:11:20:24:F2

*** Test Cases ***
Case open ble activity
    Case Disconnect Hearing Aids 
    Sleep    0.5s
    Print Info
    ${find}    ${ctx}=    Read Case Regex    SOC ([0-9]+) Volt ([0-9]+) Curr ([\\+\\-]?[0-9]+\\.[0-9]+) Temp ([\\+\\-]?[0-9]+) Charge ([0-9]+)    timeout=${3}
    Log To Console    ${ctx}
    ${soc}=    Set Variable    ${ctx}[0]
    Should Be True    ${soc} >= 10 and ${soc} <= 100
    Sleep    0.5s 
    ${case_open_log}=    Set Variable    Ble: case open
    ${connect_ha_log}=    Set Variable    BLE start
    ${connect_create_log}=    Set Variable    CREATE CONNECTION TO END DEVICE 1
    ${connect_create_success_log}=    Set Variable    Initial conn process successed
    ${connect_success_log}=    Set Variable    CONNECTION SUCCESS WITH END DEVICE 1
    Case Close
    Sleep    1s
    Case Disconnect Hearing Aids
    Sleep    1s
    Case Open
    ${fd}=    Read Case    ${case_open_log}
    Should Be True    ${fd}
    ${fd}    Read Case    ${connect_ha_log}
    Should Be True    ${fd}
    ${fd}    Read Case    ${connect_create_log}
    Should Be True    ${fd}
    ${fd}    Read Case    ${connect_create_success_log}
    Should Be True    ${fd}
    ${fd}    Read Case    ${connect_success_log}    ${5}
    Should Be True    ${fd}
    Case Close
    Sleep    1s

*** Keywords ***
Setup
    Serial Open Port    Case    /dev/ttyACM0    115200
    Connect Charging Case    ${CC_BLE_ADDR}
    Case Open
    Sleep    1s
    Case Close
    Sleep    1s
    Press Button    Reset   Long
    Sleep    15s
    Connect Charging Case    ${CC_BLE_ADDR}
    Sleep    0.5s

Teardown
    Disconnect Charging Case    ${CC_BLE_ADDR}
    Serial Close Port    Case

Read Case
    [Arguments]    ${str}    ${timeout}=${3}
    ${res}=    Serial Read Until    Case    ${str}    timeout=${timeout}
    ${ret}=    Set Variable If    "${res}" == "None"    ${False}    ${True}
    RETURN    ${ret}

Read Case Regex
    [Arguments]    ${str}    ${timeout}=${3}
    @{res}=    Serial Read Until Regex    Case    ${str}    timeout=${timeout}
    IF    "${res}"=="None" \
        RETURN    ${False}    @{EMPTY}
    ELSE
        ${length}=    Get Length    ${res}
        IF    ${length} == ${0}
            RETURN    ${False}    @{EMPTY}
        ELSE
            RETURN    ${True}    ${res}
        END
    END
