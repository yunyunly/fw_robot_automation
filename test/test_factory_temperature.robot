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
Library           DateTime

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
${charging_status}    False

${factory_mode}    True
${charging_count}    0
${decharging_count}    0

${interval_secs}    3

${charging_hrs}    2

${charging_th}    

# [temp] 26 [soc] 64 [u] 3596 [i] -9760
@{log_keywords}=    >>>> \\[temp\\]\\s+([0-9]+)    \\[soc\\]\\s+([0-9]+)     \\[u\\]\\s+([+-]?[0-9]+)    \\[i\\]\\s+([+-]?[0-9]+)

*** Test Cases ***
Charging Test 
    ${interval_secs_int}=    Convert To Integer    ${interval_secs}
    # Starton Device  
    # Reset Device
    FOR    ${index}   IN RANGE  ${test_count}  
      FOR    ${log_keyword}    IN    @{log_keywords}
            Serial Parallel Read Until Regex    Left    ${log_keyword}    timeout=${interval_secs_int}
            Serial Parallel Read Until Regex    Right    ${log_keyword}    timeout=${interval_secs_int}
        END

        
        ${results}=    Serial Parallel Wait    Left Right
        ${CurrentDate}=    Get Current Date

        Run Keyword If    ${charging_status}==True and ${charging_count}>${charging_th}    Stopcharge Device With Status
        Run Keyword If    ${charging_status}==False and ${charging_count}>${charging_th}    Charge Device With Status

        Set Test Variable    ${record_l}     ${CurrentDate} Charging status: ${charging_status}; LEFT: temp: ${results}[Left][0], soc:${results}[Left][1], u:${results}[Left][2], i: ${results}[Left][3];
        Set Test Variable    ${record_r}     ${CurrentDate} Charging status: ${charging_status}; Right: temp: ${results}[Right][0], soc:${results}[Right][1], u:${results}[Right][2], i: ${results}[Right][3];
        Log To Console    \n ---------------------------------------------- \n
        Log    ${record_l}    console=yes
        Log    ${record_r}    console=yes

        Increase Charging Count


        Sleep    ${interval_secs} 
    END
   


*** Keywords ***
Increase Charging Count
    ${charging_count}=  Evaluate    ${charging_count} + 1   
    Set Global Variable    ${charging_count} 

# Increase Decharging Time
#     ${charging_time}=  Evaluate    ${charging_time} + 1   
#     Set Global Variable    ${charging_time} 
#     # Charge Device

BoardSetUp
    Init Board Without Single Serial    ${bus_id}    ${dev_id}    ${d_port_l}    ${d_port_r}    ${factory_mode} 

    Starton Device  
    Reset Device
    
    Charge Device With Status

BoardTearDown
    Deinit Board Without Single Serial

Test Set Up
    Log    test_id: ${test_id}    console=True
    Log    test_time: ${test_count}hrs   console=True
    ${tmp}=    Evaluate    ${test_count}*60*60/${interval_secs} 
    ${result}=    Convert To String    ${tmp}
    Set Suite Variable    ${test_count}        ${result}  

    ${tmp}=    Evaluate    ${charging_hrs}*60*60/${interval_secs} 
    ${result}=    Convert To String    ${tmp}
    Set Suite Variable    ${charging_th}        ${result}  

    # ${tmp}=    Evaluate    ${decharging_hrs}*60*60/${interval_secs} 
    # ${result}=    Convert To String    ${tmp}
    # Set Suite Variable    ${decharging_count}        ${result}  


Charge Device With Status
    Log    Charge On    console=True
    Charge    On    lr
    Sleep     1s
    Set Global Variable    ${charging_status}    True
    Set Global Variable    ${charging_count}    0

Stopcharge Device With Status
    Log    Charge Off    console=True
    Charge    Off    lr
    Sleep     1s
    Set Global Variable    ${charging_status}    False
    Set Global Variable    ${charging_count}    0

    
