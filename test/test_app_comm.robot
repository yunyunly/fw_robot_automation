*** Settings ***
Documentation     Keywords(API) Test Cases for App control HA
Suite Setup       Connect Hearing Aids   12:12:33:56:56:81
Suite Teardown    Disconnect Hearing Aids   12:12:33:56:56:81
Test Setup        Serial Connnect LR
Test Teardown     Serial Disconnect LR
Library           ../lib/HearingAidsLib.py
Library           ../lib/SerialLib.py
Library    OperatingSystem
Resource    ../resource/util.resource

*** Keywords ***
serial connnect lr
    Serial Open Left    /dev/ttyUSB2    1152000
    Serial Open Right    /dev/ttyUSB3    1152000

serial disconnect lr
    Serial Close Port    Left
    Serial Close Port    Right

*** Test Cases ***

ha check soc
    log_soc
    ${matched_left}=    Serial Read Until Regex    Left    (.*Log: soc.*)    timeout=20
    Log    message=log mateched: +${matched_left}    console=True
    Should Not Be Empty    ${matched_left}