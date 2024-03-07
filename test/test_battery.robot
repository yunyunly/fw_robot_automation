*** Settings ***
Documentation     Keywords(API) Test Cases for App control HA
Suite Setup       BoardSetUp
Suite Teardown    BoardTearDown
Test Setup        Test Set Up
# Test Setup        Serial Open Hearing Aids 9600
# Test Teardown     Serial Close Hearing Aids 
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
${sleep_time}    60
${s_port_l}    /dev/ttyUSB2
${s_port_r}    /dev/ttyUSB3
${d_port_l}    /dev/ttyUSB4
${d_port_r}    /dev/ttyUSB5
${charging_status}    False

${factory_mode}    True
${charging_time}    0
${low_batt_time}    0
${charging_time_th}    200
${low_batt_time_th}    200


*** Test Cases ***
Charging Test 
    FOR    ${index}   IN RANGE  ${test_count}  
        Check Soc    ${index}  
        Sleep    ${sleep_time} 
    END
   


*** Keywords ***
Check Soc  
    [Arguments]    ${index}=1
    #Log    Charging Test    console=True

    Serial Parallel Read Until Regex    Left    soc: ([0-9]+)%    timeout=${10}
    Serial Parallel Read Until Regex    Right    soc: ([0-9]+)%    timeout=${10}

    Serial Parallel Read Until Regex    Left    batt volt: ([0-9]+)mV    timeout=${10}
    Serial Parallel Read Until Regex    Right    batt volt: ([0-9]+)mV    timeout=${10}

    Serial Parallel Read Start    ${aids_list} 
    Starton Device  
    Run Keyword If    ${charging_status}==True    Charge Device
    Run Keyword If    ${charging_time}>${charging_time_th}    Stopcharge Device With Status
    # Starton Device 
    Reset Device
    Send Heartbeat

    Request Battery Status
    ${result}=  Serial Parallel Read Wait    ${aids_list}  

    # Should Not Be Equal As Strings    ${result}[Left][0][0]    None
    # Should Not Be Equal As Strings    ${result}[Left][1][0]    None
    # Should Not Be Equal As Strings    ${result}[Right][0][0]    None
    # Should Not Be Equal As Strings    ${result}[Right][1][0]    None
	
    #case 1: long time low batt
    Run Keyword If    ${low_batt_time}>${low_batt_time_th}    Charge Device With Status

    Run Keyword If	${result}[Left][0]==None or ${result}[Right][0]==None or ${result}[Left][1]==None or ${result}[Right][1]==None	 Inc Low Batt Count
    Run Keyword If	${result}[Left][0]==None or ${result}[Right][0]==None or ${result}[Left][1]==None or ${result}[Right][1]==None   Return From Keyword
    Set Global Variable    ${low_batt_time}    0

    Run Keyword If    ${charging_status}==True    Increase Charging Time
    Log     ${charging_time}    console=True
    
    Run Keyword If    ${result}[Left][1][0] < 2700 or ${result}[Right][1][0] < 2700    Charge Device With Status
    Run Keyword If    ${result}[Left][1][0] > 4300 and ${result}[Right][1][0] > 4300	Stopcharge Device With Status

    Log    "[id ${test_id}][count ${index}/${test_count}] left_soc: ${result}[Left][0] ; left_volt: ${result}[Left][1] ; right_soc: ${result}[Right][0] ; right_volt: ${result}[Right][1] ; charging status: ${charging_status}"    console=True
    #Log    [id ${test_id}][count ${index}] charging status: ${charging_status}    console=True

    # Run Keyword If    ${result}[Left][0][0] == 100    Run Keyword If    ${result}[Left][1][0] < 4200    Fail
    # Run Keyword If    ${result}[Right][0][0] == 100    Run Keyword If    ${result}[Right][1][0] < 4200    Fail 

Inc Low Batt Count
    ${low_batt_time}=  Evaluate    ${low_batt_time} + 1
    Set Global Variable    ${low_batt_time}
    Log    Low bat time: ${low_batt_time}    console=True
    

Increase Charging Time
    ${charging_time}=  Evaluate    ${charging_time} + 1   
    Set Global Variable    ${charging_time} 
    Charge Device

BoardSetUp
    Init Board    ${bus_id}    ${dev_id}    ${s_port_l}    ${s_port_r}    ${d_port_l}    ${d_port_r}    ${factory_mode} 
    Charge Device With Status
    # Send Heartbeat
    # Sleep    5s
    # Reset Device

    # Run Keyword If    ${factory_mode}==False    Send Heartbeat 

BoardTearDown
    Deinit Board

Test Set Up
    Log    test_id: ${test_id}    console=True
    Log    test_time: ${test_count}hrs   console=True
    ${tmp}=    Evaluate    ${test_count}*60
    ${result}=    Convert To String    ${tmp}
    Set Suite Variable    ${test_count}        ${result}  


    # Check Init Soc 

Charge Device With Status
    Log    Charge On    console=True
    Charge    On    lr
    Sleep     1s
    Set Global Variable    ${charging_status}    True

Stopcharge Device With Status
    Log    Charge Off    console=True
    Charge    Off    lr
    Sleep     1s
    Set Global Variable    ${charging_status}    False
    Set Global Variable    ${charging_time}    0
    #check if open 
 #   Serial Parallel Read Until    Left      The Firmware rev is␊    timeout=${10}
 #   Serial Parallel Read Until    Right     The Firmware rev is␊    timeout=${10}

 #   ${ret}=  Serial Parallel Read Wait   Left Right 
 #   Log To Console      ${ret}
 #   Should Not Be Equal As Strings    ${ret}[Left]    [None]
 #   Should Not Be Equal As Strings    ${ret}[Right]   [None]

    
