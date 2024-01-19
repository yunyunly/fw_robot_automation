#NOTE: Please modify the parameter:
#1. ble/bt address
#2. serial port 
#3. factory mode
#4. prelude id


#robot -v prelude_id:1 -t "Check Bluetooth Pairing Test" -v factory_mode:False -v test_count:5 -v s_port_l:/dev/ttyUSB6 -v s_port_r:/dev/ttyUSB7 -v d_port_l:/dev/ttyUSB2 -v d_port_r:/dev/ttyUSB3 -v ble_address_l:183456789A01 -v ble_address_r:183456789A01 -v bt_address_l:183456789A00 -v bt_address_r:183456789A01 --output ~/Testing/fw_robot_automation/logs/charging_test_18_output.xml --log ~/Testing/fw_robot_automation/logs/basic_test_18_log.html ~/Testing/fw_robot_automation/test/test_basic.robot
robot -v prelude_id:3 -v factory_mode:False -v s_port_l:/dev/ttyUSB10 -v s_port_r:/dev/ttyUSB11 -v d_port_l:/dev/ttyUSB14 -v d_port_r:/dev/ttyUSB15 -v ble_address_l:203456789A01 -v ble_address_r:203456789A01 -v bt_address_l:203456789A00 -v bt_address_r:203456789A01 --output ~/Testing/fw_robot_automation/logs/basic_test_20_output.xml --log ~/Testing/fw_robot_automation/logs/basic_test_20_log.html ~/Testing/fw_robot_automation/test/test_basic.robot
#robot --exitonfailure -v prelude_id:1 -v ble_addr:D23456789A01 -v prelude_id:1 -v port_l:/dev/ttyUSB2 -v port_r:/dev/ttyUSB3 ~/Testing/fw_robot_automation/test/test_freq.robot


#robot -v prelude_id:1 -v factory_mode:False -v port_l:/dev/ttyUSB2 -v port_r:/dev/ttyUSB3 -v ble_address_l:D23456789A01 -v ble_address_r:D23456789A01 -v bt_address_l:D23456789A00 -v bt_address_r:D23456789A01  ~/Testing/fw_robot_automation/test/test_basic.robot
#robot --exitonfailure -v prelude_id:1 -v ble_addr:D23456789A01 -v prelude_id:1 -v port_l:/dev/ttyUSB2 -v port_r:/dev/ttyUSB3 ~/Testing/fw_robot_automation/test/test_freq.robot

# robot -v prelude_id:2 -v factory_mode:False -v port_l:/dev/ttyUSB2 -v port_r:/dev/ttyUSB3 -v ble_address_l:D23456789A01 -v ble_address_r:D23456789A01 -v bt_address_l:D23456789A00 -v bt_address_r:D23456789A01  ~/Testing/fw_robot_automation/test/test_basic.robot
# robot --exitonfailure -v prelude_id:2 -v ble_addr:D23456789A01 -v prelude_id:1 -v port_l:/dev/ttyUSB2 -v port_r:/dev/ttyUSB3 ~/Testing/fw_robot_automation/test/test_freq.robot