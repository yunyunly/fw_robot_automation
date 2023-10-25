*** Settings ***
Documentation     Keywords(API) Test Cases for charging case
Suite Setup       Connect Charging Case    D0:14:11:20:20:18
Suite Teardown    Disconnect Charging Case
Test Setup        Open Serial Port    /dev/ttyACM0    115200
Test Teardown     Close Serial Port
Library           ../lib/ChargingCaseLib.py
Library           ../lib/SerialLib.py

*** Test Cases ***
Print information
    Print Info
    ${matched}=    Serial Read Until Regex    SOC ([0-9]+) Volt ([0-9]+) Curr ([\\+\\-]?[0-9]+\\.[0-9]+) Temp ([\\+\\-]?[0-9]+) Charge ([0-9]+)
    ${soc}=    Set Variable    ${matched}[0]
    ${volt}=    Set Variable    ${matched}[1]
    ${curr}=    Set Variable    ${matched}[2]
    ${temp}=    Set Variable    ${matched}[3]
    ${charge}=    Set Variable    ${matched}[4]
    IF    ${charge} == 1
        Should Be True    ${curr} >= 0
    ELSE
        Should Be True    ${curr} < 0
    END
    Should Be True    ${soc} >= 0 and ${soc} <= 100

Case open
    Case Open
    ${status}=    Serial Read Until Regex    Robot: case ([a-zA-Z]+)
    Should Be Equal    ${status}[0]    open

Case close
    Case Close
    ${status}=    Serial Read Until Regex    Robot: case ([a-zA-Z]+)
    Should Be Equal    ${status}[0]    close

Plug in
    Plug In
    ${status}=    Serial Read Until Regex    Robot: vin plug ([a-zA-Z]+)
    Should Be Equal    ${status}[0]    in

Plug out
    Plug Out
    ${status}=    Serial Read Until Regex    Robot: vin plug ([a-zA-Z]+)
    Should Be Equal    ${status}[0]    out

Case connect hearing aids
    Case Connect Hearing Aids
    ${status}=    Serial Read Until Regex    Robot: ([a-zA-Z]+) ha
    Should Be Equal    ${status}[0]    connect

Case disconnect hearing aids
    Case Disconnect Hearing Aids
    ${status}=    Serial Read Until Regex    Robot: ([a-zA-Z]+) ha
    Should Be Equal    ${status}[0]    disconnect

Case start charge hearing aids
    Charge Hearing Aids    Left
    ${status}=    Serial Read Until Regex    Robot: do chg ([a-zA-Z]+)
    Should Be Equal    ${status}[0]    left
    Charge Hearing Aids    Right
    ${status}=    Serial Read Until Regex    Robot: do chg ([a-zA-Z]+)
    Should Be Equal    ${status}[0]    right
    Charge Hearing Aids    Both
    ${status}=    Serial Read Until Regex    Robot: do chg ([a-zA-Z]+)
    Should Be Equal    ${status}[0]    both

Case stop charge hearing aids
    Charge Hearing Aids Stop    Left
    ${status}=    Serial Read Until Regex    Robot: stop chg ([a-zA-Z]+)
    Should Be Equal    ${status}[0]    left
    Charge Hearing Aids Stop    Right
    ${status}=    Serial Read Until Regex    Robot: stop chg ([a-zA-Z]+)
    Should Be Equal    ${status}[0]    right
    Charge Hearing Aids Stop    Both
    ${status}=    Serial Read Until Regex    Robot: stop chg ([a-zA-Z]+)
    Should Be Equal    ${status}[0]    both

Case dock
    Dock    Left
    ${status}=    Serial Read Until Regex    Robot: dock ([a-zA-Z]+)
    Should Be Equal    ${status}[0]    left
    Dock    Right
    ${status}=    Serial Read Until Regex    Robot: dock ([a-zA-Z]+)
    Should Be Equal    ${status}[0]    right
    Dock    Both
    ${status}=    Serial Read Until Regex    Robot: dock ([a-zA-Z]+)
    Should Be Equal    ${status}[0]    both

Case undock
    Undock    Left
    ${status}=    Serial Read Until Regex    Robot: undock ([a-zA-Z]+)
    Should Be Equal    ${status}[0]    left
    Undock    Right
    ${status}=    Serial Read Until Regex    Robot: undock ([a-zA-Z]+)
    Should Be Equal    ${status}[0]    right
    Undock    Both
    ${status}=    Serial Read Until Regex    Robot: undock ([a-zA-Z]+)
    Should Be Equal    ${status}[0]    both

Press button
    Press Button    Fn
    ${status}=    Serial Read Until Regex    Robot: press ([a-zA-Z]+)
    Should Be Equal    ${status}[0]    fn
    Press Button    Fn    Long
    ${status}=    Serial Read Until Regex    Robot: press ([a-zA-Z]+)
    Should Be Equal    ${status}[0]    fnlong
    Press Button    Reset
    ${status}=    Serial Read Until Regex    Robot: press ([a-zA-Z]+)
    Should Be Equal    ${status}[0]    rst
    Press Button    Reset    Long
    ${status}=    Serial Read Until Regex    Robot: press ([a-zA-Z]+)
    Should Be Equal    ${status}[0]    rstlong
    Press Button    Left
    ${status}=    Serial Read Until Regex    Robot: press ([a-zA-Z]+)
    Should Be Equal    ${status}[0]    left
    Press Button    Right
    ${status}=    Serial Read Until Regex    Robot: press ([a-zA-Z]+)
    Should Be Equal    ${status}[0]    right

Pulse
    Generate Pulse    Left
    ${status}=    Serial Read Until Regex    Robot: pulse ([a-zA-Z]+)
    Should Be Equal    ${status}[0]    left
    Generate Pulse    Right
    ${status}=    Serial Read Until Regex    Robot: pulse ([a-zA-Z]+)
    Should Be Equal    ${status}[0]    right
    Generate Pulse    Both
    ${status}=    Serial Read Until Regex    Robot: pulse ([a-zA-Z]+)
    Should Be Equal    ${status}[0]    both

Soc
    Request Hearing Aids Soc    Left
    ${status}=    Serial Read Until Regex    Robot: soc ([a-zA-Z]+)
    Should Be Equal    ${status}[0]    left
    Request Hearing Aids Soc    Right
    ${status}=    Serial Read Until Regex    Robot: soc ([a-zA-Z]+)
    Should Be Equal    ${status}[0]    right
    Request Hearing AIds Soc    Both
    ${status}=    Serial Read Until Regex    Robot: soc ([a-zA-Z]+)
    Should Be Equal    ${status}[0]    both

Single wire
    Single Wire Send    Left    01ff00
    ${status}=    Serial Read Until Regex    Robot: uart snd ([a-zA-Z]+) ([0-9a-f]+)
    Should Be Equal    ${status}[0]    left
    Should Be Equal    ${status}[1]    01ff00
    Single Wire Send    Right    01ff00
    ${status}=    Serial Read Until Regex    Robot: uart snd ([a-zA-Z]+) ([0-9a-f]+)
    Should Be Equal    ${status}[0]    right
    Should Be Equal    ${status}[1]    01ff00
    Single Wire Send    Both    01ff00
    ${status}=    Serial Read Until Regex    Robot: uart snd ([a-zA-Z]+) ([0-9a-f]+)
    Should Be Equal    ${status}[0]    both
    Should Be Equal    ${status}[1]    01ff00
    Single Wire Request    Left    01ff00
    ${status}=    Serial Read Until Regex    Robot: uart req ([a-zA-Z]+) ([0-9a-f]+)
    Should Be Equal    ${status}[0]    left
    Should Be Equal    ${status}[1]    01ff00
    Single Wire Request    Right    01ff00
    ${status}=    Serial Read Until Regex    Robot: uart req ([a-zA-Z]+) ([0-9a-f]+)
    Should Be Equal    ${status}[0]    right
    Should Be Equal    ${status}[1]    01ff00
    Single Wire Request    Both    01ff00
    ${status}=    Serial Read Until Regex    Robot: uart req ([a-zA-Z]+) ([0-9a-f]+)
    Should Be Equal    ${status}[0]    both
    Should Be Equal    ${status}[1]    01ff00

Reset
    Reset
    Serial Read Until    WIRELESS_FW_RUNNING
    Serial Read Until    DBGMCU_GetRevisionID= 2001
    Serial Read Until    DBGMCU_GetDeviceID= 495
