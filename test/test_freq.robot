*** Settings ***
Documentation     Keywords(API) Test Cases for App control HA

Suite Setup       Set Up
Suite Teardown    Tear Down

Library           ../lib/PreludeControlLib.py
Library           ../lib/HearingAidsLib.py 
Library           ../lib/AudioLib.py
Library           ../lib/SerialLib.py
Library            ../lib/BluetoothLib.py
Library           BuiltIn

*** Variables ***
${prelude_id}=    1
${s_port_l}    /dev/ttyUSB2
${s_port_r}    /dev/ttyUSB3
${d_port_l}    /dev/ttyUSB4
${d_port_r}    /dev/ttyUSB5

${ble_address_l}    121233565681
${ble_address_r}    121233565681
${bt_address_l}    121233565680
${bt_address_r}    121233565681

@{aids_list}    Left    Right

*** Test Cases ***
Connect Bluetooth
# Suite set up would cause error related to library __init__ and __del__. Thus placed in test case.
    Log To Console    test vars: ${prelude_id} ${s_port_l} ${s_port_r} ${d_port_l} ${d_port_r} ${ble_address_l} ${ble_address_r}
    #init prelude board
    Starton Device 
    Send Heartbeat
    Send BoxOpen
    Send Adv

    FOR    ${counter}   IN RANGE  3
    Log To Console    Connect bluetooth for ${counter}-th try
    ${ret}=    Connect Hearing Aids Classic    ${ble_address_r}
    Log To Console    Connect bredr status: ${ret}
    Continue For Loop If    ${ret} == False
    Sleep    5s
   	${ret}=    Connect Hearing Aids      ${ble_address_r}
    Log To Console    Connect le status: ${ret}
    Run Keyword If    ${ret} == True    Exit For Loop
    Sleep    3s
    END 

    Should Be True    ${ret} == True

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
Set Up
    ${tmp}=    Addr Insert Colon   ${ble_address_r}
    Set Suite Variable    ${ble_address_r}    ${tmp}
    Log To Console    Set Up
    Open Device    ${prelude_id}
    SerialSetUp


Tear Down
    Log To Console    Tear Down
    Disconnect Hearing Aids    ${ble_address_r}
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
    Sleep    1s

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
    FOR    ${counter}   IN RANGE  3
        #send adv 
        Serial write hex        s_Left        01ff00
        Serial write hex        s_Right       01ff00
        Sleep    0.2s
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
