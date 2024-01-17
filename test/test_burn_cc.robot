*** Settings ***
Documentation     Burn charging case
Library           ../lib/BurnLib.py

*** Variables ***
${bin}=    CC-v2.0.9.0.hex
${ota}=    CC-OtaBootloader_1.1.hex

*** Test Cases ***
Burn Echo
    [Documentation]     Burn firmware to charging case
    [Tags]              Firmware
    ${ret}=    Burn Echo    ${bin}     ${ota}
    Should Be True      ${ret} == 0
