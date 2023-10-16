*** Setting ***
Documentation     Test cases for testing serial library
...
...               All keywords constructed from ``SerialLib.py``.
Test Setup        Open Serial Port    /dev/ttyACM0    115200
Test Teardown     Close Serial Port
Default Tags      Serial
Library           SerialLib.py

*** Test Cases ***
Open and close serial port
    [Setup]
    Open Serial Port    /dev/ttyACM0    115200
    Close Serial Port
    [Teardown]

Serial read latest
    ${line} =    Serial Read Latest
    Log    ${line}

Serial read newest
    FOR    ${i}    IN RANGE    1    1000
        ${line0} =    Serial Read Newest
        LOG    ${line0}
        IF    "${line0}" != "${None}"
            BREAK
        END
        Sleep    100ms
    END
    ${line1} =    Serial Read Newest
    Should Not Be Equal    ${line0}    ${line1}

Serial read blocking
    FOR    ${/}    IN RANGE    1    10
        ${line} =    Serial Read Blocking
        Should Not Be Equal    ${line}    None
    END

Serial read until string
    ${line} =    Serial Read Until    heartbeat

Serial read until regex
    [Tags]    Serial
    ${ret}=    Serial Read Until Regex    heart(.)
    Should Be Equal    ${ret}[0]     b

Serial write string
    Serial Write String    abcdefg

Serial write hex
    Serial Write Hex    ff00

*** Keywords ***
Read Until Regex
    Log    Deprecated
    # [Arguments]    ${pattern}
    # ${ret}    Set Variable    null
    # WHILE    True
        # ${newline}=    Serial Read Newest
        # IF    "${newline}" == "${None}"
            # CONTINUE
        # END
        # IF    "${newline}" == ""
            # CONTINUE
        # END
        # ${ret}=    Should Match Regexp    ${newline}    ${pattern}
        # IF    "${ret}" != "${None}"
            # BREAK
        # END
    # END
    # RETURN    ${ret}
