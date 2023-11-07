*** Setting ***
Documentation     Test cases for testing serial library
...
...               All keywords constructed from ``SerialLib.py``.
Suite Setup       
Suite Teardown    
Test Setup
Test Teardown
Default Tags      Unit
Library           ../lib/AudioLib.py

*** Test Cases ***
Audio find dev 
    ${id}=    Audio Get Dev Id
    Should Be True    ${id} > 0

Audio play a2dp 
    Audio Get Dev Id
	Audio Use A2DP
	Audio Play Simple Audio    5

Audio play hfp 
    Audio Get Dev Id
	Audio Use HFP
	Audio Play Simple Audio    5


