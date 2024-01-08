*** Settings ***
Documentation     Test case for burning hearing aids l&r
Library           ../lib/BurnLib.py
Resource    ../resource/util.resource

*** Test Cases ***
Burn Orka Two
    [Documentation]     Burn firmware to hearing aids
    [Tags]              Firmware
    ${ret}=    Burn Orka     lr  programmer1600.bin  best1600_tws.bin    ota_boot_2700_20211216_5fca0c3e.bin
    Should Be True      ${ret} == 0

Start BT Advertising
    Sleep    3s
    Serial Open Right    /dev/ttyUSB3    9600
    Serial Write Hex    Right    010A00
    Serial Close Right