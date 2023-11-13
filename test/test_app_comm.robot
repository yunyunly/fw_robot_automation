*** Settings ***
Documentation     Keywords(API) Test Cases for App control HA
Suite Setup       Connect Hearing Aids   11:11:22:33:33:81
Suite Teardown    Disconnect Hearing Aids   11:11:22:33:33:81
# Test Setup        Open Serial Port    /dev/ttyACM0    115200
# Test Teardown     Close Serial Port
Library           ../lib/HearingAidLib.py
# Library           ../lib/SerialLib.py

*** Test Cases ***
check general status
    Check General Status
