*** Settings ***
Documentation     Keywords(API) Test Cases for charging case
Suite Setup       Connect Charging Case    D0:14:11:20:20:18
Suite Teardown    Disconnect Charging Case
Test Setup        Serial Open Port    Case   /dev/ttyACM0    115200
Test Teardown     Serial Close Port    Case
Library           ../lib/ChargingCaseLib.py
Library           ../lib/SerialLib.py

*** Test Cases ***
Print information
    Print Info
    ${matched}=    Serial Read Until Regex    Case    SOC ([0-9]+) Volt ([0-9]+) Curr ([\\+\\-]?[0-9]+\\.[0-9]+) Temp ([\\+\\-]?[0-9]+) Charge ([0-9]+)
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
    ${status}=    Serial Read Until Regex    Case    Robot: case ([a-zA-Z]+)
    Should Be Equal    ${status}[0]    open

Case close
    Case Close
    ${status}=    Serial Read Until Regex    Case    Robot: case ([a-zA-Z]+)
    Should Be Equal    ${status}[0]    close

Plug in
    Plug In
    ${status}=    Serial Read Until Regex    Case    Robot: vin plug ([a-zA-Z]+)
    Should Be Equal    ${status}[0]    in

Plug out
    Plug Out
    ${status}=    Serial Read Until Regex    Case    Robot: vin plug ([a-zA-Z]+)
    Should Be Equal    ${status}[0]    out

Case connect hearing aids
    Case Connect Hearing Aids
    ${status}=    Serial Read Until Regex    Case    Robot: ([a-zA-Z]+) ha
    Should Be Equal    ${status}[0]    connect

Case disconnect hearing aids
    Case Disconnect Hearing Aids
    ${status}=    Serial Read Until Regex    Case    Robot: ([a-zA-Z]+) ha
    Should Be Equal    ${status}[0]    disconnect

Case start charge hearing aids
    Charge Hearing Aids    Left
    ${status}=    Serial Read Until Regex    Case    Robot: do chg ([a-zA-Z]+)
    Should Be Equal    ${status}[0]    left
    Charge Hearing Aids    Right
    ${status}=    Serial Read Until Regex    Case    Robot: do chg ([a-zA-Z]+)
    Should Be Equal    ${status}[0]    right
    Charge Hearing Aids    Both
    ${status}=    Serial Read Until Regex    Case    Robot: do chg ([a-zA-Z]+)
    Should Be Equal    ${status}[0]    both

Case stop charge hearing aids
    Charge Hearing Aids Stop    Left
    ${status}=    Serial Read Until Regex    Case    Robot: stop chg ([a-zA-Z]+)
    Should Be Equal    ${status}[0]    left
    Charge Hearing Aids Stop    Right
    ${status}=    Serial Read Until Regex    Case    Robot: stop chg ([a-zA-Z]+)
    Should Be Equal    ${status}[0]    right
    Charge Hearing Aids Stop    Both
    ${status}=    Serial Read Until Regex    Case    Robot: stop chg ([a-zA-Z]+)
    Should Be Equal    ${status}[0]    both

Case dock
    Dock    Left
    ${status}=    Serial Read Until Regex    Case    Robot: dock ([a-zA-Z]+)
    Should Be Equal    ${status}[0]    left
    Dock    Right
    ${status}=    Serial Read Until Regex    Case    Robot: dock ([a-zA-Z]+)
    Should Be Equal    ${status}[0]    right
    Dock    Both
    ${status}=    Serial Read Until Regex    Case    Robot: dock ([a-zA-Z]+)
    Should Be Equal    ${status}[0]    both

Case undock
    Undock    Left
    ${status}=    Serial Read Until Regex    Case    Robot: undock ([a-zA-Z]+)
    Should Be Equal    ${status}[0]    left
    Undock    Right
    ${status}=    Serial Read Until Regex    Case    Robot: undock ([a-zA-Z]+)
    Should Be Equal    ${status}[0]    right
    Undock    Both
    ${status}=    Serial Read Until Regex    Case    Robot: undock ([a-zA-Z]+)
    Should Be Equal    ${status}[0]    both

Press button
    Press Button    Fn
    ${status}=    Serial Read Until Regex    Case    Robot: press ([a-zA-Z]+)
    Should Be Equal    ${status}[0]    fn
    Press Button    Fn    Long
    ${status}=    Serial Read Until Regex    Case    Robot: press ([a-zA-Z]+)
    Should Be Equal    ${status}[0]    fnlong
    Press Button    Reset
    ${status}=    Serial Read Until Regex    Case    Robot: press ([a-zA-Z]+)
    Should Be Equal    ${status}[0]    rst
    Press Button    Reset    Long
    ${status}=    Serial Read Until Regex    Case    Robot: press ([a-zA-Z]+)
    Should Be Equal    ${status}[0]    rstlong
    Press Button    Left
    ${status}=    Serial Read Until Regex    Case    Robot: press ([a-zA-Z]+)
    Should Be Equal    ${status}[0]    left
    Press Button    Right
    ${status}=    Serial Read Until Regex    Case    Robot: press ([a-zA-Z]+)
    Should Be Equal    ${status}[0]    right

Pulse
    Generate Pulse    Left
    ${status}=    Serial Read Until Regex    Case    Robot: pulse ([a-zA-Z]+)
    Should Be Equal    ${status}[0]    left
    Generate Pulse    Right
    ${status}=    Serial Read Until Regex    Case    Robot: pulse ([a-zA-Z]+)
    Should Be Equal    ${status}[0]    right
    Generate Pulse    Both
    ${status}=    Serial Read Until Regex    Case    Robot: pulse ([a-zA-Z]+)
    Should Be Equal    ${status}[0]    both

Soc
    Request Hearing Aids Soc    Left
    ${status}=    Serial Read Until Regex    Case    Robot: soc ([a-zA-Z]+)
    Should Be Equal    ${status}[0]    left
    Request Hearing Aids Soc    Right
    ${status}=    Serial Read Until Regex    Case    Robot: soc ([a-zA-Z]+)
    Should Be Equal    ${status}[0]    right
    Request Hearing AIds Soc    Both
    ${status}=    Serial Read Until Regex    Case    Robot: soc ([a-zA-Z]+)
    Should Be Equal    ${status}[0]    both

Single wire send
    Single Wire Send    Left    01ff00
    ${status}=    Serial Read Until Regex    Case    Robot: uart snd ([a-zA-Z]+)
    Should Be Equal    ${status}[0]    left
    ${status}=    Serial Read Until Regex    Case    Robot: snd ([0-9a-f]+)
    Should Be Equal    ${status}[0]    01ff00
    Single Wire Send    Right    01ff00
    ${status}=    Serial Read Until Regex    Case    Robot: uart snd ([a-zA-Z]+)
    Should Be Equal    ${status}[0]    right
    ${status}=    Serial Read Until Regex    Case    Robot: snd ([0-9a-f]+)
    Should Be Equal    ${status}[0]    01ff00
    Single Wire Send    Both    01ff00
    ${status}=    Serial Read Until Regex    Case    Robot: uart snd ([a-zA-Z]+)
    Should Be Equal    ${status}[0]    both
    ${status}=    Serial Read Until Regex    Case    Robot: snd ([0-9a-f]+)
    Should Be Equal    ${status}[0]    01ff00
    ${status}=    Serial Read Until Regex    Case    Robot: snd ([0-9a-f]+)
    Should Be Equal    ${status}[0]    01ff00

Single wire req
    Single Wire Request    Left    010b00     4
    ${status}=    Serial Read Until Regex    Case    Robot: uart req ([a-zA-Z]+)
    Should Be Equal    ${status}[0]    left
    ${status}=    Serial Read Until Regex    Case    Robot: recv ([0-9a-f]+)
    Should Be Equal    ${status}[0]    020c0101
    Single Wire Request    Right    010b00    4
    ${status}=    Serial Read Until Regex    Case    Robot: uart req ([a-zA-Z]+)
    Should Be Equal    ${status}[0]    right
    ${status}=    Serial Read Until Regex    Case    Robot: recv ([0-9a-f]+)
    Should Be Equal    ${status}[0]    020c0101
    Single Wire Request    Both    010b00     4
    ${status}=    Serial Read Until Regex    Case    Robot: uart req ([a-zA-Z]+)
    Should Be Equal    ${status}[0]    both
    ${status}=    Serial Read Until Regex    Case    Robot: recv ([0-9a-f]+)
    Should Be Equal    ${status}[0]    020c0101
    ${status}=    Serial Read Until Regex    Case    Robot: recv ([0-9a-f]+)
    Should Be Equal    ${status}[0]    020c0101

Reset
    Reset
    Serial Read Until    Case     WIRELESS_FW_RUNNING
    Serial Read Until    Case    DBGMCU_GetRevisionID= 2001
    Serial Read Until    Case     DBGMCU_GetDeviceID= 495
