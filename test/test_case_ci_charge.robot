*** Settings ***
Library    ../lib/SerialLib.py
Suite Setup    Setup
Suite Teardown    Teardown

*** Keywords ***
Setup
    Serial Open Port    Case    ${case_charge_relay_port}    115200
Teardown
    FOR  ${counter}  IN RANGE    3
        Serial Write Str    Case    L
    END
    Serial Close Port    Case

*** Variables ***
${case_charge_relay_port}=    /dev/relay8

*** Test Cases ***
Charge Case
    FOR  ${counter}  IN RANGE    3
        Serial Write Str    Case    H
    END
    Sleep    2day
    