*** Settings ***
Documentation     Keywords(API) Test Cases for Burn Firmware
Library           ../lib/BurnLib.py

*** Test Cases ***
Burn Firmware
    [Documentation]     Burn firmware to hearing aids
    [Tags]              Firmware
    ${ret}=    Burn     lr  programmer1600.bin  best1600_tws.bin    ota_boot_2700_20211216_5fca0c3e.bin
    Should Be True      ${ret} == 0