*** Settings ***
Documentation     Keywords(API) Test Cases for App control HA
Suite Setup       BoardSetUp
Suite Teardown    BoardTearDown
Library           ../lib/PreludeControlLib.py
Library           BuiltIn

*** Variables ***
@{aids_list}    Left    Right
${bus_id}    1
${dev_id}    1


*** Test Cases ***
Charge Device
    Log To Console    Charge Device
    Charge    Off    lr
    Sleep     0.5s
    Charge    On    lr
    Sleep     2000s
    

*** Keywords ***
BoardSetUp
    Log To Console    bus_id:${bus_id}
    Log To Console    device_id:${dev_id}

    Open Device With Bus    ${bus_id}    ${dev_id}  

BoardTearDown
    Close Ftdi


