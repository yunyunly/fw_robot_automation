*** Settings ***
Documentation     Keywords(API) Test Cases for App control HA
Suite Setup       BoardSetUp
Suite Teardown    BoardTearDown
Test Setup        Test Set Up
#Test Teardown     SerialTearDown

#Library           ../lib/HearingAidLib.py
Library           ../lib/SerialLib.py
Library           ../lib/PreludeControlLib.py
Library           BuiltIn

*** Variables ***
@{aids_list}    Left    Right
${bus_id}    1
${dev_id}    1
${test_id}    1
# ${test_count}    1
${s_port_l}    /dev/ttyUSB2
${s_port_r}    /dev/ttyUSB3
${d_port_l}    /dev/ttyUSB4
${d_port_r}    /dev/ttyUSB5
${factory_mode}    True

${ble_address_l}    121233565681
${ble_address_r}    121233565681
${bt_address_l}    121233565680
${bt_address_r}    121233565681

${ble_cmd_l}    00010906${ble_address_l} 
${ble_cmd_r}    00010906${ble_address_r} 
${bt_cmd_l}    00010706${bt_address_l} 
${bt_cmd_r}    00010706${bt_address_r} 

*** Test Cases ***
Check Release And Initialization
    Log    Check Release And Initialization    console=true
    Starton Device

    # Serial Parallel Read Until Regex    Left    The Firmware rev is ([0-9]+)    timeout=${5}
    Serial Parallel Read Until    Left    init success    timeout=${10}
    Serial Parallel Read Until    Left    VERSO RELEASE MODE    timeout=${10}
    Serial Parallel Read Until    Left    shutdown reason: echo not active    timeout=${10}

    # Serial Parallel Read Until Regex    Right    The Firmware rev is ([0-9]+)    timeout=${5}
    Serial Parallel Read Until    Right    init success    timeout=${10}
    Serial Parallel Read Until    Right    VERSO RELEASE MODE    timeout=${10}
    Serial Parallel Read Until    Right    shutdown reason: echo not active    timeout=${10}
    
    Serial Parallel Read Start    ${aids_list}  

    Reset Device 
    ${ret}=  Serial Parallel Read Wait    ${aids_list}  

    # Log To Console    ${ret}[Left][0]

    Should Not Be Equal As Strings    ${ret}[Left][0]    None
    Should Not Be Equal As Strings    ${ret}[Left][1]    None
    Should Not Be Equal As Strings    ${ret}[Left][2]    None

    Should Not Be Equal As Strings    ${ret}[Right][0]    None
    Should Not Be Equal As Strings    ${ret}[Right][1]    None
    Should Not Be Equal As Strings    ${ret}[Right][2]    None
    
    #Already shutdown
    Sleep     3s

Check Heartbeat And Shutdown
    Log    Check Heartbeat And Shutdown    console=True
    Starton Device 
    Send Heartbeat

    Serial Parallel Read Until  Left    shutdown reason: echo not active    timeout=${10}
    Serial Parallel Read Until  Right   shutdown reason: echo not active    timeout=${10}
    Serial Parallel Read Start    ${aids_list}
    ${ret}=  Serial Parallel Read Wait   ${aids_list}
    Should Be Equal As Strings    ${ret}[Left][0]    None
    Should Be Equal As Strings    ${ret}[Right][0]    None

    Serial Parallel Read Until  Left    shutdown reason: comm cmd  timeout=${5}
    Serial Parallel Read Until  Right   shutdown reason: comm cmd  timeout=${5}
    Serial Parallel Read Start    ${aids_list}

    Shutdown Device 

    ${ret}=  Serial Parallel Read Wait   ${aids_list}

    Should Not Be Equal As Strings    ${ret}[Left][0]    None
    Should Not Be Equal As Strings    ${ret}[Right][0]    None
    Sleep     3s

Check Charge And Shutdown
    Log    Check Charge And Shutdown    console=True
    Charge Device   
    
    Serial Parallel Read Until  Left    STILL CHARING, SHUTDOWN    timeout=${15}
    Serial Parallel Read Until  Right   STILL CHARING, SHUTDOWN    timeout=${15}
    
    Serial Parallel Read Start    ${aids_list}
    Reset Device 
    Send Heartbeat
    ${ret}=  Serial Parallel Read Wait   ${aids_list}

    Should Not Be Equal As Strings    ${ret}[Left][0]    None
    Should Not Be Equal As Strings    ${ret}[Right][0]    None

    Shutdown Device 
    Sleep     3s

Check Bluetooth Pairing And Broadcast
    Log    Check Bluetooth Pairing And Broadcast    console=True
    Starton Device 

    Serial Parallel Read Until  Left    system_shutdown    timeout=${10}
    Serial Parallel Read Until  Right   system_shutdown    timeout=${10}
    Serial Parallel Read Start    ${aids_list}
    
    
    Reset Device 
    
    Send Heartbeat    4

    Send Comm Test
    Send Request Bt Addr
    #send ble/bt to each other 
    Serial write hex        s_Left        ${bt_cmd_r}  
    Serial write hex        s_Right       ${bt_cmd_l} 

    Sleep    0.5s
    Serial write hex        s_Left        ${ble_cmd_r} 
    Serial write hex        s_Right       ${ble_cmd_l} 
    
    Sleep    0.5s
    Send Heartbeat    

    ${ret}=    Serial Parallel Read Wait    ${aids_list}
    
    #Shutdown Device 
    Sleep    3s
    Should Not Be Equal As Strings    ${ret}[Left][0]    None
    Should Not Be Equal As Strings    ${ret}[Right][0]    None   

    Shutdown Device 
    Sleep    3s
     
    #NOTICE: this test loop that might get the information for last loop in searial, using sleep to make the system shutdown eventaully.
    #Need the information for bt pair trace.


    Serial Parallel Read Until  Left    Access mode changed to 3    timeout=${15}
    Serial Parallel Read Until  Right   Access mode changed to 3    timeout=${15}

    Serial Parallel Read Until  Left    TWS-STATE:CONNECTING EVENT=EVT_TWS_CONNECT_FAILED    timeout=${15}
    Serial Parallel Read Until  Right   TWS-STATE:CONNECTING EVENT=EVT_TWS_CONNECT_FAILED    timeout=${15}

    Serial Parallel Read Start    ${aids_list}

    Starton Device    
    Send Heartbeat    5   
    Send Adv

    ${ret}=  Serial Parallel Read Wait   ${aids_list}
    Should Be True    '${ret}[Left][0]'!='None' or '${ret}[Right][0]'!='None'

    # Add when bug fixed 
    # Should Be True    '${ret}[Left][1]'=='None' and '${ret}[Right][1]'=='None'

    Shutdown Device 
    Sleep     3s

Check Box Status
    Log    Check Box Status    console=True
    Starton Device

    Send Heartbeat
    Send BoxClose
    Sleep    20s

    Serial Parallel Read Until  Left    ori box state = IN_BOX_CLOSED,new = IN_BOX_OPEN    timeout=${5}
    Serial Parallel Read Until  Right    ori box state = IN_BOX_CLOSED,new = IN_BOX_OPEN    timeout=${5}
    Serial Parallel Read Until  Left    ori box state = IN_BOX_OPEN,new = OUT_BOX    timeout=${10}
    Serial Parallel Read Until  Right    ori box state = IN_BOX_OPEN,new = OUT_BOX    timeout=${10}
    Serial Parallel Read Until  Left    custom_ui:case open run complete    timeout=${15}    #10->15s
    Serial Parallel Read Until  Right    custom_ui:case open run complete    timeout=${15}
    Serial Parallel Read Until  Left    app_advertising_started   timeout=${10}
    Serial Parallel Read Until  Right    app_advertising_started   timeout=${10}
    Serial Parallel Read Start    ${aids_list}

    #Reset Device
    Send BoxOpen
    Send BoxOpen
    Send Heartbeat    5

    ${ret}=  Serial Parallel Read Wait   ${aids_list}
    Log    ${ret}
    
    Should Not Be Equal As Strings    ${ret}[Left][0]    None
    Should Not Be Equal As Strings    ${ret}[Right][0]    None
    Should Not Be Equal As Strings    ${ret}[Left][1]    None
    Should Not Be Equal As Strings    ${ret}[Right][1]    None
    Should Not Be Equal As Strings    ${ret}[Left][2]    None
    Should Not Be Equal As Strings    ${ret}[Right][2]    None
    Should Be True    '${ret}[Left][3]'!='None' or '${ret}[Right][3]'!='None'

    Sleep    5s

#OUT_BOX_WEARED -> OUT_BOX -> IN_BOX_OPEN
    serial_parallel_read_until  Left    ori box state = OUT_BOX(.*)new = IN_BOX_OPEN    timeout=${10}
    serial_parallel_read_until  Right   ori box state = OUT_BOX(.*)new = IN_BOX_OPEN    timeout=${10}
    Serial Parallel Read Until  Left    ori box state = IN_BOX_OPEN,new = IN_BOX_CLOSED    timeout=${10}
    Serial Parallel Read Until  Right   ori box state = IN_BOX_OPEN,new = IN_BOX_CLOSED    timeout=${10}

    Serial Parallel Read Start    ${aids_list}
    Send Heartbeat    5
    Send BoxClose
    ${ret}=  Serial Parallel Read Wait   ${aids_list}
    Log    ${ret}
    Should Not Be Equal As Strings    ${ret}[Left][0]    None
    Should Not Be Equal As Strings    ${ret}[Right][0]    None
    Should Not Be Equal As Strings    ${ret}[Left][1]    None
    Should Not Be Equal As Strings    ${ret}[Right][1]    None

    Shutdown Device 
    Sleep     3s

# Test Shipping Mode
#     Log    Test Shipping Mode    console=True

    
    
*** Keywords ***
BoardSetUp
    Log    s_port_l:${s_port_l}    console=True
    Log    s_port_r:${s_port_r}    console=True

    Log    d_port_l:${d_port_l}    console=True
    Log    d_port_r:${d_port_r}    console=True
    Log    factory_mode:${factory_mode}    console=True

    Log    ble_address_l:${ble_address_l}    console=True
    Log    ble_address_r:${ble_address_r}    console=True
    Log    bt_address_l:${bt_address_l}    console=True
    Log    bt_address_r:${bt_address_r}    console=True

    Log    bus_id:${bus_id}    console=True
    Log    device_id:${dev_id}    console=True

    Open Device With Bus    ${bus_id}    ${dev_id}  

    SerialSetUp
    Run Keyword If    ${factory_mode}    Check Factory Mode  

BoardTearDown
    SerialTearDown
    Close Ftdi

Test Set Up
    Log    test_id:${test_id}    console=True
    Check Init Soc

Check Init Soc   
    Log    Check Init Soc    console=True
    Starton Device
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

    #Reset Device 

Check Factory Mode 
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

    [Arguments]    ${num}=3
    FOR    ${counter}   IN RANGE  ${num} 
        Serial Write Str             s_Left      [to_rel,]
        Serial Write Str             s_Right     [to_rel,]
    
        Sleep   0.7s
    END

    Should Not Be Equal As Strings    ${ret}[Left][0]    None
    Should Not Be Equal As Strings    ${ret}[Right][0]    None

    Should Be Equal As Strings    ${ret}[Left][1]    None
    Should Be Equal As Strings    ${ret}[Right][1]    None

SerialSetUp
    Serial Open Hearing Aids 1152000
    Serial Open Hearing Aids 9600

    # Check Init Soc 

SerialTearDown
    Serial Close Hearing Aids 9600
    Serial Close Hearing Aids 1152000
    
Serial Open Hearing Aids 9600
    Serial Open Port    s_Left     ${s_port_l}    9600
    Serial Open Port    s_Right    ${s_port_r}    9600
    
Serial Open Hearing Aids 1152000
    Serial Open Port    Left     ${d_port_l}    1152000
    Serial Open Port    Right    ${d_port_r}    1152000

Serial Close Hearing Aids 9600
    Serial Close Port    s_Left
    Serial Close Port    s_Right

Serial Close Hearing Aids 1152000
    Serial Close Port    Left
    Serial Close Port    Right

Starton Device 
    Charge    Off    lr
    Sleep     0.5s
    Charge    On    lr
    Sleep     0.5s
    Charge    Off    lr
    Sleep    2s

Charge Device
    Log    Charge Device    console=True
    Charge    Off    lr
    Sleep     0.5s
    Charge    On    lr

    #check if open 
 #   Serial Parallel Read Until    Left      The Firmware rev is␊    timeout=${10}
 #   Serial Parallel Read Until    Right     The Firmware rev is␊    timeout=${10}

 #   ${ret}=  Serial Parallel Read Wait   Left Right 
 #   Log To Console      ${ret}
 #   Should Not Be Equal As Strings    ${ret}[Left]    [None]
 #   Should Not Be Equal As Strings    ${ret}[Right]   [None]

Reset Device 
    Log    Reset    console=True 
    Reset     On    lr 
    Sleep    0.2s 
    Reset     Off    lr
    Sleep    1s

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

# Enter Shipping Mode
#     Serial write hex        s_Left        010600
#     Serial write hex        s_Right       010600
#     Sleep    0.2s 