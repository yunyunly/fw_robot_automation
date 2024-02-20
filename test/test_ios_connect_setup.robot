*** Settings ***
Library    ../lib/SerialLib.py
Library    ../lib/PreludeControlLib.py
Library    DateTime
Suite Setup    Setup
Suite Teardown    Teardown

*** Variables ***
${s_port_l}=       /dev/ttyUSB2
${s_port_r}=       /dev/ttyUSB3

${d_port_l}=       /dev/ttyUSB4
${d_port_r}=       /dev/ttyUSB5

${prelude_id}    1
${bus_id}    1
${dev_id}    1
${count}    1

${ble_address_l}    121233565681
${ble_address_r}    121233565681
${bt_address_l}    121233565680
${bt_address_r}    121233565681

${ble_cmd_l}    00010906${ble_address_l} 
${ble_cmd_r}    00010906${ble_address_r} 
${bt_cmd_l}    00010706${bt_address_l} 
${bt_cmd_r}    00010706${bt_address_r} 

@{log_keywords}=    ibrt disconnected reason =(.*)    BT disconnected!!!, discReason =(.*)    MOBILE RSSI=(-[0-9]+)    checker: local_box_state:(.*)    VOLT: (.*)

*** Keywords ***
Setup    
    Log    ${count} ${bus_id} ${dev_id} ${s_port_l} ${s_port_r} ${d_port_l} ${d_port_r}    console=yes
    Log    ${ble_address_l} ${ble_address_l} ${bt_address_l} ${bt_address_l}    console=yes

    Open Device With Bus    ${bus_id}    ${dev_id}
    Serial Open Port    Left    ${d_port_l}    1152000
    Serial Open Port    Right    ${d_port_r}    1152000

    Serial Open Port    s_Left     ${s_port_l}    9600
    Serial Open Port    s_Right    ${s_port_r}    9600

    Starton Device 

    Reset Device

    Send Heartbeat
    # #send ble/bt to each other 
    # Serial write hex        s_Left        ${ble_cmd_r} 
    # Serial write hex        s_Left        ${bt_cmd_r}  

    # Serial write hex        s_Right       ${ble_cmd_l} 
    # Serial write hex        s_Right       ${bt_cmd_l} 

    # Sleep    10s

    # Starton Device 
    # Send Heartbeat    5

    Sleep    3s

Send Heartbeat  
    [Arguments]    ${num}=3
    FOR    ${counter}   IN RANGE  ${num} 
        #send adv 
        Serial write hex        s_Left        01ff00
        Serial write hex        s_Right       01ff00
        Sleep    0.7s
    END

Teardown

    Shutdown Device 
    Sleep    3s

    Serial Close Port    s_Left
    Serial Close Port    s_Right

    Serial Close Port    Left
    Serial Close Port    Right
    Close Ftdi

Starton Device 
    Charge    Off    lr
    Sleep     0.5s
    Charge    On    lr
    Sleep     0.5s
    Charge    Off    lr
    Sleep    2s

Reset Device 
    Log    Reset    console=True 
    Reset     On    lr 
    Sleep    0.2s 
    Reset     Off    lr
    Sleep    1s

Send BoxOpen
    Serial write hex        s_Left        010200
    Serial write hex        s_Right       010200
    Sleep    0.2s 

Shutdown Device 
    Serial write hex    s_Left    010100
    Serial write hex    s_Right   010100
    Sleep     0.2s

    Serial write hex    s_Left    010100
    Serial write hex    s_Right   010100
    Sleep     0.2s

*** Test Cases ***
IOS reconnect test
     FOR    ${cnt}    IN RANGE    ${count}

        Log    ${cnt}    console=yes
        FOR    ${log_keyword}    IN    @{log_keywords}
            Serial Parallel Read Until Regex    Left    ${log_keyword}    timeout=${10}
            Serial Parallel Read Until Regex    Right    ${log_keyword}    timeout=${10}
        END
        
        ${results}=    Serial Parallel Wait    Left Right
        ${CurrentDate}=    Get Current Date
        Set Test Variable    ${record_l}     ${CurrentDate} d_port_l:${d_port_l}, LEFT: ble disconnect: ${results}[Left][0], bt disconnect:${results}[Left][1], mobile rssi:${results}[Left][2], wear status: ${results}[Left][3], batt: ${results}[Left][4]
        Set Test Variable    ${record_r}     ${CurrentDate} d_port_r:${d_port_r}, RIGHT: ble disconnect: ${results}[Right][0], bt disconnect:${results}[Right][1], mobile rssi:${results}[Right][2], wear status: ${results}[Right][3], batt: ${results}[Right][4]
        Log To Console    \n ---------------------------------------------- \n
        Log    ${record_l}    console=yes
        Log    ${record_r}    console=yes

    END