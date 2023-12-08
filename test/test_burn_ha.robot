*** Settings ***
Documentation     Test case for burning hearing aids l&r
Library           ../lib/BurnLib.py

*** Test Cases ***
Burn Orka Two
    [Documentation]     Burn firmware to hearing aids
    [Tags]              Firmware
    ${ret}=    Burn Orka     lr  programmer1600.bin  best1600_tws.bin    ota_boot_2700_20211216_5fca0c3e.bin
    Should Be True      ${ret} == 0