*** Settings ***
Documentation     Keywords(API) Test Cases for App control HA
# Suite Setup       Connect Hearing Aids   D2:04:56:78:9A:01
# Suite Teardown    Disconnect Hearing Aids
Test Setup        Serial Open Hearing Aids 9600
Test Teardown     Serial Close Hearing Aids 
#Library           ../lib/HearingAidLib.py
Library           ../lib/SerialLib.py
Library           ../lib/PreludeControlLib.py
Library           BuiltIn

*** Variables ***
@{aids_list}    Left    Right
${test_count}    1
${port_l}    /dev/ttyUSB4
${port_r}    /dev/ttyUSB5
${factory_mode}    True

${ble_address_l}    121233565681
${ble_address_r}    121233565681
${bt_address_l}    121233565680
${bt_address_r}    121233565681

${ble_cmd_l}    00010906${ble_address_l} 
${ble_cmd_r}    00010906${ble_address_r} 
${bt_cmd_l}    00010706${bt_address_l} 
${bt_cmd_r}    00010706${bt_address_r} 

*** Test Cases ***
Run Basic Tests Multiple Times
    Open Device    1
    Log To Console    port_l:${port_l}
    Log To Console    port_r:${port_r}
    Log To Console    factory_mode:${factory_mode}

    Log To Console    ble_address_l:${ble_address_l}
    Log To Console    ble_address_r:${ble_address_r}
    Log To Console    bt_address_l:${bt_address_l}
    Log To Console    bt_address_r:${bt_address_r}

    Run Keyword If    ${factory_mode}    Check Factory Mode

    FOR    ${index}   IN RANGE  ${test_count}  
        Log To Console      The ${index}-th run 
        Check Release And Version
        Check Heartbeat And Shutdown
        Check Bluetooth Pairing 
    END

*** Keywords ***
Check Factory Mode
    Log To Console    Check Factory Mode    
    Serial Open Hearing Aids 1152000
    Starton Device 
    Reset Device

    Serial Parallel Read Until    Left    VERSO FACTORY MODE    timeout=${10}
    Serial Parallel Read Until    Right    VERSO FACTORY MODE    timeout=${10}

    Serial Parallel Read Until    Left    Start pmu shutdown    timeout=${10}
    Serial Parallel Read Until    Right    Start pmu shutdown    timeout=${10}
    
    Serial Parallel Read Start    ${aids_list}  
    ${ret}=  Serial Parallel Read Wait    ${aids_list}  

    Should Not Be Equal As Strings    ${ret}[Left][0]    None
    Should Not Be Equal As Strings    ${ret}[Right][0]    None

    Should Be Equal As Strings    ${ret}[Left][1]    None
    Should Be Equal As Strings    ${ret}[Right][1]    None
    
    Log To Console    Turn To Release Mode
    Serial Open Hearing Aids 9600
    Serial Write Str             Left      [to_rel,]
    Serial Write Str             Right     [to_rel,]
    
    Sleep   0.2s

    Serial Write Str             Left      [to_rel,]
    Serial Write Str             Right     [to_rel,]


Check Release And Version
    Log To Console    Check Release And Version
    Serial Open Hearing Aids 1152000
    Starton Device
    Reset Device 

    Serial Parallel Read Until    Left     init success    timeout=${5}
    Serial Parallel Read Until    Left     VERSO RELEASE MODE    timeout=${10}

    Serial Parallel Read Until    Right    init success    timeout=${5}
    Serial Parallel Read Until    Right    VERSO RELEASE MODE    timeout=${10}
    
    Serial Parallel Read Start    ${aids_list}  
    ${ret}=  Serial Parallel Read Wait    ${aids_list}  

    Should Not Be Equal As Strings    ${ret}[Left][0]    None
    Should Not Be Equal As Strings    ${ret}[Left][1]    None

    Should Not Be Equal As Strings    ${ret}[Right][0]    None
    Should Not Be Equal As Strings    ${ret}[Right][1]    None

    Shutdown Device 
    Sleep     3s

Check Heartbeat And Shutdown
    Log To Console    Check Heartbeat And Shutdown
    Starton Device 

    Send Heartbeat

    Serial Open Hearing Aids 1152000
    Serial Parallel Read Until  Left    shutdown reason: echo not active    timeout=${10}
    Serial Parallel Read Until  Right   shutdown reason: echo not active    timeout=${10}

    Serial Parallel Read Start    ${aids_list}
    ${ret}=  Serial Parallel Read Wait   ${aids_list}
    Should Be Equal As Strings    ${ret}[Left]    [None]
    Should Be Equal As Strings    ${ret}[Right]   [None]

    #shutdown by cmd
    Shutdown Device 
    Serial Open Hearing Aids 1152000
    Serial Parallel Read Until  Left    Start pmu shutdown  timeout=${5}
    Serial Parallel Read Until  Right   Start pmu shutdown  timeout=${5}

    Serial Parallel Read Start    ${aids_list}
    ${ret}=  Serial Parallel Read Wait   ${aids_list}

    Should Not Be Equal As Strings    ${ret}[Left]    [None]
    Should Not Be Equal As Strings    ${ret}[Right]   [None]
    Sleep     3s

Check Bluetooth Pairing 
    Log To Console    Check Bluetooth Pairing 
    Starton Device 

    Send Heartbeat
    
    #send ble/bt to each other 
    Serial write hex        Left        ${ble_cmd_r} 
    Serial write hex        Left        ${bt_cmd_r} 

    Serial write hex        Right       ${ble_cmd_l} 
    Serial write hex        Right       ${bt_cmd_l} 

    Sleep    5s

    Starton Device
    FOR    ${counter}   IN RANGE  5
        Send Heartbeat
        Sleep    0.2s

        #send adv 
        Serial write hex        Left        00010a00
        Serial write hex        Right       00010a00
    END
    

    Serial Open Hearing Aids 1152000
    Serial Parallel Read Until  Left    Access mode changed to 3    timeout=${10}
    Serial Parallel Read Until  Right   Access mode changed to 3    timeout=${10}

    Serial Parallel Read Start    ${aids_list}

    ${ret}=  Serial Parallel Read Wait   ${aids_list}

    ${final}    Set Variable    ${ret}[Right]
    #Set Variable If    '${ret}[Left]'!='[None]'    ${final}    ${ret}[Left]
    #Set Variable If    '${ret}[Right]'!='[None]'    ${final}    ${ret}[Right]
    #Log To Console    ${final}

    Should Not Be Equal As Strings    ${final}   [None]
    
    Shutdown Device 
    Sleep     3s
     
Serial Open Hearing Aids 9600
    Serial Open Port    Left     ${port_l}    9600
    Serial Open Port    Right    ${port_r}    9600
    
Serial Open Hearing Aids 1152000
    Serial Open Port    Left     ${port_l}    1152000
    Serial Open Port    Right    ${port_r}    1152000

Serial Close Hearing Aids 
    Serial Close Port    Left
    Serial Close Port    Right
    Close Ftdi

Starton Device 
    Charge    Off    lr
    Sleep     0.5s
    Charge    On    lr
    Sleep     0.5s
    Charge    Off    lr

    #check if open 
 #   Serial Parallel Read Until    Left      The Firmware rev is␊    timeout=${10}
 #   Serial Parallel Read Until    Right     The Firmware rev is␊    timeout=${10}

 #   ${ret}=  Serial Parallel Read Wait   Left Right 
 #   Log To Console      ${ret}
 #   Should Not Be Equal As Strings    ${ret}[Left]    [None]
 #   Should Not Be Equal As Strings    ${ret}[Right]   [None]

Reset Device 
    Log    Reset    console=True 
    Reset     On    lr 
    Sleep     0.2s 
    Reset     Off    lr

Shutdown Device 
    Serial Open Hearing Aids 9600
    Serial write hex    Left    00010100
    Serial write hex    Right   00010100
    Sleep     0.2s

    Serial write hex    Left    00010100
    Serial write hex    Right   00010100

Send Heartbeat
    Serial Open Hearing Aids 9600
    Serial write hex        Left        0001ff00
    Serial write hex        Right       0001ff00
    Sleep    0.2s 
    Serial write hex        Left        0001ff00
    Serial write hex        Right       0001ff00
    Sleep    0.7s 
    Serial write hex        Left        0001ff00
    Serial write hex        Right       0001ff00
    Sleep    0.7s 
    Serial write hex        Left        0001ff00
    Serial write hex        Right       0001ff00
    Sleep    0.7s 
    Serial write hex        Left        0001ff00
    Serial write hex        Right       0001ff00
    
    

    
