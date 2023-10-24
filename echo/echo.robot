*** Settings ***
Library           ${CURDIR}/../lib/ChargingCaseLib.py
Library           ${CURDIR}/../lib/SerialLib.py
Suite Setup       Connect Charging Case    D0:14:11:20:20:18
Suite Teardown    Disconnect Charging Case 
Test Setup        Open Serial Port    /dev/ttyACM0    115200
Test Teardown     Close Serial Port


*** Test Cases ***
Print information
    Print Info
    ${matched}=   Serial Read Until Regex  SOC ([0-9]+) Volt ([0-9]+) Curr ([\\+\\-]?[0-9]+\\.[0-9]+) Temp ([\\+\\-]?[0-9]+) Charge ([0-9]+) 
    ${soc}=  Set Variable   ${matched}[0]
    ${volt}=  Set Variable  ${matched}[1]
    ${curr}=  Set Variable  ${matched}[2]
    ${temp}=  Set Variable  ${matched}[3]
    ${charge}=  Set Variable  ${matched}[4]
    IF  ${charge} == 1 
      Should Be True  ${curr} >= 0 
    ELSE 
      Should Be True  ${curr} < 0
    END 
    Should Be True     ${soc} >= 0 and ${soc} <= 100
    Serial Save

Case open 
    Case Open 
    ${status}=  Serial Read Until Regex   Robot: case ([a-zA-Z]+)
    Should Be Equal   ${status}   open    
    Serial Save

Case close 
    Case Close 
    ${status}=  Serial Read Until Regex   Robot: case ([a-zA-Z]+)
    Should Be Equal   ${status}   close 

Charger plug in 
    Plug In 
    ${status}=  Serial Read Until Regex   Robot: vin plug ([a-zA-Z]+)
    Should Be Equal   ${status}   in   

Charger plug out
    Plug Out 
    ${status}=  Serial Read Until Regex   Robot: vin plug ([a-zA-Z]+)
    Should Be Equal   ${status}   out 


Case connect hearing aids 
    Case Connect Hearing Aids 
    ${status}=  Serial Read Until Regex    Robot: ([a-zA-Z]+) ha 
    Should Be Equal   ${status}   connect 

Case disconnect hearing aids 
    Case Disconnect Hearing Aids 
    ${status}=  Serial Read Until Regex     Robot: ([a-zA-Z]+) ha 
    Should Be Equal   ${status}   disconnect 

Case start charge hearing aids 
    Charging Hearing Aids  Left 
    ${status}=  Serial Read Until Regex     Robot: do charge ([a-zA-Z]+)  
    Should Be Equal   ${status}   left
    Charging Hearing Aids  Right 
    ${status}=  Serial Read Until Regex     Robot: do charge ([a-zA-Z]+)  
    Should Be Equal   ${status}   right 
    Charging Hearing Aids  Both 
    ${status}=  Serial Read Until Regex     Robot: do charge ([a-zA-Z]+)  
    Should Be Equal   ${status}   both 

Case stop charge hearing aids 
    Charging Hearing Aids Stop  Left 
    ${status}=  Serial Read Until Regex     Robot: stop charge ([a-zA-Z]+)  
    Should Be Equal   ${status}   left
    Charging Hearing Aids Stop   Right 
    ${status}=  Serial Read Until Regex     Robot: stop charge ([a-zA-Z]+)  
    Should Be Equal   ${status}   right 
    Charging Hearing Aids Stop  Both 
    ${status}=  Serial Read Until Regex     Robot: stop charge ([a-zA-Z]+)  
    Should Be Equal   ${status}   both 

Case dock 
    Dock  Left 
    ${status}=  Serial Read Until Regex     Robot: dock ([a-zA-Z]+)  
    Should Be Equal   ${status}   left
    Dock   Right 
    ${status}=  Serial Read Until Regex     Robot: dock ([a-zA-Z]+)  
    Should Be Equal   ${status}   right 
    Dock  Both 
    ${status}=  Serial Read Until Regex     Robot: dock ([a-zA-Z]+)  
    Should Be Equal   ${status}   both 

Case undock 
    Undock  Left 
    ${status}=  Serial Read Until Regex     Robot: undock ([a-zA-Z]+)  
    Should Be Equal   ${status}   left
    Undock   Right 
    ${status}=  Serial Read Until Regex     Robot: undock ([a-zA-Z]+)  
    Should Be Equal   ${status}   right 
    Undock  Both 
    ${status}=  Serial Read Until Regex     Robot: undock ([a-zA-Z]+)  
    Should Be Equal   ${status}   both 

Press button 
    Press Button Fn  
    ${status}=  Serial Read Until Regex     Robot: Press ([a-zA-Z]+)  
    Should Be Equal   ${status}   fn
    Press Button  Fn  Long 
    ${status}=  Serial Read Until Regex     Robot: Press ([a-zA-Z]+)  
    Should Be Equal   ${status}   fnlong 
    Press Button  Reset
    ${status}=  Serial Read Until Regex     Robot: Press ([a-zA-Z]+)  
    Should Be Equal   ${status}   rst 
    Press Button  Reset   Long 
    ${status}=  Serial Read Until Regex     Robot: Press ([a-zA-Z]+)  
    Should Be Equal   ${status}   rstlong
    Press Button  Left
    ${status}=  Serial Read Until Regex     Robot: Press ([a-zA-Z]+)  
    Should Be Equal   ${status}   left 
    Press Button  Right
    ${status}=  Serial Read Until Regex     Robot: Press ([a-zA-Z]+)  
    Should Be Equal   ${status}   right 

Pulse 
  Generate Pulse  Left
  ${status}=  Serial Read Until Regex     Robot: pluse ([a-zA-Z]+)  
  Should Be Equal   ${status}   left 
  Generate Pulse  Right
  ${status}=  Serial Read Until Regex     Robot: pluse ([a-zA-Z]+)  
  Should Be Equal   ${status}   right 
  Generate Pulse  Both
  ${status}=  Serial Read Until Regex     Robot: pluse ([a-zA-Z]+)  
  Should Be Equal   ${status}   both

Soc
  Request Hearing Aids Soc  Left
  ${status}=  Serial Read Until Regex     Robot: soc ([a-zA-Z]+)  
  Should Be Equal   ${status}   left 
  Request Hearing Aids Soc  Right
  ${status}=  Serial Read Until Regex     Robot: soc ([a-zA-Z]+)  
  Should Be Equal   ${status}   right 
  Request Hearing AIds Soc  Both
  ${status}=  Serial Read Until Regex     Robot: soc ([a-zA-Z]+)  
  Should Be Equal   ${status}   both

Single wire
  Single Wire Send  Left  01ff00
  ${status}=  Serial Read Until Regex     Robot: uart snd ([a-zA-Z]+) ([0-9a-f]+)  
  Should Be Equal   ${status}[0]  left  
  Should Be Equal   ${status}[1]  01ff00 
  Single Wire Send  Right  01ff00
  ${status}=  Serial Read Until Regex     Robot: uart snd ([a-zA-Z]+) ([0-9a-f]+)  
  Should Be Equal   ${status}[0]  right  
  Should Be Equal   ${status}[1]  01ff00 
  Single Wire Send  Both  01ff00
  ${status}=  Serial Read Until Regex     Robot: uart snd ([a-zA-Z]+) ([0-9a-f]+)  
  Should Be Equal   ${status}[0]  both  
  Should Be Equal   ${status}[1]  01ff00 
  Single Wire Request  Left  01ff00
  ${status}=  Serial Read Until Regex     Robot: uart req ([a-zA-Z]+) ([0-9a-f]+)  
  Should Be Equal   ${status}[0]  left  
  Should Be Equal   ${status}[1]  01ff00 
  Single Wire Request  Right  01ff00
  ${status}=  Serial Read Until Regex     Robot: uart req ([a-zA-Z]+) ([0-9a-f]+)  
  Should Be Equal   ${status}[0]  right  
  Should Be Equal   ${status}[1]  01ff00 
  Single Wire Request  Both  01ff00
  ${status}=  Serial Read Until Regex     Robot: uart req ([a-zA-Z]+) ([0-9a-f]+)  
  Should Be Equal   ${status}[0]  both  
  Should Be Equal   ${status}[1]  01ff00  


