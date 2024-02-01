*** Settings ***
Documentation     Test case for burning hearing aids l&r
Library           ../lib/BurnLib.py
Library           ../lib/SerialLib.py

*** Variables ***
${port_l}    /dev/ttyUSB2
${port_r}    /dev/ttyUSB3
${d_port_l}    /dev/ttyUSB4
${d_port_r}    /dev/ttyUSB5
${prelude_id}    -1

${bus_id}    1
${dev_id}    1

${factory_file_l}    left.bin
${factory_file_r}    right.bin

${ota_bin}    ota_boot_2700_20211216_5fca0c3e.bin
${program_bin}    programmer1600.bin
${bes_bin}    best1600_tws.bin
${version}    2.0.13


*** keywords ***
Burn Orka Two With Prelude ID
    [Documentation]     Burn firmware to hearing aids
    [Tags]              Firmware
    Update Ha Port      ${port_l}    ${port_r}
    ${ret}=    Burn Orka     1    lr    programmer1600.bin  best1600_tws.bin    ota_boot_2700_20211216_5fca0c3e.bin
    Should Be True      ${ret} == 0


Burn Orka Two With Bus And Device 
    [Documentation]     Burn firmware to hearing aids
    [Tags]              Firmware

    Log To Console    s_port_l:${port_l}
    Log To Console    s_port_r:${port_r}
    Log To Console    d_port_l:${d_port_l}
    Log To Console    d_port_r:${d_port_r}
    Log To Console    program_bin:${program_bin}
    Log To Console    bes_bin:${bes_bin}
    Log To Console    ota_bin:${ota_bin}
    Log To Console    factory_file_l:${factory_file_l}
    Log To Console    factory_file_r:${factory_file_r}
    Log To Console    bus_id:${bus_id}
    Log To Console    device_id:${dev_id}

    Update Ha Port      ${port_l}    ${port_r}
    ${ret}=    Burn Orka With Bus    ${bus_id}    ${dev_id}    l    ${program_bin}    ${bes_bin}     ${ota_bin}    erase_chip    ${factory_file_l}
    ${ret}=    Burn Orka With Bus    ${bus_id}    ${dev_id}    r    ${program_bin}    ${bes_bin}     ${ota_bin}    erase_chip    ${factory_file_r}
    Should Be True      ${ret} == 0
    #Check BT and BLE address 


    #Check Version

*** Test Cases ***
Burn Orka Two
    IF  ${prelude_id}==-1
        Log To Console    start burn ha with bus and device
        Burn Orka Two With Bus And Device
    ELSE
        Log To Console    start burn ha with prelude id
        Burn Orka Two With Prelude ID
    END
    