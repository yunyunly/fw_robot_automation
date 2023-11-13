*** Setting ***
Documentation     Core Test Cases for testing both Charging Case and Hearing Aids' User Interface Functionality
...                Contains most items in checklist
...               
Suite Setup         Setup
Suite Teardown      Teardown
Test Setup
Test Teardown
Default Tags      Charge
Resource           util.resource 
Library            ../lib/ChargingCaseLib.py
Library    ../lib/SerialLib.py
Library     Collections

Request Ha Voltage 
    Single Wire  Request    Left     010d00    5
    ${find}    ${ret}=    Read Case Regex    Uart: left volt ([0-9]+)mV
    Should Be True     ${find}

    Single Wire  Request    Right     010d00    5
    ${find}    ${ret}=    Read Case Regex    Uart: right volt ([0-9]+)mV
    Should Be True     ${find}

    Single Wire  Request    Both     010d00    5
    ${find}    ${ret}=    Read Case Regex    Uart: (left|right) volt ([0-9]+)mV
    Should Be True     ${find}
    ${find}    ${ret}=    Read Case Regex    Uart: (left|right) volt ([0-9]+)mV
    Should Be True     ${find}