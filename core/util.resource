*** Settings ***
Documentation     An simple resource file
Library           ../lib/SerialLib.py
Library    ../lib/ChargingCaseLib.py

*** Variables ***
${Charging Case BLE Addr}     D0:14:11:20:20:18
${Hearing Aids BLE Addr}    12:34:56:78:A0:B3   
${HOST}           localhost:7272
${LOGIN URL}      http://${HOST}/
${WELCOME URL}    http://${HOST}/welcome.html
${BROWSER}        Firefox

*** Keywords ***
Serial Open Case 
    [Arguments]    ${port}    ${bard rate}
    Serial Open Port    Case    ${port}    ${bard rate}

Serial Open Left 
    [Arguments]    ${port}    ${bard rate}
    Serial Open Port    Left    ${port}    ${bard rate}

Serial Open Right 
    [Arguments]    ${port}    ${bard rate}
    Serial Open Port    Right    ${port}    ${bard rate}

Serial Close Case 
    Serial Close Port    Case 

Serial Close Left 
    Serial Close Port    Left 
Serial Close Right 
    Serial Close Port    Right

Read Case 
    [Arguments]    ${str}     ${timeout}=${3}
    ${res}=    Serial Read Until    Case    ${str}    ${timeout}
    ${ret}=    Set Variable If    "${res}"=="None"    ${False}    ${True}
    RETURN    ${ret}

Read Left 
    [Arguments]    ${str}     ${timeout}=${3}
    ${res}=    Serial Read Until    Case    ${str}    ${timeout}
    ${ret}=    Set Variable If    "${res}"=="None"    ${False}    ${True}
    RETURN    ${ret}

Read Right 
    [Arguments]    ${str}     ${timeout}=${3}
    ${res}=    Serial Read Until    Case    ${str}    ${timeout}
    ${ret}=    Set Variable If    "${res}"=="None"    ${False}    ${True}
    RETURN    ${ret}

Read Case Regex 
    [Arguments]    ${str}    ${timeout}=${3} 
    @{res}=    Serial Read Until Regex    Case    ${str}    timeout=${timeout}
    IF    "${res}" == "None"
        RETURN      ${False}     @{EMPTY}
    ELSE
        ${length}=    Get Length     ${res}
        IF    ${length} == ${0}
            RETURN      ${False}    @{EMPTY}
        ELSE
            RETURN      ${True}      @{res}
        END
    END
Read Left Regex 
    [Arguments]    ${str}    ${timeout}=${3} 
    @{res}=    Serial Read Until Regex    Left    ${str}    timeout=${timeout}
    IF    "${res}" == "None"
        RETURN      ${True}
    ELSE
        RETURN      @{res}
    END
Read Right Regex 
    [Arguments]    ${str}    ${timeout}=${3} 
    @{res}=    Serial Read Until Regex    Right    ${str}    timeout=${timeout}
    IF    "${res}" == "None"
        RETURN      ${True}
    ELSE
        RETURN      @{res}
    END

