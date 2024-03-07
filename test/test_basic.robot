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

Resource          ../resource/ha_utils.resource
*** Variables ***
@{aids_list}    Left    Right
${bus_id}    1
${dev_id}    1
${test_id}    1
${test_count}    1
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
    Serial Parallel Read Until    Left    shutdown reason: echo not active    timeout=${10}

    # Serial Parallel Read Until Regex    Right    The Firmware rev is ([0-9]+)    timeout=${5}
    Serial Parallel Read Until    Right    init success    timeout=${10}
    Serial Parallel Read Until    Right    shutdown reason: echo not active    timeout=${10}
    
    Serial Parallel Read Start    ${aids_list}  

    Reset Device 
    ${ret}=  Serial Parallel Read Wait    ${aids_list}  

    Should Not Be Equal As Strings    ${ret}[Left][0]    None
    Should Not Be Equal As Strings    ${ret}[Left][1]    None

    Should Not Be Equal As Strings    ${ret}[Right][0]    None
    Should Not Be Equal As Strings    ${ret}[Right][1]    None
    
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

    Serial Parallel Read Until  Left    system_shutdown    timeout=${15}
    Serial Parallel Read Until  Right   system_shutdown    timeout=${15}
    Serial Parallel Read Start    ${aids_list}
    
    
    Bluetooth Pair    ${ble_address_l}    ${ble_address_r}    ${bt_address_l}    ${bt_address_r}
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
    Init Board    ${bus_id}    ${dev_id}    ${s_port_l}    ${s_port_r}    ${d_port_l}    ${d_port_r}    ${factory_mode} 

BoardTearDown
    Deinit Board

Test Set Up
    Log    test_id:${test_id} s_port_l:${s_port_l} test_count:${test_count}        console=True
    Check Init Soc
    
# Enter Shipping Mode
#     Serial write hex        s_Left        010600
#     Serial write hex        s_Right       010600
#     Sleep    0.2s 