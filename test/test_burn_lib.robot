*** Settings ***
Documentation     Keywords(API) Test Cases for Burn Firmware
Library           ../lib/BurnLib.py

*** Test Cases ***
Burn Firmware
    [Documentation]     Burn firmware to hearing aids
    [Tags]              Firmware
    ${ret}=    Burn      programmer1600.bin  best1600_tws.bin
    Should Be True      ${ret} == 0
