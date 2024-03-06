*** Settings ***
Documentation     An simple resource file
Library           ../lib/SerialLib.py
Library           ../lib/PreludeControlLib.py
Library           ../lib/AndroidTestLib.py
Library           ../lib/BluetoothLib.py

*** Variables ***
@{aids_list}    Left    Right
${ble_cmd_l}
${ble_cmd_r}
${bt_cmd_l}
${bt_cmd_r}

*** Keywords ***
Starton Device 
    Charge    Off    lr
    Sleep     0.5s
    Charge    On    lr
    Sleep     0.5s
    Charge    Off    lr
    Sleep    2s

Reset Device 
    Reset     On    lr 
    Sleep    0.2s 
    Reset     Off    lr
    Sleep    1s

Charge Device
    Charge    Off    lr
    Sleep     0.5s
    Charge    On    lr

SerialSetUp
    [Arguments]    ${s_port_l}    ${s_port_r}    ${d_port_l}    ${d_port_r}
    Serial Open Hearing Aids 1152000    ${d_port_l}    ${d_port_r}
    Serial Open Hearing Aids 9600    ${s_port_l}    ${s_port_r}

    # Check Init Soc 

SerialTearDown  
    Serial Close Hearing Aids 9600
    Serial Close Hearing Aids 1152000
    
Serial Open Hearing Aids 9600
    [Arguments]    ${s_port_l}    ${s_port_r}
    Serial Open Port    s_Left     ${s_port_l}    9600
    Serial Open Port    s_Right    ${s_port_r}    9600
    
Serial Open Hearing Aids 1152000
    [Arguments]    ${d_port_l}    ${d_port_r}  
    Serial Open Port    Left     ${d_port_l}    1152000
    Serial Open Port    Right    ${d_port_r}    1152000

Serial Close Hearing Aids 9600
    Serial Close Port    s_Left   
    Serial Close Port    s_Right    

Serial Close Hearing Aids 1152000
    Serial Close Port    Left
    Serial Close Port    Right

Check Init Soc   
    Log    Check Init Soc    console=True
    Starton Device
    Send Heartbeat    10
    Serial Parallel Read Until Regex    Left    soc: ([0-9]+)%    timeout=${10}
    Serial Parallel Read Until Regex    Right    soc: ([0-9]+)%    timeout=${10}
    

    Serial Parallel Read Start    ${aids_list} 
    Reset Device 
    Send Heartbeat    
    ${soc}=  Serial Parallel Read Wait    ${aids_list}  

    Log    Left soc = ${soc}[Left][0][0] ; Right soc = ${soc}[Right][0][0]    console=True
    Run Keyword If    ${soc}[Left][0][0] <10 or ${soc}[Right][0][0] <= 10    Charge Device

    Should Be True    ${soc}[Left][0][0] >= 10 and ${soc}[Left][0][0] <= 100
    Should Be True    ${soc}[Right][0][0] >= 10 and ${soc}[Right][0][0] <= 100

Check Factory Mode 
    [Arguments]    ${num}=3

    Log    Factory mode enable!!!    console=True
    Starton Device 

    Serial Parallel Read Until    Left    VERSO FACTORY MODE    timeout=${10}
    Serial Parallel Read Until    Right    VERSO FACTORY MODE    timeout=${10}

    Serial Parallel Read Until    Left    Start pmu shutdown    timeout=${10}
    Serial Parallel Read Until    Right    Start pmu shutdown    timeout=${10}
    
    Serial Parallel Read Start    ${aids_list}  
    Reset Device
    ${ret}=  Serial Parallel Read Wait    ${aids_list}  
    
    Log    Turn To Release Mode    console=True

    FOR    ${counter}   IN RANGE  ${num} 
        Serial Write Str             s_Left      [to_rel,]
        Serial Write Str             s_Right     [to_rel,]
    
        Sleep   0.7s
    END

    Should Not Be Equal As Strings    ${ret}[Left][0]    None
    Should Not Be Equal As Strings    ${ret}[Right][0]    None

    Should Be Equal As Strings    ${ret}[Left][1]    None
    Should Be Equal As Strings    ${ret}[Right][1]    None


Log Basic Info
    [Arguments]     ${bus_id}    ${dev_id}    ${s_port_l}    ${s_port_r}    ${d_port_l}    ${d_port_r}    ${factory_mode}
    Log    s_port_l:${s_port_l}    console=True
    Log    s_port_r:${s_port_r}    console=True

    Log    d_port_l:${d_port_l}    console=True
    Log    d_port_r:${d_port_r}    console=True
    Log    factory_mode:${factory_mode}    console=True

    # Log    ble_address_l:${ble_address_l}    console=True
    # Log    ble_address_r:${ble_address_r}    console=True
    # Log    bt_address_l:${bt_address_l}    console=True
    # Log    bt_address_r:${bt_address_r}    console=True

    Log    bus_id:${bus_id}    console=True
    Log    device_id:${dev_id}    console=True

Init Board
    [Arguments]    ${bus_id}    ${dev_id}    ${s_port_l}    ${s_port_r}    ${d_port_l}    ${d_port_r}    ${factory_mode}
    Log Basic Info    ${bus_id}    ${dev_id}    ${s_port_l}    ${s_port_r}    ${d_port_l}    ${d_port_r}    ${factory_mode}
    Open Device With Bus    ${bus_id}    ${dev_id}  
    SerialSetUp    ${s_port_l}    ${s_port_r}    ${d_port_l}    ${d_port_r}     
    Run Keyword If    ${factory_mode}    Check Factory Mode    
    # Starton Device
    # Send Heartbeat

Bluetooth Pair
    [Arguments]    ${ble_address_l}    ${ble_address_r}     ${bt_address_l}    ${bt_address_r}     
    Starton Device
    Reset Device

    Send Heartbeat    4

    #send ble/bt to each other 
    Set Test Variable    ${ble_cmd_l}    00010906${ble_address_l} 
    Set Test Variable    ${ble_cmd_r}    00010906${ble_address_r} 
    Set Test Variable    ${bt_cmd_l}    00010706${bt_address_l} 
    Set Test Variable    ${bt_cmd_r}    00010706${bt_address_r} 

    Serial write hex    s_Left    ${bt_cmd_r}  
    Serial write hex    s_Right    ${bt_cmd_l} 

    Sleep    0.5s
    Serial write hex    s_Left    ${ble_cmd_r} 
    Serial write hex    s_Right    ${ble_cmd_l} 
    
    Sleep    0.5s
    Send Heartbeat    

    # Sleep    10s

    # Starton Device 
    # Send Heartbeat    5

Connect Bluetooth    
    [Arguments]    ${ble_address_r}
    ${tmp}=    Addr Insert Colon   ${ble_address_r}
    Set Suite Variable    ${ble_address_r}    ${tmp}

    Starton Device
    Reset Device
    Send Heartbeat
    Ble Connect Ha    ${ble_address_r}
    Sleep    3s

Disconnect Bluetooth
    [Arguments]    ${ble_address_r}
    ${tmp}=    Addr Insert Colon   ${ble_address_r}
    Set Suite Variable    ${ble_address_r}    ${tmp}
    Ble Disconnect Ha    ${ble_address_r}   

Deinit Board   
    # Shutdown Device
    SerialTearDown
    Close Ftdi

Shutdown Device 
    Serial write hex    s_Left    010100
    Serial write hex    s_Right   010100
    Sleep     0.2s

    Serial write hex    s_Left    010100
    Serial write hex    s_Right   010100
    Sleep     0.2s

Send Heartbeat  
    [Arguments]    ${num}=3
    FOR    ${counter}   IN RANGE  ${num} 
        #send adv 
        Serial write hex        s_Left        01ff00
        Serial write hex        s_Right       01ff00
        Sleep    0.7s
    END

Send BoxOpen
    Serial write hex        s_Left        010200
    Serial write hex        s_Right       010200
    Sleep    0.2s 

Send BoxClose
    Serial write hex        s_Left        010300
    Serial write hex        s_Right       010300
    Sleep    0.2s 

Send Adv 
    FOR    ${counter}   IN RANGE  2
        #send adv 
        Serial write hex        s_Left        010a00
        Serial write hex        s_Right       010a00
        Sleep    0.7s
    END

Send Comm Test
    Serial write hex        s_Left        010000
    Serial write hex        s_Right       010000
    Sleep    0.2s 

Send Request Bt Addr
    Serial write hex        s_Left        010600
    Serial write hex        s_Right       010600
    Sleep    0.2s 