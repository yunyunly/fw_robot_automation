*** Settings ***
Library    ../lib/PreludeControlLib.py
Suite Teardown    Close

*** Variables ***
${prelude_id}=    1

*** Keywords ***
Close 
    Charge    off    lr
    Close Ftdi

*** Test Cases ***
Charge Ha
    Open Device    ${prelude_id}
    Charge    on    lr
    Log To Console    charging ha.CI idling
    Sleep    2day