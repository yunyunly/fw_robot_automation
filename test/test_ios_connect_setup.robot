*** Settings ***
Library    ../lib/SerialLib.py
Library    ../lib/PreludeControlLib.py
Library    DateTime
Suite Setup    Setup

*** Variables ***
${port_l}=       /dev/ttyUSB2
${port_r}=       /dev/ttyUSB3
${prelude_id}    1
@{log_keywords}=    ibrt disconnected reason =(.*)    BT disconnected!!!, discReason =(.*)    MOBILE RSSI=(-[0-9]+)    checker: local_box_state:(.*)    VOLT: (.*)

*** Keywords ***
Setup
    Log To Console    ${prelude_id} ${port_l} ${port_r}
    Open Device    ${prelude_id}
    Ha start on
    Serial Open Port    Left    ${port_l}    1152000
    Serial Open Port    Right    ${port_r}    1152000
    Sleep    2s
    Sleep    5s

Ha start on
    Serial Open Port    Left     ${port_l}    9600
    Serial Open Port    Right    ${port_r}    9600

    Charge    Off    lr
    Sleep     0.5s
    Charge    On    lr
    Sleep     0.5s
    Charge    Off    lr

    FOR  ${index}  IN  RANGE    5
        Serial write hex        Left        0001ff00
        Serial write hex        Right       0001ff00
        Sleep    1s
    END
    
    Serial Close Port    Left
    Serial Close Port    Right
    Sleep    1s

*** Test Cases ***
IOS reconnect test
    WHILE    ${True}
        FOR    ${log_keyword}    IN    @{log_keywords}
            Serial Parallel Read Until Regex    Left    ${log_keyword}    10
            Serial Parallel Read Until Regex    Right    ${log_keyword}    10
        END
        
        ${results}=    Serial Parallel Wait    Left Right
        ${CurrentDate}=    Get Current Date
        Set Test Variable    ${record_l}     ${CurrentDate} LEFT: ble disconnect: ${results}[Left][0], bt disconnect:${results}[Left][1], mobile rssi:${results}[Left][2], wear status: ${results}[Left][3], batt: ${results}[Left][4]
        Set Test Variable    ${record_r}     ${CurrentDate} RIGHT: ble disconnect: ${results}[Right][0], bt disconnect:${results}[Right][1], mobile rssi:${results}[Right][2], wear status: ${results}[Right][3], batt: ${results}[Right][4]
        Log To Console    \n ---------------------------------------------- \n
        Log    ${record_l}    console=yes
        Log    ${record_r}    console=yes

    END