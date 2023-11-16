*** Settings ***
Documentation     Keywords(API) Test Cases for App control HA
Suite Setup       Connect Hearing Aids   D2:04:56:78:9A:01
Suite Teardown    Disconnect Hearing Aids
# Test Setup        Open Serial Port    /dev/ttyACM0    115200
# Test Teardown     Close Serial Port
Library           ../lib/HearingAidLib.py
# Library           ../lib/SerialLib.py

*** Test Cases ***
check general status
    Check General Status
