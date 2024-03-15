*** Settings ***
Documentation     Keywords(API) Test Cases for App control HA
Suite Setup       Setup
Suite Teardown    Teardown
Library           ../lib/AndroidTestLib.py
Library           ../lib/PreludeControlLib.py
Library           ../lib/SerialLib.py
Library           ../lib/BluetoothLib.py
Resource          ../resource/ha_utils.resource


***Variables***
${android_name}    R38M20B9D2R
${socket_port}    65432
${ha_addr}    0:0:0

${prelude_id}=    1
${bus_id}    1  
${dev_id}    1
${test_id}    1
${test_count}    1
${s_port_l}    /dev/ttyUSB2
${s_port_r}    /dev/ttyUSB3
${d_port_l}    /dev/ttyUSB4
${d_port_r}    /dev/ttyUSB5

${ble_address_l}    121233565681
${ble_address_r}    121233565681
${bt_address_l}    121233565680
${bt_address_r}    121233565681

${factory_mode}    0
@{aids_list}    Left    Right


*** Test Cases ***
Read General Status
    Log Soc
    Log Volt
    Log Mcu Freq    M55
    Log Mcu Freq    M33

Audio play a2dp
#wait wear on
    
    Log To Console      Normal and Bf_off
    Switch Beamforming  Off  
    Switch Mode         Normal
    Android A2dp Start       
    Sleep  10s
    Log Mcu Freq    M55
    Android A2dp Stop      

    Sleep  5s
    Log Mcu Freq    M55
    Log To Console      Normal and Bf_on
    Switch Beamforming  On
    Switch Mode         Normal
    Android A2dp Start      
    Sleep  10s 
    Log Mcu Freq    M55
    Android A2dp Stop     

    Sleep  5s 
    Log Mcu Freq    M55 
    Log To Console      Innoise and Bf_off
    Switch Beamforming  Off 
    Switch Mode         Innoise
    Android A2dp Start      
    Sleep  10s 
    Log Mcu Freq    M55
    Android A2dp Stop    
    
    Sleep  5s
    Log Mcu Freq    M55 
    Log To Console      Innoise and Bf_on
    Switch Beamforming  On
    Switch Mode         Innoise
    Android A2dp Start  

    Sleep  10s 
    Log Mcu Freq    M55
    Android A2dp Stop      
	
    Sleep  5s
    Log Mcu Freq     M55 


Audio play hfp 
    Log To Console      Normal and Bf_off
    Switch Beamforming  Off  
    Switch Mode         Normal
    Android Hfp Start
    Sleep  10s
    Log Mcu Freq    M55
    Android Hfp Stop

    Sleep  5s
    Log Mcu Freq    M55
    Log To Console      Normal and Bf_on
    Switch Beamforming  On
    Switch Mode         Normal
    Android Hfp Start
    Sleep  10s 
    Log Mcu Freq    M55
    Android Hfp Stop

    Sleep  5s 
    Log Mcu Freq    M55 
    Log To Console      Innoise and Bf_off
    Switch Beamforming  Off 
    Switch Mode         Innoise
    Android Hfp Start
    Sleep  10s 
    Log Mcu Freq    M55
    Android Hfp Stop

    Sleep  5s
    Log Mcu Freq    M55 
    Log To Console      Innoise and Bf_on
    Switch Beamforming  On
    Switch Mode         Innoise
    Android Hfp Start
    Sleep  10s 
    Log Mcu Freq    M55
    Android Hfp Stop
    Sleep  5s
    Log Mcu Freq     M55 

# repeat test
#     # FOR   ${i}    IN RANGE    1    ${test_count}
#         Read General Status
#         Audio play a2dp
#         Audio play hfp
#     # END



*** Keywords ***
Setup   
    Init Board    ${bus_id}    ${dev_id}    ${s_port_l}    ${s_port_r}    ${d_port_l}    ${d_port_r}    ${factory_mode} 
    # Check Init Soc
    Set Android Device    ${android_name}    ${socket_port}
    Start Server
    
    Log    "Wait Server stable..."
    Sleep    5s
    # Bluetooth Pair   ${ble_address_l}   ${ble_address_r}    ${bt_address_l}    ${bt_address_r} 
    Connect Bluetooth    ${ble_address_r}    ${bt_address_r} 
    Log    Test Start; id:${test_id}; count:${test_count}    console=True

Teardown
    Disconnect Bluetooth    ${ble_address_r}    
    Stop Android
    Deinit Board
    Log    Wait deinit...    console=True

    Sleep    60s
    Log    Quit successfully...    console=True    

Connect Bluetooth    
    [Arguments]    ${ble_address_r}    ${bt_address_r}
    ${tmp}=    Addr Insert Colon   ${ble_address_r}
    Set Suite Variable    ${ble_address_r}    ${tmp}


    Starton Device    
    Reset Device
    Send BoxOpen
    Send Heartbeat    10   

    # adv will make bt disconnect
    # Send Adv


    FOR    ${bt_counter}   IN RANGE  3
    Log To Console    Connect bredr for ${bt_counter}-th try
    Sleep    3s
    ${ret}=    Bt Connect Ha   ${ble_address_r}
    Log To Console    Connect bredr status: ${ret}
    Run Keyword If    ${ret} == True    Exit For Loop
    Sleep    3s
    END
    Should Be True    ${ret} == True
    
    FOR    ${ble_counter}   IN RANGE  3
    Log To Console    Connect le for ${ble_counter}-th try
   	${ret}=    Ble Connect Ha   ${ble_address_r}
    Log To Console    Connect le status: ${ret}
    Run Keyword If    ${ret} == True    Exit For Loop
    Sleep    3s
    END 
    Should Be True    ${ret} == True


Disconnect Bluetooth
    [Arguments]    ${ble_address_r}
    ${tmp}=    Addr Insert Colon   ${ble_address_r}
    Set Suite Variable    ${ble_address_r}    ${tmp}
    Ble Disconnect Ha    ${ble_address_r}   