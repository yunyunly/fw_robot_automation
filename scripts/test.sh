#!/bin/bash
# =============================================================================
#      FileName: build.sh
#          Desc:
#        Author: Richard
#         Email:
#      HomePage:
#       Version: 0.0.1
#    LastChange:
#       History:
# =============================================================================
SOURCE_DIR=$(dirname "$BASH_SOURCE")
SOURCE_DIR=$(readlink -m $SOURCE_DIR/)

ROOT_DIR=${SOURCE_DIR}/../
TEST_CASE_DIR=${ROOT_DIR}/test
BURN_TOOL_DIR=${ROOT_DIR}/tools/dldtool

cd ${ROOT_DIR}

source scripts/board_cfg.rc
source scripts/common.rc

#NAME:function_name:robot1_name:robot2_name
SupportTestCases=(
  #TEST_SHOWN_NAME: TEST_NAME: FIRST_ROBOT_NAME: SECOND_ROBOT_NAME
  "ONLY_CHARGING:charge_ha:charge_ha"
  "BURN_TEST:burn_ha_test:test_burn_ha"
  "BASIC_TEST:basic_test:test_basic"
  "UBUNTU_BLUETOOTH_TEST:ubuntu_bluetooth_test:test_ubuntu_bluetooth"
  "ANDROID_BLUETOOTH_TEST:android_bluetooth_test:test_android_bluetooth"
  "IOS_BLUETOOTH_TEST:ios_bluetooth_test:test_ios_bluetooth"
  "BATTERY_TEST:battery_test:test_battery"
  "BURN_AND_BASIC_TEST:burn_ha_and_basic_test:test_burn_ha:test_basic"
  "BURN_AND_ANDROID_BLUETOOTH_TEST:burn_ha_and_android_bluetooth_test:test_burn_ha:test_android_bluetooth"
  "SHIPPING_MODE_TEST:shipping_mode_test:test_shipping_mode"
)

tcnt=0
for mtestcase in ${SupportTestCases[@]}; do
  ((tcnt += 1))
done

TotalChoiceCnt=$tcnt
tchoice=0
ScriptKeyStr="-DTEST_CASE"
ChooseDestTestCaseNum=
DestTestCaseStr=
DestTestFirstRobotName=
DestTestSecondRobotName=

burn_bin=
output=
name=
bt_address_suffix_l="3456789A00"
ble_address_suffix="3456789A01"

serial_logs_folder="${ROOT_DIR}/serial_logs/"

factory_file_folder="${ROOT_DIR}/tools/factory_files/"
factory_file="${ROOT_DIR}/tools/dldtool/left.bin"
program_bin="${ROOT_DIR}/tools/dldtool/programmer1600.bin"
ota_bin="${ROOT_DIR}/tools/dldtool/ota_boot_2700_20211216_5fca0c3e.bin"
factory=0

test_count=1
cleantest=0
id_list=()
pid_list=(0 0 0 0 0 0 0 0 0)
pid_list2=(0 0 0 0 0 0 0 0 0)

Usage() {
  # print_red "Error: line $1"
  echo "Usage: $0 --id #_id --test_case #_case ..."
  echo " --id #_id                                指定ID参数, para: 1-8/all"
  echo " --case #_test_case_id                    指定test_case, 具体如下："
  tcnt=0
  for mtestcase in ${SupportTestCases[@]}; do
    DestTestCaseStr=$(echo $mtestcase | cut -d: -f1)
    printf "%43d. %s\n" $tcnt $DestTestCaseStr
    ((tcnt += 1))
  done
  echo "  --count #_test_count                    指定测试次数/对于battery test代表测试小时数"
  echo "  --bin                                   指定烧录bin文件,只有在测试烧录时才会check"
  echo "  --output                                指定输出所有日志到output"
  echo "  --clean                                 清除原有测试目录"
  echo "  --factory                               工厂模式测试"
  echo "  --help                                  显示帮助信息"

  # echo or : $0 $ScriptKeyStr=\$TestCaseName ...
  exit 1
}

ManualChooseDestTestCase() {
  print_green "You need specify test case:"
  tcnt=0
  tchoice=0
  for mtestcase in ${SupportTestCases[@]}; do
    DestTestCaseStr=$(echo $mtestcase | cut -d: -f1)
    printf "%4d. %s\n" $tcnt $DestTestCaseStr
    ((tcnt += 1))
  done

  while true; do
    read -p "       Choice: " tchoice
    if [ -z "${tchoice}" ]; then
      continue
    fi
    if [ -z "${tchoice//[0-9]/}" ]; then
      if [ $tchoice -ge 0 -a $tchoice -lt $tcnt ]; then
        break
      fi
    fi
    print_red "Invalid input ..."
  done
  ChooseDestTestCaseNum=$tchoice
}

for args in $@; do
  case $args in
  --id)
    args="$2"
    if [ -z "$args" ]; then
      print_yellow "Empty input: $args"
    elif [ "$args" = "all" ]; then
      # 如果参数为"all"，则设置id_list为1到8之间的所有数字
      id_list=($(seq 1 8))
    elif [[ "$args" =~ ^[0-9]+$ && ! " ${id_list[@]} " =~ "$args" ]]; then
      if (($args < 1 || $args > 8)); then
        print_yellow "Only support test id between 1 and 8."
        print_yellow "Invalid id ${args} in id_list, please check."
        shift 2
        continue
      fi
      id_list+=("$args")
    else
      print_yellow "Invalid input: $args"
    fi
    shift 2
    ;;
  --case)
    args="$2"
    if [ -z "$args" ]; then
      print_yellow "Empty input: $args"
    elif [ ${args} -lt $TotalChoiceCnt ]; then
      ChooseDestTestCaseNum=${args}
    else
      print_yellow "Invalid input: $args"
    fi
    shift 2
    ;;
  --count)
    args="$2"
    if [ -z "$args" ]; then
      print_yellow "Empty input: $args"
    elif [[ "$args" =~ ^[0-9]+$ ]]; then
      test_count=${args}
    else
      print_yellow "Invalid input: $args"
    fi
    shift 2
    ;;
  --bin)
    args=$(realpath "$2")
    if [ -z "$args" ]; then
      print_yellow "Empty input: $args"
    elif [[ ! -f "$args" ]]; then
      print_yellow "Invalid input: $args"
    fi
    burn_bin="$args"
    shift 2
    ;;
  --output)
    args=$("pwd")/"$2"
    if [ -z "$args" ]; then
      print_yellow "Empty input: $args"
    fi
    output=$args
    shift 2
    ;;
  --factory)
    factory=1
    shift
    ;;
  --clean)
    cleantest=1
    shift
    ;;
  --help)
    Usage ${LINENO}
    shift
    ;;
  --*)
    print_red "Unrecognized para: $args, please check:"
    Usage ${LINENO}
    shift
    ;;
  esac
done

# if [ "x$ChooseDestTestCaseNum" == "x" ]; then
#   AutoChooseDestTestCase
if [ "x$ChooseDestTestCaseNum" == "x" ]; then
  ManualChooseDestTestCase
fi
#fi

tcnt=0
for mtestcase in ${SupportTestCases[@]}; do
  if [ $ChooseDestTestCaseNum -eq $tcnt ]; then
    DestTestCaseStr=$(echo $mtestcase | cut -d: -f1)
    DestTestFirstRobotName=$(echo $mtestcase | cut -d: -f3)
    DestTestSecondRobotName=$(echo $mtestcase | cut -d: -f4)
    break
  fi
  ((tcnt += 1))
done

env_prepare() {
  if [ ${#id_list[@]} -eq 0 ]; then
    print_red "Please provide at least one testing id, using --id [#id](#id supported from 1 to 8), or --id all for all devices."
    Usage ${LINENO}
    exit 1
  fi

  log_folder="${output}/logs/"
  total_folder="${output}/total/"
  summary_folder="${output}/summary/"
  serial_folder="${output}/serial_logs/"

  if [ "${ChooseDestTestCaseNum}" != 0 ]; then
    if [ -d "${output}" ]; then
      if [ "${cleantest}" = 1 ]; then
        print_yellow "Clean output: ${output}."
        rm -rf "${log_folder}"
        rm -rf "${total_folder}"
        rm -rf "${summary_folder}"
        rm -rf "${serial_folder}"

        mkdir -p ${total_folder}
        mkdir -p ${summary_folder}
        mkdir -p ${serial_folder}
      else
        print_red "Output: ${output} already exists, add --clean to use the same folder or use another folder."
        exit 1
      fi
    else
      mkdir -p "$output"
      if [ -d "$output" ]; then
        log_folder="${output}/logs/"
        total_folder="${output}/total/"
        summary_folder="${output}/summary/"
        serial_folder="${output}/serial_logs/"
        mkdir -p ${total_folder}
        mkdir -p ${summary_folder}
        mkdir -p ${serial_folder}
      else
        print_red "Can not create log dir: $output, using --output [output_dir]".
        exit 1
      fi
    fi
  fi
}

cleanup() {
  print_red "Receive ctrl+c, quit test"
  sleep 5
  for ((i = 0; i < ${#pid_list[@]}; i++)); do
    if [ "${pid_list[$i]}" -ne 0 ]; then
      kill ${pid_list[$i]}
      echo kill ${pid_list[$i]}
    fi

    if [ "${pid_list2[$i]}" -ne 0 ]; then
      kill ${pid_list2[$i]}
      echo kill ${pid_list2[$i]}
    fi
  done

}

robot_test() {
  id="$1"
  test_robot_path=${TEST_CASE_DIR}/${DestTestFirstRobotName}.robot
  if [ ! -f "$test_robot_path" ]; then
    print_red "Test file: [$test_robot_path] does not exist, Return."
    return
  fi

  if [ ! -z ${DestTestSecondRobotName} ]; then
    test_robot2_path=${TEST_CASE_DIR}/${DestTestSecondRobotName}.robot
    if [ ! -f "$test_robot2_path" ]; then
      print_red "Test file: [$test_robot2_path] does not exist, Return."
      return
    fi
  fi

  bt_id="${bt_addr_table[$id]}"
  bus_id="${bus_table[$id]}"
  dev_id="${device_table[$id]}"

  s_port_l="/dev/s_l_$bt_id"
  s_port_r="/dev/s_r_$bt_id"
  d_port_l="/dev/d_l_$bt_id"
  d_port_r="/dev/d_r_$bt_id"

  bt_address_l="${bt_id}${bt_address_suffix_l}"
  bt_address_r="${bt_id}${ble_address_suffix}"
  ble_address_l="${bt_id}${ble_address_suffix}"
  ble_address_r="${bt_id}${ble_address_suffix}"

  factory_file_l="${factory_file_folder}/factory_l_${bt_id}.bin"
  factory_file_r="${factory_file_folder}/factory_r_${bt_id}.bin"

  log_dir=${log_folder}/bt_${bt_addr_table[$id]}

  trap cleanup SIGINT

  if [ "$DestTestFirstRobotName" = "test_battery" ]; then
    output="${log_dir}/${DestTestFirstRobotName}_${bt_addr_table[$id]}_${i}.xml"
    log="${log_dir}/${DestTestFirstRobotName}_${bt_addr_table[$id]}_log_${i}.html"
    report="${log_dir}/${DestTestFirstRobotName}_${bt_addr_table[$id]}_report_${i}.html"

    robot -v test_id:${id} -v bus_id:${bus_id} -v dev_id:${dev_id} -v test_count:${test_count} -v factory_mode:${factory} \
      -v ota_bin:${ota_bin} -v program_bin:${program_bin} -v bes_bin:${burn_bin} \
      -v factory_file_l:${factory_file_l} -v factory_file_r:${factory_file_r} \
      -v s_port_l:${s_port_l} -v s_port_r:${s_port_r} -v d_port_l:${d_port_l} -v d_port_r:${d_port_r} \
      -v ble_address_l:${ble_address_l} -v ble_address_r:${ble_address_r} -v bt_address_l:${bt_address_l} \
      -v bt_address_r:${bt_address_r} --output "${output}" --log "${log}" --report "${report}" "${test_robot_path}" &
    pid_list[$id]=$!
    wait
  else
    for ((i = 1; i <= test_count; i++)); do
      if [ "$ChooseDestTestCaseNum" -eq 0 ]; then
        output="NONE"
        log="NONE"
        report="NONE"
      else
        output="${log_dir}/${DestTestFirstRobotName}_${bt_addr_table[$id]}_${i}.xml"
        log="${log_dir}/${DestTestFirstRobotName}_${bt_addr_table[$id]}_log_${i}.html"
        report="${log_dir}/${DestTestFirstRobotName}_${bt_addr_table[$id]}_report_${i}.html"
      fi

      if [ "$DestTestFirstRobotName" = "test_burn_ha" ]; then
        if [ ! -f "$burn_bin" ]; then
          print_red "Burn file: [$burn_bin] does not exist, using --bin [test_burn_bin]."
          return
        fi
      fi

      robot -v test_id:${id} -v bus_id:${bus_id} -v dev_id:${dev_id} -v test_count:${i} -v factory_mode:${factory} \
        -v ota_bin:${ota_bin} -v program_bin:${program_bin} -v bes_bin:${burn_bin} \
        -v factory_file_l:${factory_file_l} -v factory_file_r:${factory_file_r} \
        -v s_port_l:${s_port_l} -v s_port_r:${s_port_r} -v d_port_l:${d_port_l} -v d_port_r:${d_port_r} \
        -v ble_address_l:${ble_address_l} -v ble_address_r:${ble_address_r} -v bt_address_l:${bt_address_l} \
        -v bt_address_r:${bt_address_r} --output "${output}" --log "${log}" --report "${report}" "${test_robot_path}" &
      pid_list[$id]=$!
      wait
      # if [ $? -ne 0 ]; then
      #   print_red "Test Case:  ${DestTestCaseStr}"
      #   print_red "Test Fail!!!"
      #   exit 1
      # fi

      #if we have second robot test
      if [ ! -z ${DestTestSecondRobotName} ]; then
        output="${log_dir}/${DestTestSecondRobotName}_${bt_addr_table[$id]}_${i}.xml"
        log="${log_dir}/${DestTestSecondRobotName}_${bt_addr_table[$id]}_log_${i}.html"
        report="${log_dir}/${DestTestSecondRobotName}_${bt_addr_table[$id]}_report_${i}.html"

        if [ "$DestTestFirstRobotName" = "test_burn_ha" ]; then
          factory=1
        fi
        robot -v test_id:${id} -v bus_id:${bus_id} -v dev_id:${dev_id} -v test_count:${i} -v factory_mode:${factory} \
          -v s_port_l:${s_port_l} -v s_port_r:${s_port_r} -v d_port_l:${d_port_l} -v d_port_r:${d_port_r} \
          -v ble_address_l:${ble_address_l} -v ble_address_r:${ble_address_r} -v bt_address_l:${bt_address_l} \
          -v bt_address_r:${bt_address_r} --output "${output}" --log "${log}" --report "${report}" "${test_robot2_path}" &
        pid_list2[$id]=$!
        wait
        # if [ $? -ne 0 ]; then
        #   print_red "Test Case:  ${DestTestCaseStr}"
        #   print_red "Test Fail!!!"
        #   exit 1
        # fi
      else
        factory=0
      fi
    done
  fi
}

test_set() {
  for id in "${id_list[@]}"; do
    status="${status_table[$id]}"
    if [ "${status}" = 0 ]; then
      print_yellow "Deivce: $id is not set up, please check."
      continue
    fi
    robot_test $id &
  done
}

create_log() {
  if [ "${ChooseDestTestCaseNum}" != 0 ]; then
    for id in "${id_list[@]}"; do

      status="${status_table[$id]}"
      if [ "${status}" = 0 ]; then
        # echo "Deivce: $id is not set up, please check."
        continue
      fi

      log_dir=${log_folder}/bt_${bt_addr_table[$id]}
      if [ "$(ls -A ${log_dir}/*.xml)" ]; then
        cp ${log_dir}/*.xml ${total_folder}
      else
        continue
      fi

      if [ "$(ls -A ${serial_logs_folder}/*_${bt_addr_table[$id]}.txt)" ]; then
        mv ${serial_logs_folder}/*_${bt_addr_table[$id]}.txt ${serial_folder}
      fi
      func_name=$(echo ${SupportTestCases[$ChooseDestTestCaseNum]} | cut -d: -f2)
      rebot --name Combined --log ${summary_folder}/${func_name}_${bt_addr_table[$id]}_log.html --report ${summary_folder}/${func_name}_${bt_addr_table[$id]}_report.html ${log_dir}/*.xml
    done

    if [ "$(ls -A ${total_folder})" ]; then
      rebot --name Combined --log ${output}/total_log.html --report ${output}/total_report.html ${total_folder}/*.xml
    fi
    if [ ! "$(ls -A ${log_folder})" ]; then
      rm -rf ${log_folder}
    fi
    if [ ! "$(ls -A ${serial_folder})" ]; then
      rm -rf ${serial_folder}
    fi
    if [ ! "$(ls -A ${summary_folder})" ]; then
      rm -rf ${summary_folder}
    fi
    rm -rf ${total_folder}
    if [ ! "$(ls -A ${output})" ]; then
      print_red "No output in ${output}, remove the folder"
      rm -rf ${output}
    fi
  fi
}

# echo ChooseDestPlatformNum=${ChooseDestPlatformNum} >./.old_project
env_prepare
test_set
trap cleanup SIGINT
wait

print_green "All threads quit..."
create_log
echo ""
echo ""

print_green "Test Case:  ${DestTestCaseStr}"
print_green "Test Done!!!"
exit 0
