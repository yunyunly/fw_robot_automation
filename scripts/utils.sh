# utils.sh

#!/bin/bash


# 定义关联数组（查询表格）
# declare -A prelude_id_table
# prelude_id_table[0]=2
# prelude_id_table[1]=4
# prelude_id_table[2]=6
# prelude_id_table[3]=1
# prelude_id_table[4]=4

#############################DEFINITION OF BOARDs#######################################
#   test_device_num   #     bus/device    #    bt_address    #    Status      
#   01                #     01/xx         #    19            #    On
#   02                #     01/xx         #    24            #    On
#   03                #     01/xx         #    11            #    Off 
#   04                #     01/xx         #    18            #    On
#   05                #     01/xx         #    20            #    On
#   06                #     01/xx         #    21            #    On 
#   07                #     01/xx         #    16            #    On 
#   08                #     01/xx         #    23            #    Off
########################################################################################

declare -A test_device_num_table
test_device_num_table[1]=1
test_device_num_table[2]=2
test_device_num_table[3]=3
test_device_num_table[4]=4
test_device_num_table[5]=5
test_device_num_table[6]=6
test_device_num_table[7]=7
test_device_num_table[8]=8

declare -A bus_table
bus_table[1]=1
bus_table[2]=1
bus_table[3]=1
bus_table[4]=1
bus_table[5]=1
bus_table[6]=1
bus_table[7]=1
bus_table[8]=1

declare -A device_table
device_table[1]=93
device_table[2]=91
device_table[3]=89
device_table[4]=87
device_table[5]=85
device_table[6]=83
device_table[7]=81
device_table[8]=79

declare -A bt_addr_table
bt_addr_table[1]=19
bt_addr_table[2]=24
bt_addr_table[3]=11
bt_addr_table[4]=18
bt_addr_table[5]=20
bt_addr_table[6]=21
bt_addr_table[7]=16
bt_addr_table[8]=23

declare -A status_table
status_table[1]=1
status_table[2]=1
status_table[3]=1
status_table[4]=1
status_table[5]=1
status_table[6]=0
status_table[7]=1
status_table[8]=0
# declare -A s_port_l_table
# s_port_l_table[0]="/dev/ttyUSB6"
# s_port_l_table[1]="/dev/ttyUSB13"
# s_port_l_table[2]="/dev/ttyUSB20"

# declare -A s_port_r_table
# s_port_r_table[0]="/dev/ttyUSB7"
# s_port_r_table[1]="/dev/ttyUSB14"
# s_port_r_table[2]="/dev/ttyUSB21"

# declare -A d_port_l_table
# d_port_l_table[0]="/dev/ttyUSB2"
# d_port_l_table[1]="/dev/ttyUSB9"
# d_port_l_table[2]="/dev/ttyUSB16"

# declare -A d_port_r_table
# d_port_r_table[0]="/dev/ttyUSB3"
# d_port_r_table[1]="/dev/ttyUSB10"
# d_port_r_table[2]="/dev/ttyUSB17"
