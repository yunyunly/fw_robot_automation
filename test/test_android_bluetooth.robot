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
${android_name}    RF8N103W59D
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
    Log To Console      Normal and Bf_off
    Switch Beamforming  Off  
    Switch Mode         Normal
    Android A2dp Start       
    Sleep  5s
    Log Mcu Freq    M55
    Android A2dp Stop      

    Sleep  5s
    Log Mcu Freq    M55
    Log To Console      Normal and Bf_on
    Switch Beamforming  On
    Switch Mode         Normal
    Android A2dp Start      
    Sleep  5s 
    Log Mcu Freq    M55
    Android A2dp Stop     

    Sleep  5s 
    Log Mcu Freq    M55 
    Log To Console      Innoise and Bf_off
    Switch Beamforming  Off 
    Switch Mode         Innoise
    Android A2dp Start      
    Sleep  5s 
    Log Mcu Freq    M55
    Android A2dp Stop    
    
    Sleep  5s
    Log Mcu Freq    M55 
    Log To Console      Innoise and Bf_on
    Switch Beamforming  On
    Switch Mode         Innoise
    Android A2dp Start  

    Sleep  5s 
    Log Mcu Freq    M55
    Android A2dp Stop      
	
    Sleep  5s
    Log Mcu Freq     M55 


Audio play hfp 
    Log To Console      Normal and Bf_off
    Switch Beamforming  Off  
    Switch Mode         Normal
    Android Hfp Start
    Sleep  5s
    Log Mcu Freq    M55
    Android Hfp Stop

    Sleep  5s
    Log Mcu Freq    M55
    Log To Console      Normal and Bf_on
    Switch Beamforming  On
    Switch Mode         Normal
    Android Hfp Start
    Sleep  5s 
    Log Mcu Freq    M55
    Android Hfp Stop

    Sleep  5s 
    Log Mcu Freq    M55 
    Log To Console      Innoise and Bf_off
    Switch Beamforming  Off 
    Switch Mode         Innoise
    Android Hfp Start
    Sleep  5s 
    Log Mcu Freq    M55
    Android Hfp Stop

    Sleep  5s
    Log Mcu Freq    M55 
    Log To Console      Innoise and Bf_on
    Switch Beamforming  On
    Switch Mode         Innoise
    Android Hfp Start
    Sleep  5s 
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
    Set Android Device    ${android_name}    ${socket_port}
    Start Server
    Bluetooth Pair   ${ble_address_l}   ${ble_address_r}    ${bt_address_l}    ${bt_address_r} 
    Connect Bluetooth    ${ble_address_l} 

Teardown
    Stop Android
    Deinit Board
