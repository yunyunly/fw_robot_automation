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
${prelude_id}    1
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
    Open Device    ${prelude_id}
    Log To Console    port_l:${port_l}
    Log To Console    port_r:${port_r}
    Log To Console    factory_mode:${factory_mode}

    Log To Console    ble_address_l:${ble_address_l}
    Log To Console    ble_address_r:${ble_address_r}
    Log To Console    bt_address_l:${bt_address_l}
    Log To Console    bt_address_r:${bt_address_r}

    Check Init Soc  

    Run Keyword If    ${factory_mode}    Check Factory Mode

    FOR    ${index}   IN RANGE  ${test_count}  
        Log To Console      The ${index}-th run 
        Check Release And Version
        Check Charge And Shutdown
        Check Heartbeat And Shutdown
        Check Bluetooth Pairing
        Check Box Status
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


Check Init Soc   
    Log To Console    Check Init Soc
    Serial Open Hearing Aids 1152000
    Starton Device
    Serial Parallel Read Until Regex    Left    soc: ([0-9]+)%    timeout=${10}
    Serial Parallel Read Until Regex    Right    soc: ([0-9]+)%    timeout=${10}
    Serial Parallel Read Start    ${aids_list} 

    Reset Device 
     
    ${soc}=  Serial Parallel Read Wait    ${aids_list}  

    Should Be True    ${soc}[Left][0][0] >= 10 and ${soc}[Left][0][0] <= 100
    Should Be True    ${soc}[Right][0][0] >= 10 and ${soc}[Right][0][0] <= 100

    Log To Console    Left soc = ${soc}[Left][0][0] ; Right soc = ${soc}[Right][0][0]
    Reset Device 

Check Release And Version
    Log To Console    Check Release And Version
    Serial Open Hearing Aids 1152000
    Starton Device
    Reset Device 

    Serial Parallel Read Until    Left    init success    timeout=${5}
    Serial Parallel Read Until    Left    VERSO RELEASE MODE    timeout=${5}
    Serial Parallel Read Until    Left    shutdown reason: echo not active    timeout=${10}

    Serial Parallel Read Until    Right    init success    timeout=${5}
    Serial Parallel Read Until    Right    VERSO RELEASE MODE    timeout=${5}
    Serial Parallel Read Until    Right    shutdown reason: echo not active    timeout=${10}
    
    Serial Parallel Read Start    ${aids_list}  
    ${ret}=  Serial Parallel Read Wait    ${aids_list}  

    Should Not Be Equal As Strings    ${ret}[Left][0]    None
    Should Not Be Equal As Strings    ${ret}[Left][1]    None
    Should Not Be Equal As Strings    ${ret}[Left][2]    None

    Should Not Be Equal As Strings    ${ret}[Right][0]    None
    Should Not Be Equal As Strings    ${ret}[Right][1]    None
    Should Not Be Equal As Strings    ${ret}[Right][2]    None
    
    #Already shutdown
    Sleep     3s

Check Heartbeat And Shutdown
    Log To Console    Check Heartbeat And Shutdown
    Starton Device 
    Reset Device 

    Send Heartbeat

    Serial Open Hearing Aids 1152000
    Serial Parallel Read Until  Left    shutdown reason: echo not active    timeout=${10}
    Serial Parallel Read Until  Right   shutdown reason: echo not active    timeout=${10}

    Serial Parallel Read Start    ${aids_list}
    ${ret}=  Serial Parallel Read Wait   ${aids_list}
    Should Be Equal As Strings    ${ret}[Left][0]    None
    Should Be Equal As Strings    ${ret}[Right][0]    None

    #shutdown by cmd
    Shutdown Device 
    Serial Open Hearing Aids 1152000
    Serial Parallel Read Until  Left    Start pmu shutdown  timeout=${5}
    Serial Parallel Read Until  Right   Start pmu shutdown  timeout=${5}

    Serial Parallel Read Start    ${aids_list}
    ${ret}=  Serial Parallel Read Wait   ${aids_list}

    Should Not Be Equal As Strings    ${ret}[Left][0]    None
    Should Not Be Equal As Strings    ${ret}[Right][0]    None
    Sleep     3s

Check Charge And Shutdown
    Log To Console    Check Charge And Shutdown
    Charge Device
    Reset Device    

    Send Heartbeat

    Serial Open Hearing Aids 1152000
    Serial Parallel Read Until  Left    STILL CHARING, SHUTDOWN    timeout=${10}
    Serial Parallel Read Until  Right   STILL CHARING, SHUTDOWN    timeout=${10}

    Serial Parallel Read Start    ${aids_list}
    ${ret}=  Serial Parallel Read Wait   ${aids_list}
    Should Not Be Equal As Strings    ${ret}[Left][0]    None
    Should Not Be Equal As Strings    ${ret}[Right][0]    None


Check Bluetooth Pairing 
    Log To Console    Check Bluetooth Pairing 
    Starton Device 
    Reset Device 
    
    Send Heartbeat
    
    #send ble/bt to each other 
    Serial write hex        Left        ${ble_cmd_r} 
    Serial write hex        Left        ${bt_cmd_r} 

    Serial write hex        Right       ${ble_cmd_l} 
    Serial write hex        Right       ${bt_cmd_l} 

    Sleep    5s

    Starton Device
    Send Heartbeat
    
    FOR    ${counter}   IN RANGE  2
        Sleep    0.2s
        #send adv 
        Serial write hex        Left        010a00
        Serial write hex        Right       010a00
    END
    

    Serial Open Hearing Aids 1152000
    Serial Parallel Read Until  Left    Access mode changed to 3    timeout=${10}
    Serial Parallel Read Until  Right   Access mode changed to 3    timeout=${10}

    Serial Parallel Read Start    ${aids_list}
    ${ret}=  Serial Parallel Read Wait   ${aids_list}
    # TODO: only master will print this log 
    # Should Not Be Equal As Strings    ${ret}[Left][0]   None
    Should Not Be Equal As Strings    ${ret}[Right][0]   None
    # Should Be True    '${ret}[Left][0]'=='None' or '${ret}[Right][0]'=='None'
    Shutdown Device 
    Sleep     3s

Check Box Status
    Log To Console    Check Box Status
    Shutdown Device 
    Starton Device 
    Reset Device 
    
    Send BoxOpen
    Send Heartbeat

    Serial Open Hearing Aids 1152000
    Serial Parallel Read Until  Left    ori box state = IN_BOX_CLOSED,new = IN_BOX_OPEN    timeout=${5}
    Serial Parallel Read Until  Right    ori box state = IN_BOX_CLOSED,new = IN_BOX_OPEN    timeout=${5}
    Serial Parallel Read Until  Left    ori box state = IN_BOX_OPEN,new = OUT_BOX    timeout=${5}
    Serial Parallel Read Until  Right    ori box state = IN_BOX_OPEN,new = OUT_BOX    timeout=${5}
    Serial Parallel Read Until  Left    custom_ui:case open run complete    timeout=${20}
    Serial Parallel Read Until  Right    custom_ui:case open run complete    timeout=${20}
    Serial Parallel Read Until  Left    app_advertising_started   timeout=${10}
    Serial Parallel Read Until  Right    app_advertising_started   timeout=${10}

    Serial Parallel Read Start    ${aids_list}
    ${ret}=  Serial Parallel Read Wait   ${aids_list}


    Should Not Be Equal As Strings    ${ret}[Left][0]    None
    Should Not Be Equal As Strings    ${ret}[Right][0]    None
    Should Not Be Equal As Strings    ${ret}[Left][1]    None
    Should Not Be Equal As Strings    ${ret}[Right][1]    None
    Should Not Be Equal As Strings    ${ret}[Left][2]    None
    Should Not Be Equal As Strings    ${ret}[Right][2]    None
    
    # TODO: only master will print this log 
    # Should Be True    ${ret}[Left][3]!=None or ${ret}[Right][3]!=None
    # Should Not Be Equal As Strings    ${ret}[Left][3]    None
    Should Not Be Equal As Strings    ${ret}[Right][3]    None
    
    Sleep    5s
    Send Heartbeat
    Send BoxClose

    Serial Open Hearing Aids 1152000
    # Serial Parallel Read Until  Left    ori box state = OUT_BOX,new = IN_BOX_OPEN    timeout=${5}
    # Serial Parallel Read Until  Right   ori box state = OUT_BOX,new = IN_BOX_OPEN    timeout=${5}
    Serial Parallel Read Until  Left    IN_BOX_CLOSED    timeout=${5}
    Serial Parallel Read Until  Right   IN_BOX_CLOSED    timeout=${5}
    Serial Parallel Read Start    ${aids_list}
    ${ret}=  Serial Parallel Read Wait   ${aids_list}
    Should Not Be Equal As Strings    ${ret}[Left][0]    None
    Should Not Be Equal As Strings    ${ret}[Right][0]    None
    # Should Not Be Equal As Strings    ${ret}[Left][1]    None
    # Should Not Be Equal As Strings    ${ret}[Right][1]    None
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
    Sleep     0.5s

Charge Device
    Charge    Off    lr
    Sleep     0.5s
    Charge    On    lr
    Sleep     1s

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
    Sleep    1s

Shutdown Device 
    Serial Open Hearing Aids 9600
    Serial write hex    Left    010100
    Serial write hex    Right   010100
    Sleep     0.2s

    Serial write hex    Left    010100
    Serial write hex    Right   010100
    Sleep     0.2s

Send Heartbeat
    Serial Open Hearing Aids 9600
    Serial write hex        Left        01ff00
    Serial write hex        Right       01ff00
    Sleep    0.2s 
    Serial write hex        Left        01ff00
    Serial write hex        Right       01ff00
    Sleep    0.2s 

Send BoxOpen
    Serial Open Hearing Aids 9600
    Serial write hex        Left        010200
    Serial write hex        Right       010200
    Sleep    0.2s 

Send BoxClose
    Serial Open Hearing Aids 9600
    Serial write hex        Left        010300
    Serial write hex        Right       010300
    Sleep    0.2s 

    

    
