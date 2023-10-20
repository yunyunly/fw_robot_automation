*** Settings ***
Suite Setup       Connect Case
Suite Teardown    Disconnect Case
Test Setup        Open Serial Port    /dev/ttyACM0    115200
Test Teardown     Close Serial Port
Library           ../lib/EchoLib.py
Library           ../lib/SerialLib.py

*** Test Cases ***
Print information
    Print Info
    Serial Read Until Regex    [BluePig] SOC (\\d+)

Case open 
    Case Open 
    Serial Read Until Regex   [BluePig] 

Case close 
    Serial Read Until Regex   [BluePig]

Charger plug in 
    Plug In 
    Serial Read Until Regex   [BluePig] 

Charger plug out
    Plug Out 
    Serial Read Until Regex   [BluePig]

Case connect hearing aids 
    Case Connect Hearing Aids 
    Serial Read Until Regex   [BluePig]

Case disconnect hearing aids 
    Case Disconnect Hearing Aids 
    Serial Read Until Regex   [BluePig]


Case close charge hearing aids 
    Case Open 
    Case Connect Hearing Aids 
    Case Close 




