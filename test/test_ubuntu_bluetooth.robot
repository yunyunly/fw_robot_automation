*** Settings ***
Documentation     Keywords(API) Test Cases for App control HA

Suite Setup       Set Up
Test Setup        Test Set Up
Suite Teardown    Tear Down


Resource          ../resource/ha_utils.resource
Library           ../lib/PreludeControlLib.py
Library           ../lib/HearingAidsLib.py 
Library           ../lib/AudioLib.py
Library           ../lib/SerialLib.py
Library            ../lib/BluetoothLib.py
Library           BuiltIn

*** Variables ***
${prelude_id}=    1
${bus_id}    1  
${dev_id}    1
${test_id}    1
${s_port_l}    /dev/ttyUSB2
${s_port_r}    /dev/ttyUSB3
${d_port_l}    /dev/ttyUSB4
${d_port_r}    /dev/ttyUSB5
${factory_mode}    0

${ble_address_l}    121233565681
${ble_address_r}    121233565681
${bt_address_l}    121233565680
${bt_address_r}    121233565681

${ble_cmd_l}    00010906${ble_address_l} 
${ble_cmd_r}    00010906${ble_address_r} 
${bt_cmd_l}    00010706${bt_address_l} 
${bt_cmd_r}    00010706${bt_address_r} 
@{aids_list}    Left    Right

*** Test Cases ***
Read General Status
    Log Soc
    Log Volt
    Log Mcu Freq    M55 
    Log Mcu Freq    M33

Audio play a2dp
    ${id}=    Audio Get Dev Id
    	Should Be True    ${id} > 0
    Log To Console      Normal and Bf_off
    Switch Beamforming  Off  
    Switch Mode         Normal
    ${process_id}=   Audio Start Play Audio      ~/audio/Big_band.wav
	Should Be True    ${process_id} > 0
    Sleep  5s
    Log Mcu Freq    M55
    ${ret}=   Audio Stop Play Audio  ${process_id}
	Should Be True    ${ret} == True
    Sleep  5s
    Log Mcu Freq    M55
    Log To Console      Normal and Bf_on
    Switch Beamforming  On
    Switch Mode         Normal
    ${process_id}=   Audio Start Play Audio      ~/audio/Big_band.wav
	Should Be True    ${process_id} > 0
    Sleep  5s 
    Log Mcu Freq    M55
    ${ret}=   Audio Stop Play Audio  ${process_id}
	Should Be True    ${ret} == True
    Sleep  5s 
    Log Mcu Freq    M55 
    Log To Console      Innoise and Bf_off
    Switch Beamforming  Off 
    Switch Mode         Innoise
    ${process_id}=   Audio Start Play Audio      ~/audio/Big_band.wav
	Should Be True    ${process_id} > 0
    Sleep  5s 
    Log Mcu Freq    M55
    ${ret}=   Audio Stop Play Audio  ${process_id}
	Should Be True    ${ret} == True
    Sleep  5s
    Log Mcu Freq    M55 
    Log To Console      Innoise and Bf_on
    Switch Beamforming  On
    Switch Mode         Innoise
    ${process_id}=   Audio Start Play Audio      ~/audio/Big_band.wav
	Should Be True    ${process_id} > 0
    Sleep  5s 
    Log Mcu Freq    M55
    ${ret}=   Audio Stop Play Audio  ${process_id}
	Should Be True    ${ret} == True
    Sleep  5s
    Log Mcu Freq     M55 


Audio play hfp 
    ${id}=    Audio Get Dev Id
    Log To Console      Normal and Bf_off
    Switch Beamforming  Off  
    Switch Mode         Normal
    ${process_id}=   Audio Start Play Hfp        ~/audio/Big_band.wav
	Should Be True    ${process_id} > 0
    Sleep  5s
    Log Mcu Freq    M55
    ${ret}=   Audio Stop Play Audio  ${process_id}
	Should Be True    ${ret} == True
    Sleep  5s
    Log Mcu Freq    M55
    Log To Console      Normal and Bf_on
    Switch Beamforming  On
    Switch Mode         Normal
    ${process_id}=   Audio Start Play Hfp        ~/audio/Big_band.wav
	Should Be True    ${process_id} > 0
    Sleep  5s 
    Log Mcu Freq    M55
    ${ret}=   Audio Stop Play Audio  ${process_id}
	Should Be True    ${ret} == True
    Sleep  5s 
    Log Mcu Freq    M55 
    Log To Console      Innoise and Bf_off
    Switch Beamforming  Off 
    Switch Mode         Innoise
    ${process_id}=   Audio Start Play Hfp      ~/audio/Big_band.wav
	Should Be True    ${process_id} > 0
    Sleep  5s 
    Log Mcu Freq    M55
    ${ret}=   Audio Stop Play Audio  ${process_id}
	Should Be True    ${ret} == True
    Sleep  5s
    Log Mcu Freq    M55 
    Log To Console      Innoise and Bf_on
    Switch Beamforming  On
    Switch Mode         Innoise
    ${process_id}=   Audio Start Play Hfp      ~/audio/Big_band.wav
	Should Be True    ${process_id} > 0
    Sleep  5s 
    Log Mcu Freq    M55
    ${ret}=   Audio Stop Play Audio  ${process_id}
	Should Be True    ${ret} == True
    Sleep  5s
    Log Mcu Freq     M55 

*** Keywords ***
Test Set Up
    Log    test_id:${test_id}    console=True

Set Up
    Init Board    ${bus_id}    ${dev_id}    ${s_port_l}    ${s_port_r}    ${d_port_l}    ${d_port_r}    ${factory_mode}
    ${tmp}=    Addr Insert Colon   ${ble_address_r}
    Set Suite Variable    ${ble_address_r}    ${tmp}
    Log To Console    Set Up

    Init
    Check Init Soc
    Connect Bluetooth


Tear Down
    Log To Console    Tear Down
    Disconnect Hearing Aids    ${ble_address_r}
    Quit   
    Deinit Board  
    Sleep    5s


Connect Bluetooth
# Suite set up would cause error related to library __init__ and __del__. Thus placed in test case.
    Log    bluetooth vars: ${ble_address_l} ${ble_address_r}    console=True
    Starton Device 

    Reset Device

    Send Heartbeat
    #send ble/bt to each other 
    Serial write hex        s_Left        ${ble_cmd_r} 
    Serial write hex        s_Left        ${bt_cmd_r}  

    Serial write hex        s_Right       ${ble_cmd_l} 
    Serial write hex        s_Right       ${bt_cmd_l} 

    Sleep    10s

    Starton Device 
    Send Heartbeat    5

    Sleep    3s

    Send Heartbeat
    Send BoxOpen

    FOR    ${bt_counter}   IN RANGE  3
    Log To Console    Connect bredr for ${bt_counter}-th try
    # Send Adv
    Sleep    3s
    ${ret}=    Connect Hearing Aids Classic    ${ble_address_r}
    Log To Console    Connect bredr status: ${ret}
    Run Keyword If    ${ret} == True    Exit For Loop
    Sleep    3s
    END
    Should Be True    ${ret} == True
    
    FOR    ${ble_counter}   IN RANGE  3
    Log To Console    Connect le for ${ble_counter}-th try
   	${ret}=    Connect Hearing Aids      ${ble_address_r}
    Log To Console    Connect le status: ${ret}
    Run Keyword If    ${ret} == True    Exit For Loop
    Sleep    3s
    END 
    Should Be True    ${ret} == True
