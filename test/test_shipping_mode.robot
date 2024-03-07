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
Enter Shipping Mode
    Log    Test Shipping Mode    console=true
    Starton Device
    Reset Device
    Send Heartbeat

    Serial Parallel Read Until    Left    HEAD: dire 0x01, evt 0x00, len 0     timeout=${10}
    Serial Parallel Read Until    Right    HEAD: dire 0x01, evt 0x00, len 0      timeout=${10}
    Serial Parallel Read Start    ${aids_list}  
    Send Comm Test
    ${ret}=  Serial Parallel Read Wait    ${aids_list}  
    Should Not Be Equal As Strings    ${ret}[Left][0]    None
    Should Not Be Equal As Strings    ${ret}[Right][0]    None

    Serial Parallel Read Until    Left    Shipmode: success    timeout=${10}
    Serial Parallel Read Until    Right    Shipmode: success     timeout=${10}
    Serial Parallel Read Start    ${aids_list}  
    Serial write hex        s_Left    010F04A5C39625
    Serial write hex        s_Right    010F04A5C39625
    ${ret}=  Serial Parallel Read Wait    ${aids_list}  
    Should Not Be Equal As Strings    ${ret}[Left][0]    None
    Should Not Be Equal As Strings    ${ret}[Right][0]    None
    
    #Already shutdown
    Sleep     3s

# Quit Shipping Mode
    
*** Keywords ***
BoardSetUp
    Init Board    ${bus_id}    ${dev_id}    ${s_port_l}    ${s_port_r}    ${d_port_l}    ${d_port_r}    ${factory_mode} 

BoardTearDown
    Deinit Board

Test Set Up
    Log    test_id:${test_id} s_port_l:${s_port_l} test_count:${test_count}        console=True
    Check Init Soc

    
