*** Settings ***
Documentation     Keywords(API) Test Cases for App control HA
Suite Setup       Setup
Suite Teardown    Teardown
Library           ../lib/AndroidTestLib.py


***Variables***
# device name of android phone, could be found by running 'adb devices'
${android_name}    LMQ620VA18853978
# port number for socket communication, do not use same port for multiple devices
${socket_port}    65444
# Bluetooth address of HA
${ha_addr}    12:12:12:12:12:11

*** Keywords ***
Setup
    Set Android Device    ${android_name}    ${socket_port}
    Start Server
    Ble Connect Ha    ${ha_addr}
    Sleep    5s

Teardown
    Stop Android
    Log To Console    Teardown

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

*** Test Cases ***
repeat test
    FOR   ${i}    IN RANGE    1    10000
        Read General Status
        Audio play a2dp
        Audio play hfp
    END