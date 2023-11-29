*** Settings ***
Documentation     Keywords(API) Test Cases for Burning Firmware
Library           ../lib/BurnLib.py

*** Test Cases ***
Burn Orka
    [Documentation]     Burn firmware to hearing aids
    [Tags]              Firmware
    ${ret}=    Burn Orka     lr  programmer1600.bin  best1600_tws.bin    ota_boot_2700_20211216_5fca0c3e.bin
    Should Be True      ${ret} == 0

Burn Echo
    [Documentation]     Burn firmware to charging case
    [Tags]              Firmware
    ${ret}=    Burn Echo    CC-v2.0.9.0.hex     CC-OTA_bootloader.hex
    Should Be True      ${ret} == 0
