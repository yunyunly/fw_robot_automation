*** Settings ***
Documentation     Keywords(API) Test Cases for App control HA
Suite Setup       Setup
Suite Teardown    Teardown
Library           ../lib/AndroidTestLib.py
Library           ../lib/PreludeControlLib.py
Library           ../lib/SerialLib.py
Library           ../lib/BluetoothLib.py


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

${ble_cmd_l}    00010906${ble_address_l} 
${ble_cmd_r}    00010906${ble_address_r} 
${bt_cmd_l}    00010706${bt_address_l} 
${bt_cmd_r}    00010706${bt_address_r} 

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
    Log    Setup    console=True 
    Log    ${test_count} ${bus_id} ${dev_id} ${s_port_l} ${s_port_r} ${d_port_l} ${d_port_r}    console=yes
    Log    ${ble_address_l} ${ble_address_l} ${bt_address_l} ${bt_address_l}    console=yes


    Run Keyword If    ${factory_mode}    Setup Prelude 
    Sleep    5s
    Set Android Device    ${android_name}    ${socket_port}
    Start Server

    ${tmp}=    Addr Insert Colon   ${ble_address_r}
    Set Suite Variable    ${ble_address_r}    ${tmp}

    Ble Connect Ha    ${ble_address_r}
    Sleep    5s

Setup Prelude 
    Open Device With Bus    ${bus_id}    ${dev_id}
    SerialSetUp

    Starton Device 
    Run Keyword If    ${factory_mode}    Check Factory Mode  
    Reset Device

    Send Heartbeat    4

    #send ble/bt to each other 
    Serial write hex        s_Left        ${bt_cmd_r}  
    Serial write hex        s_Right       ${bt_cmd_l} 

    Sleep    0.5s
    Serial write hex        s_Left        ${ble_cmd_r} 
    Serial write hex        s_Right       ${ble_cmd_l} 
    
    Sleep    0.5s
    Send Heartbeat    

    Sleep    10s

    Starton Device 
    Send Heartbeat    5


Teardown
    Log    Teardown    console=True
    Stop Android
    Run Keyword If    ${factory_mode}    Teardown Prelude  

Teardown Prelude 
    Shutdown Device
    SerialTearDown
    Close Ftdi

SerialSetUp
    Serial Open Hearing Aids 1152000
    Serial Open Hearing Aids 9600
    Check Init Soc 


Check Init Soc   
    Log To Console    Check Init Soc
    Starton Device
    Serial Parallel Read Until Regex    Left    soc: ([0-9]+)%    timeout=${10}
    Serial Parallel Read Until Regex    Right    soc: ([0-9]+)%    timeout=${10}
    
    Serial Parallel Read Start    ${aids_list} 
    Reset Device 
    ${soc}=  Serial Parallel Read Wait    ${aids_list}  

    Log To Console    Left soc = ${soc}[Left][0][0] ; Right soc = ${soc}[Right][0][0]
    Run Keyword If    ${soc}[Left][0][0] <10 or ${soc}[Right][0][0] <= 10    Charge Device

    Should Be True    ${soc}[Left][0][0] >= 10 and ${soc}[Left][0][0] <= 100
    Should Be True    ${soc}[Right][0][0] >= 10 and ${soc}[Right][0][0] <= 100

    Reset Device 

SerialTearDown
    Serial Close Hearing Aids 9600
    Serial Close Hearing Aids 1152000


Serial Open Hearing Aids 9600
    Serial Open Port    s_Left     ${s_port_l}    9600
    Serial Open Port    s_Right    ${s_port_r}    9600
    
Serial Open Hearing Aids 1152000
    Serial Open Port    Left     ${d_port_l}    1152000
    Serial Open Port    Right    ${d_port_r}    1152000

Serial Close Hearing Aids 9600
    Serial Close Port    s_Left
    Serial Close Port    s_Right

Serial Close Hearing Aids 1152000
    Serial Close Port    Left
    Serial Close Port    Right

Starton Device 
    Charge    Off    lr
    Sleep     0.5s
    Charge    On    lr
    Sleep     0.5s
    Charge    Off    lr
    Sleep    2s

    #check if open 
 #   Serial Parallel Read Until    Left      The Firmware rev is␊    timeout=${10}
 #   Serial Parallel Read Until    Right     The Firmware rev is␊    timeout=${10}

 #   ${ret}=  Serial Parallel Read Wait   Left Right 
 #   Log To Console      ${ret}
 #   Should Not Be Equal As Strings    ${ret}[Left]    [None]
 #   Should Not Be Equal As Strings    ${ret}[Right]   [None]

Reset Device 
    Log    Reset    console=True 
    PreludeControlLib.Reset     On    lr 
    Sleep     0.2s 
    PreludeControlLib.Reset     Off    lr
    Sleep    1s

Shutdown Device 
    Serial write hex    s_Left    010100
    Serial write hex    s_Right   010100
    Sleep     0.2s

    Serial write hex    s_Left    010100
    Serial write hex    s_Right   010100
    Sleep     0.2s

Send Heartbeat  
    [Arguments]    ${num}=3
    FOR    ${counter}   IN RANGE  ${num} 
        #send adv 
        Serial write hex        s_Left        01ff00
        Serial write hex        s_Right       01ff00
        Sleep    0.7s
    END


Send BoxOpen
    Serial write hex        s_Left        010200
    Serial write hex        s_Right       010200
    Sleep    0.2s 

Send BoxClose
    Serial write hex        s_Left        010300
    Serial write hex        s_Right       010300
    Sleep    0.2s 

Send Adv 
    FOR    ${counter}   IN RANGE  2
        #send adv 
        Serial write hex        s_Left        010a00
        Serial write hex        s_Right       010a00
        Sleep    0.2s
    END

Check Factory Mode 
    Log    Factory mode enable!!!    console=True
    Starton Device 

    Serial Parallel Read Until    Left    VERSO FACTORY MODE    timeout=${10}
    Serial Parallel Read Until    Right    VERSO FACTORY MODE    timeout=${10}

    Serial Parallel Read Until    Left    Start pmu shutdown    timeout=${10}
    Serial Parallel Read Until    Right    Start pmu shutdown    timeout=${10}
    
    Serial Parallel Read Start    ${aids_list}  
    Reset Device
    ${ret}=  Serial Parallel Read Wait    ${aids_list}  
    
    Log    Turn To Release Mode    console=True

    [Arguments]    ${num}=3
    FOR    ${counter}   IN RANGE  ${num} 
        Serial Write Str             s_Left      [to_rel,]
        Serial Write Str             s_Right     [to_rel,]
    
        Sleep   0.7s
    END

    Should Not Be Equal As Strings    ${ret}[Left][0]    None
    Should Not Be Equal As Strings    ${ret}[Right][0]    None

    Should Be Equal As Strings    ${ret}[Left][1]    None
    Should Be Equal As Strings    ${ret}[Right][1]    None