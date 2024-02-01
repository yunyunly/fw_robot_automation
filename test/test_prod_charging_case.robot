*** Setting ***
Documentation     Core testcases for testing Charging Case's User Interface Functionality
...               Contains most items in checklist
Suite Setup       Setup
Suite Teardown    Teardown
Test Setup
Test Teardown
Default Tags      Base
Metadata          Author    fanyx
Metadata          Last Update    2023/12/26
Metadata          Platform    Linux
Metadata          Bluez Version    5.66
Metadata          Python Version    3.10.13
Metadata          Robot Framework Version    6.1.1
Library           ../lib/SerialLib.py
Library           ../lib/BluetoothLib.py
Library           ../lib/ChargingCaseLib.py
Library           String
Library           Collections

*** Variables ***
${CC_BLE_ADDR}    D0:14:11:20:1F:B3     # 充电盒BLE地址
${CC_TTY_PORT}    /dev/ttyACM0    # 充电盒串口端口
${CC_TTY_BAUDRATE}    115200    # 充电盒串口波特率
${HA_BLE_ADDR}    12:34:56:78:A0:B3    # 助听器BLE地址
${HA_BT_ADDR}     12:34:56:78:A0:B3    # 助听器BT地址
${HA_L_TTY_PORT}    /dev/ttyUSB3    # 助听器左耳串口端口
${HA_R_TTY_PORT}    /dev/ttyUSB4    # 助听器右耳串口端口
${HA_TTY_BAUDRATE}    1152000    # 助听器串口波特率

*** Test Cases ***
Remark
    [Documentation]    测试时充电盒保持开盒、助听器双耳置于盒内，断开充电器
    Case Open
    Sleep    1s
    Case Close 
    Should Be True    ${True}

Case info
    [Documentation]    基本检查、此测试通过说明Robot Framework正常、蓝牙正常、串口正常、浮点数正常、充电盒为Robot测试版并且不处于低电量模式。
    Print Info
    ${find}    ${ctx}=    Read Case Regex    SOC ([0-9]+) Volt ([0-9]+) Curr ([\\+\\-]?[0-9]+\\.[0-9]+) Temp ([\\+\\-]?[0-9]+) Charge ([0-9]+)    timeout=${3}
    Log To Console    ${ctx}
    ${soc}=    Set Variable    ${ctx}[0]
    ${volt}=    Set Variable    ${ctx}[1]
    ${curr}=    Set Variable    ${ctx}[2]
    ${temp}=    Set Variable    ${ctx}[3]
    ${charge}=    Set Variable    ${ctx}[4]
    Should Be True    ${soc} >= 10 and ${soc} <= 100
    Should Be True    ${curr} != "None"
    Should Be True    ${charge} == 0


Case binding hearing aids
    [Documentation]    三合一绑定
    Case Open
    Sleep    1s
    Dock    Both
    Sleep    1s
    Case Close
    Sleep    1s
    Press Button    Reset    Long
    ${fd}=    Read Case    binding success    ${10}
    ${fd}=    Read Case    binding end
    Should Be True    ${fd}
    Connect Charging Case    ${CC_BLE_ADDR}

Case open turn on Leds
    [Documentation]    开盒助听器开机、充电盒亮灯、助听器保持开机
    ${want0}=    Set Variable    Led: turn on front led case open
    ${want1a}=    Set Variable    turn on both led
    ${want1b}=    Set Variable    turn on right led
    ${want1c}=    Set Variable    turn on left led
    Case Open
    Serial Parallel Read Until    Case    ${want0}    timeout=${3}
    Serial Parallel Read Until    Case    ${want1a}    timeout=${3}
    Serial Parallel Read Until    Case    ${want1b}    timeout=${3}
    Serial Parallel Read Until    Case    ${want1c}    timeout=${3}
    ${map}=    Serial Parallel Wait    Case
    Should Contain    ${map}[Case][0]    ${want0}
    Remove Values From List    ${map}[Case]    ${None}
    ${len}=    Get Length    ${map}[Case]
    IF    ${len} == 2
        Should Contain Match    ${map}[Case]     *${want1a}
    ELSE IF     ${len} == 3
        Should Contain Match    ${map}[Case]    *${want1b}
        Should Contain Match    ${map}[Case]    *${want1c}
    ELSE
        Fail
    END 
    Sleep    5s
    ${want0}=    Set Variable    Uart: left soc
    ${want1}=    Set Variable    Uart: right soc
    Request Hearing Aids Soc    Both
    Serial Parallel Read Until    Case    ${want0}    timeout=${3}
    Serial Parallel Read Until    Case    ${want1}    timeout=${3}
    ${map}=    Serial Parallel Wait    Case
    Should Not Be Equal    ${map}[Case][0]    ${None}
    Should Not Be Equal    ${map}[Case][1]    ${None}
    Should Contain    ${map}[Case][0]    ${want0}
    Should Contain    ${map}[Case][1]    ${want1}

Case close turn off Leds
    [Documentation]    关盒助听器自动关机
    ${want0}=    Set Variable    Led: turn off front led case close
    ${want1}=    Set Variable    Start pmu shutdown
    Case Open
    Sleep    2s
    Case Close
    ${fd}=    Read Case    ${want0}    timeout=3
    Should Be True    ${fd}
    Serial Parallel Read Until    Left    ${want1}    timeout=${7}
    Serial Parallel Read Until    Right    ${want1}    timeout=${7}
    ${map}=    Serial Parallel Wait    Left Right
    Should Contain    ${map}[Left][0]    ${want1}
    Should Contain    ${map}[Right][0]    ${want1}

Case single dock and undock
    [Documentation]    单耳分别出盒入盒两遍
    Case Open
    sleep    0.5s
    Undock    Left
    ${fd}=    Read Case    Action: undock left
    Should Be True    ${fd}
    Dock    Left
    ${fd}=    Read Case    Action: dock left
    Should Be True    ${fd}
    ${fd}=    Read Case    Led: turn on left led
    Should Be True    ${fd}
    Undock    Right
    ${fd}=    Read Case    Action: undock right
    Should Be True    ${fd}
    Dock    Right
    ${fd}=    Read Case    Action: dock right
    Should Be True    ${fd}
    ${fd}=    Read Case    Led: turn on right led
    Should Be True    ${fd}
    Undock    Left
    ${fd}=    Read Case    Action: undock left
    Should Be True    ${fd}
    Dock    Left
    ${fd}=    Read Case    Action: dock left
    Should Be True    ${fd}
    ${fd}=    Read Case    Led: turn on left led
    Should Be True    ${fd}
    Undock    Right
    ${fd}=    Read Case    Action: undock right
    Should Be True    ${fd}
    Dock    Right
    ${fd}=    Read Case    Action: dock right
    Should Be True    ${fd}
    ${fd}=    Read Case    Led: turn on right led
    Should Be True    ${fd}

Case double dock and undock

    [Documentation]    双耳同时出盒入盒两遍
    Case Open
    sleep    0.5s
    Undock    Both
    ${fd}=    Read Case    Action: undock both
    Should Be True    ${fd}
    Dock    Both
    ${fd}=    Read Case    Action: dock both
    Should Be True    ${fd}
    ${fd}=    Read Case    Led: turn on both led
    Should Be True    ${fd}
    sleep    1.5s
    Undock    Both
    ${fd}=    Read Case    Action: undock both
    Should Be True    ${fd}
    Dock    Both
    ${fd}=    Read Case    Action: dock both
    Should Be True    ${fd}
    ${fd}=    Read Case    Led: turn on both led
    Should Be True    ${fd}

Case charger plug in and plug out
    [Documentation]    充电盒充电插入触发与拔出触发
    Plug In
    ${res}=    Read Case    Action: plug in
    Should Be True    ${res}
    ${res}=    Read Case    Led: turn on front led plug in
    Should Be True    ${res}
    Sleep    1.5s
    Plug Out
    ${res}=    Read Case    Action: plug out
    Should Be True    ${res}
    ${res}=    Read Case    Led: turn off front led plug out
    Should Be True    ${res}

Case control volume
    [Documentation]    充电盒按键控制音量加减
    Case Open
    Sleep    2s
    Undock    Both
    Sleep    2s
    Press Button    Left
    ${res}=    Read Case    Btn: vol up
    Should Be True    ${res}
    ${res}=    Read Right    Btn: vol up    
    Should Be True    ${res}
    ${res}=    Read Left    Btn: vol up
    Should Be True    ${res}
    Sleep    0.5s
    Press Button    Right
    ${res}=    Read Case    Btn: vol down
    Should Be True    ${res}
    ${res}=    Read Right    Btn: vol down
    Should Be True    ${res}
    ${res}=    Read Left    Btn: vol down
    Should Be True    ${res}


Case control mode switch
    [Documentation]    充电盒按键控制模式切换
    Case Open
    Sleep    2s
    Undock    Both
    Sleep    2s
    Press Button    Fn
    ${res}=    Read Case    Btn: mode switch
    Should Be True    ${res}
    ${res}=    Read Right    mode switch to
    Should Be True    ${res}
    ${res}=    Read Left    mode switch to
    Should Be True    ${res}
    Sleep    0.5s
    Press Button    Fn
    ${res}=    Read Case    Btn: mode switch
    Should Be True    ${res}
    ${res}=    Read Right    mode switch to
    Should Be True    ${res}
    ${res}=    Read Left    mode switch to
    Should Be True    ${res}


Case pairing success
    [Documentation]    手机蓝牙配对成功
    Case Close 
    Sleep    0.5s
    Case Open
    Sleep    0.5s
    Dock    Both
    Sleep    0.5s
    Press Button    Fn    Long
    ${res}=    Read Case    Led: tws pairing
    Should Be True    ${res}    Case should log pairing start 
    ${res}=    Bt Connect Hearing Aids	  ${HA_BT_ADDR}
        Should Be True    ${res}    Bt should connect ha
    ${res}=    Read Case    Led: tws pairing success    ${20}
    Should Be True    ${res}    Case should log pairing success


Case pairing cancel
    [Documentation]    手机蓝牙配对中途关盒取消
    Case Close 
    Sleep    0.5s
    Case Open
    Sleep    0.5s
    Dock    Both
    Sleep    0.5s
    Press Button    Fn    Long
    ${res}=    Read Case    Led: tws pairing
    Should Be True    ${res}
    Case Close
    ${res}=    Read Case    Led: tws pairing cancel
    Should Be True    ${res}

Case pairing timeout
    [Documentation]    手机蓝牙配对2分钟超时
    Case Open
    Sleep    0.5s
    Dock    Both
    Sleep    0.5s
    Press Button    Fn    Long
    ${res}=    Read Case    Led: tws pairing
    Should Be True    ${res}
    ${res}=    Read Case    Led: tws pairing timeout    timeout=${150}
    Should Be True    ${res}

*** Keywords ***
Setup
    Serial Open Port    Case    ${CC_TTY_PORT}    ${CC_TTY_BAUDRATE}
    Serial Open Port    Left    ${HA_L_TTY_PORT}    ${HA_TTY_BAUDRATE}
    Serial Open Port    Right    ${HA_R_TTY_PORT}    ${HA_TTY_BAUDRATE}
    BluetoothLib.Init
    ${ret}=    Connect Charging Case    ${CC_BLE_ADDR}
    Should Be True    ${ret}

Teardown
    Serial Close Port    Case
    Serial Close Port    Left
    Serial Close Port    Right
    Case Close
    Sleep    1s
    Disconnect Charging Case    ${CC_BLE_ADDR}
    Disconnect    ${HA_BT_ADDR}
    BluetoothLib.Quit

Read Case
    [Arguments]    ${str}    ${timeout}=${3}
    ${res}=    Serial Read Until    Case    ${str}    timeout=${timeout}
    ${ret}=    Set Variable If    "${res}" == "None"    ${False}    ${True}
    RETURN    ${ret}

Read Left
    [Arguments]    ${str}    ${timeout}=${3}
    ${res}=    Serial Read Until    Left    ${str}    timeout=${timeout}
    ${ret}=    Set Variable If    "${res}" == "None"    ${False}    ${True}
    RETURN    ${ret}

Read Right
    [Arguments]    ${str}    ${timeout}=${3}
    ${res}=    Serial Read Until    Right    ${str}    timeout=${timeout}
    ${ret}=    Set Variable If    "${res}" == "None"    ${False}    ${True}
    RETURN    ${ret}

Read Case Regex
    [Arguments]    ${str}    ${timeout}=${3}
    @{res}=    Serial Read Until Regex    Case    ${str}    timeout=${timeout}
    IF    "${res}" == "None"
        RETURN    ${False}    @{EMPTY}
    ELSE
        ${length}=    Get Length    ${res}
        IF    ${length} == ${0}
            RETURN    ${False}    @{EMPTY}
        ELSE
            RETURN    ${True}    ${res}
        END
    END
