#!/bin/bash

# C-style loop from 1 to 5
for (( i=1; i<=100; i++ ))
do
    echo "Round $i, dev 33"
    #set up variables for robot test
    robot -v prelude_id:1 -v port_l:/dev/ttyUSB6 -v port_r:/dev/ttyUSB7 -v ble_addr:33:33:33:33:33:11  ~/fw_robot_automation/test/test_freq.robot
    exitcode=$? # Save the exit code
   
   # Check the exit code
   if [ $exitcode -ne 0 ]; then
       echo "Command failed with exit code $exitcode"
       exit $exitcode   # Exit with the error code of the failed command
   fi

    echo "Round $i, dev 44"
    robot -v prelude_id:2 -v port_l:/dev/ttyUSB2 -v port_r:/dev/ttyUSB3 -v ble_addr:44:44:44:44:44:11  ~/fw_robot_automation/test/test_freq.robot
    exitcode=$?
   
   if [ $exitcode -ne 0 ]; then
       echo "Command failed with exit code $exitcode"
       exit $exitcode
   fi
done
