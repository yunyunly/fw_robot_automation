*** Settings ***
Documentation     Test case for burning hearing aids l&r
Library           ../lib/BurnLib.py

*** Variables ***
${port_l}    /dev/ttyUSB4
${port_r}    /dev/ttyUSB5
${factory_mode}    False

*** Test Cases ***
Burn Orka Two
    [Documentation]     Burn firmware to hearing aids
    [Tags]              Firmware
    Update Ha Port      ${port_l}    ${port_r}
    ${ret}=    Burn Orka     1    ${factory_mode}    lr    programmer1600.bin  best1600_tws.bin    ota_boot_2700_20211216_5fca0c3e.bin
    Should Be True      ${ret} == 0