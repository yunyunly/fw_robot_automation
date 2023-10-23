*** Settings ***
Library           ${CURDIR}/../lib/ChargingCaseLib.py
Library           ${CURDIR}/../lib/SerialLib.py
Suite Setup       
Suite Teardown     
Test Setup        Open Serial Port    /dev/ttyACM0    115200
Test Teardown     Close Serial Port


*** Keywords ***
Infra Connect Case
  Connect Charging Case  D0:14:11:20:20:10

Infra Disconnect Case 
  Disconnect Charging Case 

*** Test Cases ***
Connect case 
    &{all libs}=  Get library instance  all=True
    Log   ${all libs}
    Serial Write Hex             abcd
    Connect Charging Case     

Print information
    Connect Charging Case    
    Print Info
    ${matched}=   Serial Read Until Regex  SOC ([0-9]+) Volt ([0-9]+)
    Log   ${matched}
    Serial Save

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




