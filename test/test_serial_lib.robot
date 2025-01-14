*** Setting ***
Documentation     Test cases for testing serial library
...
...               All keywords constructed from ``SerialLib.py``.
Suite Setup       Serial Open All
Suite Teardown    Serial Close All
Test Setup
Test Teardown
Default Tags      Serial
Library           ../lib/SerialLib.py

*** Test Cases ***
Serial read until string
        ${line} =    Serial Read Until    Case    heartbeat
        ${line} =    Serial Read Until    Left    watchdog
        Log    ${line}

Serial read until regex match string
        ${ret}=    Serial Read Until Regex    Case    heart(.)
        Should Be Equal    ${ret}[0]    b
        ${ret}=    Serial Read Until Regex    Left    feed (.)
        Should Be Equal    ${ret}[0]    w

Serial read until regex match int
        ${ret}=    Serial Read Until Regex    Case    send event ([0-9]+)
        Should Be Equal    ${ret}[0]    255
        ${ret}=    Serial Read Until Regex    Left    running mode: (.)
        Should Be Equal    ${ret}[0]    0

Serial read until regex match float
        ${ret}=    Serial Read Until Regex    Case    new curr: ([+-]?[0-9]+\\.[0-9]+)
        Should Be True    ${ret}[0] < 32

Serial write string
        Serial Write Str    Case    abcdefg

Serial write hex
        Serial Write Hex    Case    ff00

Serial read parallel
        Serial Parallel Read Until    Case    heartbeat
        Serial Parallel Read Until    Left    watchdog
    ${ret}=    Serial Parallel Wait    [Case, Left]
    Log    ${ret}

Serial read parallel regex
    ${ret}=    Serial Parallel Read Until Regex    Case    heart(.)
    ${ret}=    Serial Parallel Read Until Regex    Left    feed watch(.)og
    ${ret}=    Serial Parallel Wait    Case Left
    Should Be Equal    ${ret}[Case][0][0]    b
    Should Be Equal    ${ret}[Left][0][0]    d

Serial read newline 
    ${ret}=    Serial Read Until     Case      
    Log   ${ret}
    ${ret}=    Serial Read Until     Left      
    Log   ${ret}
    ${ret}=    Serial Read Until     Case      
    Log   ${ret}
    ${ret}=    Serial Read Until     Left      
    Log   ${ret}
*** Keywords ***
Serial Open All
    Serial Open Port    Case    /dev/ttyACM0    115200
    Serial Open Port    Left    /dev/ttyUSB0    1152000

Serial Close All
    Serial Close Port    Case
    Serial Close Port    Left

