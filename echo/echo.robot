*** Settings ***
Suite Setup       Connect Case
Suite Teardown    Disconnect Case
Test Setup        Open Serial Port \ \ \ /dev/ttyACM0 \ \ \ 115200
Test Teardown     Close Serial Port
Library           ../lib/EchoLib.py
Library           ../lib/SerialLib.py

*** Test Cases ***
Print information
    Print Info
    Serial Read Until Regex    [BluePig] SOC (\\d+)
