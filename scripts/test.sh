#!/bin/bash
# set -x

test_root_folder=$(pwd)

echo "test_root_dir:${test_root_folder}"

pushd ${test_root_folder}
source ${test_root_folder}/scripts/utils.sh

# 显示帮助信息
show_help() {
  echo "Usage: $0 [--id <id>] [--次数 <次数>] [--test_case <test_case>]"
  echo "  --id #_id             指定ID参数, para: 1-8/all"
  echo "  --count #_count       指定次数参数"
  echo "  --test_suite          指定test_suite参数, para: 
                                0(onlycharging)
                                1(burning)
                                2(basic test) 
                                4(bluetooth test), 
                                8(ios bluetooth test)"
  echo "  --bin                 指定烧录bin文件,只有在测试烧录时才会check"
  echo "  --output              输出所有日志到output"
  echo "  --clean               清除所有测试日志"
  echo "  --factory             工厂模式测试"
  echo "  --help                显示帮助信息"
  exit 0
}


bin=
output=
name=
bt_address_suffix_l="3456789A00"
ble_address_suffix="3456789A01"

serial_logs_folder="${test_root_folder}/serial_logs/"
factory_file_folder="${test_root_folder}/tools/factory_files/"

factory_file="${test_root_folder}/tools/dldtool/left.bin"
program_bin="${test_root_folder}/tools/dldtool/programmer1600.bin"
ota_bin="${test_root_folder}/tools/dldtool/ota_boot_2700_20211216_5fca0c3e.bin"
output_folder="${test_root_folder}/logs/"


#test_path
charge_ha_robot_path="${test_root_folder}/test/charge_ha.robot"
burn_ha_robot_path="${test_root_folder}/test/test_burn_ha.robot"
basic_test_robot_path="${test_root_folder}/test/test_basic.robot"
bluetooth_test_robot_path="${test_root_folder}/test/test_freq.robot"
ios_connect_robot_path="${test_root_folder}/test/test_ios_connect_setup.robot"

factory=0
count=1
cleantest=0
onlycharging=0
id_list=()
pid_list=(0 0 0 0 0 0 0 0 0)
# quit=(0 0 0 0 0 0 0 0 0)

test_suite=0

# 检查是否有参数
if [ $# -eq 0 ]; then
  show_help
fi

# 解析命令行参数
while [ "$#" -gt 0 ]; do
  case "$1" in
    --id)
      id="$2"
      if [ -z "$id" ]; then
        echo "Please provide testing id"
      else 
        if [ "$id" = "all" ]; then
        # 如果参数为"all"，则设置id_list为1到8之间的所有数字
          id_list=($(seq 1 8))
        elif [[ "$id" =~ ^[0-9]+$  &&  ! " ${id_list[@]} " =~ "$id" ]]; then
          if (( $id < 1 || $id > 8 )); then
            echo "Only support test id between 1 and 8."
            echo "Invalid id ${id} in id_list, please check."
            shift 2
            continue;
          fi 
          id_list+=("$id")
        else
          echo "Empty id: "${id} 
        fi
      fi
      shift 2
      ;;
    --count)
      count="$2"
      if [ -z "$count" ]; then
        echo "Please provide testing count"
        exit 1
      fi
      shift 2
      ;;
    --test_suite)
      if (( "$2" < 0 || "$2" > 8 )); then
            echo "Only support test suite between 0 and 8."
            echo "Invalid suite id ${$2}, please check."
            shift 2
            continue;
      fi 
      test_suite="$2"
      shift 2
      ;; 
    --bin)
      bin=$(readlink -f "$2")
      if [ ! -e "${bin}" ]; then
          echo "Bes_bin: ${bin} does not exist."
          exit 1
      fi
      shift 2
      ;;
    --output)
      output=$(readlink -f "$2")
      if [ ! -n "${output}" ]; then
          echo "Output: ${output} empty."
          exit 1
      fi
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
      show_help
      ;;
    *)
      echo "Unknown option: $1"
      show_help
      ;;
  esac
done


if [ ${#id_list[@]} -eq 0 ]; then
  echo "Please provide at least one testing id"
  exit 1
fi

if [ "${test_suite}" != 0 ];then 
  if [ -d "${output}" ]; then
    if [ "${cleantest}" = 1 ]; then 
      echo "Clean output: ${output}."
      rm -rf "${output}"
    else  
      echo "Output: ${output} already exists."
      exit 1
    fi
  fi

  mkdir -p "$output"

  if [ -d "$output" ]; then
    output_folder="${output}/logs/"
    total_folder="${output}/total/"
    summary_folder="${output}/summary/"
    serial_folder="${output}/serial_logs/"
    mkdir -p ${total_folder}
    mkdir -p ${summary_folder}
    mkdir -p ${serial_folder}
  else 
    echo "Can not create output folder".
    exit 1
  fi
fi

charging_ha()
{
  id="$1"
  bus_id="${bus_table[$id]}"
  dev_id="${device_table[$id]}"
  robot -v test_id:${id} -v bus_id:${bus_id} -v dev_id:${dev_id} "${charge_ha_robot_path}"
}

burn_ha_test()
{
  name="burn_ha_test"
  id="$1"
  bes_bin="$2" 
  #check if valid bin 
  if [ ! -f "$bes_bin" ]; then
    echo "Burn file: [$bes_bin] does not exist, Exit."
    exit
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

  # factory_file_l="${factory_file}"
  # factory_file_r="${factory_file}" 
  log_dir=${output_folder}/bt_${bt_addr_table[$id]}

  for ((i=1; i<=count; i++)); do
    echo test count: ${i}:${count}

    output="${log_dir}/burn_ha_test_${bt_addr_table[$id]}_${i}.xml"
    log="${log_dir}/burn_ha_test_${bt_addr_table[$id]}_${i}.html"

    robot -v test_id:${id} -v bus_id:${bus_id} -v dev_id:${dev_id}  -v port_l:${s_port_l} -v port_r:${s_port_r} -v d_port_l:${d_port_l} -v d_port_r:${d_port_r} \
    -v factory_file_l:${factory_file_l} -v factory_file_r:${factory_file_r} -v ota_bin:${ota_bin} -v program_bin:${program_bin} -v bes_bin:${bes_bin} --output "${output}" --log "${log}" "${burn_ha_robot_path}"

  done
}

basic_test()
{
  id="$1"

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

  log_dir=${output_folder}/bt_${bt_addr_table[$id]}
    
  for ((i=1; i<=count; i++)); do
      # echo  "${quit[$id]}"
      # if [ "${quit[$id]}" -eq 1 ]; then
      #   echo "break"
      #   break
      # fi
      echo test count: ${i}:${count}
      if [ $i -gt 1 ]; then
        factory=0
      fi
      output="${log_dir}/basic_test_${bt_addr_table[$id]}_${i}.xml"
      log="${log_dir}/basic_test_${bt_addr_table[$id]}_${i}.html"

      robot -v factory_mode:${factory} -v test_id:${id} -v bus_id:${bus_id} -v dev_id:${dev_id} -v s_port_l:${s_port_l} -v s_port_r:${s_port_r} -v d_port_l:${d_port_l} -v d_port_r:${d_port_r} \
      -v ble_address_l:${ble_address_l} -v ble_address_r:${ble_address_r} -v bt_address_l:${bt_address_l} -v bt_address_r:${bt_address_r} \
      --output "${output}" --log "${log}" "${basic_test_robot_path}"
  done
}

bluetooth_test()
{
  name="bluetooth_test"
  id="$1"

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

  log_dir=${output_folder}/bt_${bt_addr_table[$id]}
    
  for ((i=1; i<=count; i++)); do
      echo test count: ${i}:${count}
      output="${log_dir}/${name}_${bt_addr_table[$id]}_${i}.xml"
      log="${log_dir}/${name}_${bt_addr_table[$id]}_${i}_log.html"
      report="${log_dir}/${name}_${bt_addr_table[$id]}_${i}_report.html"

      robot -v test_id:${id} -v bus_id:${bus_id} -v dev_id:${dev_id} -v s_port_l:${s_port_l} -v s_port_r:${s_port_r} -v d_port_l:${d_port_l} -v d_port_r:${d_port_r} \
      -v ble_address_l:${ble_address_l} -v ble_address_r:${ble_address_r} -v bt_address_l:${bt_address_l} -v bt_address_r:${bt_address_r} \
      --output "${output}" --log "${log}" --report "${report}" "${bluetooth_test_robot_path}"
  done
}

burn_ha_and_basic_test()
{
  id="$1"
  bes_bin="$2" 

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

  log_dir=${output_folder}/bt_${bt_addr_table[$id]}
    
  for ((i=1; i<=count; i++)); do
      echo test count: ${i}:${count}

      output="${log_dir}/burn_ha_test_${bt_addr_table[$id]}_${i}.xml"
      log="${log_dir}/burn_ha_test_${bt_addr_table[$id]}_${i}.html"

      robot -v test_id:${id} -v bus_id:${bus_id} -v dev_id:${dev_id}  -v port_l:${s_port_l} -v port_r:${s_port_r} -v d_port_l:${d_port_l} -v d_port_r:${d_port_r} \
      -v factory_file_l:${factory_file_l} -v factory_file_r:${factory_file_r} -v ota_bin:${ota_bin} -v program_bin:${program_bin} -v bes_bin:${bes_bin} --output "${output}" --log "${log}" "${burn_ha_robot_path}"

      output="${log_dir}/basic_test_${bt_addr_table[$id]}_${i}.xml"
      log="${log_dir}/basic_test_${bt_addr_table[$id]}_${i}.html"

      robot -v test_id:${id} -v factory_mode:1 -v bus_id:${bus_id} -v dev_id:${dev_id} -v s_port_l:${s_port_l} -v s_port_r:${s_port_r} -v d_port_l:${d_port_l} -v d_port_r:${d_port_r} \
      -v ble_address_l:${ble_address_l} -v ble_address_r:${ble_address_r} -v bt_address_l:${bt_address_l} -v bt_address_r:${bt_address_r} \
      --output "${output}" --log "${log}" "${basic_test_robot_path}"

  done
}

ios_bluetooth_test()
{
  id="$1"

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

  log_dir=${output_folder}/bt_${bt_addr_table[$id]}
    
  # for ((i=1; i<=count; i++)); do
      # echo test count: ${i}:${count}

  output="${log_dir}/ios_bluetooth_test_${bt_addr_table[$id]}.xml"
  log="${log_dir}/ios_bluetooth_test_${bt_addr_table[$id]}_log.html"
  report="${log_dir}/ios_bluetooth_test_${bt_addr_table[$id]}_report.html"

  robot -v test_id:${id} -v count:${count} -v bus_id:${bus_id} -v dev_id:${dev_id}  -v s_port_l:${s_port_l} -v s_port_r:${s_port_r} -v d_port_l:${d_port_l} -v d_port_r:${d_port_r} \
  -v ble_address_l:${ble_address_l} -v ble_address_r:${ble_address_r} -v bt_address_l:${bt_address_l} -v bt_address_r:${bt_address_r} \
  --output "${output}" --log "${log}" --report "${report}" "${ios_connect_robot_path}"

  # done
}

all_test()
{
  id="$1"
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

  log_dir=${output_folder}/bt_${bt_addr_table[$id]}
    
  for ((i=1; i<=count; i++)); do
      echo test count: ${i}:${count}

      output="${log_dir}/burn_ha_test_${bt_addr_table[$id]}_${i}.xml"
      log="${log_dir}/burn_ha_test_${bt_addr_table[$id]}_${i}.html"

      robot -v test_id:${id} -v bus_id:${bus_id} -v dev_id:${dev_id}  -v port_l:${s_port_l} -v port_r:${s_port_r} -v d_port_l:${d_port_l} -v d_port_r:${d_port_r} \
      -v factory_file_l:${factory_file_l} -v factory_file_r:${factory_file_r} -v ota_bin:${ota_bin} -v program_bin:${program_bin} -v bes_bin:${bes_bin} --output "${output}" --log "${log}" "${burn_ha_robot_path}"

      output="${log_dir}/basic_test_${bt_addr_table[$id]}_${i}.xml"
      log="${log_dir}/basic_test_${bt_addr_table[$id]}_${i}.html"

      robot -v test_id:${id} -v factory_mode:1 -v bus_id:${bus_id} -v dev_id:${dev_id} -v s_port_l:${s_port_l} -v s_port_r:${s_port_r} -v d_port_l:${d_port_l} -v d_port_r:${d_port_r} \
      -v ble_address_l:${ble_address_l} -v ble_address_r:${ble_address_r} -v bt_address_l:${bt_address_l} -v bt_address_r:${bt_address_r} \
      --output "${output}" --log "${log}" "${basic_test_robot_path}"

      output="${log_dir}/bluetooth_test_${bt_addr_table[$id]}_${i}.xml"
      log="${log_dir}/bluetooth_test_${bt_addr_table[$id]}_${i}.html"

      robot -v test_id:${id} -v bus_id:${bus_id} -v dev_id:${dev_id} -v s_port_l:${s_port_l} -v s_port_r:${s_port_r} -v d_port_l:${d_port_l} -v d_port_r:${d_port_r} \
      -v ble_address_r:${ble_address_r} -v bt_address_l:${bt_address_l} -v bt_address_r:${bt_address_r} --output "${output}" --log "${log}" "${bluetooth_test_robot_path}"

  done
}


for id in "${id_list[@]}"; do
  status="${status_table[$id]}"   
  if [ "${status}" = 0 ]; then
    echo "Deivce: $id is not set up, please check."
    continue;
  fi

  log_dir=${output_folder}/bt_${bt_addr_table[$id]}
  # if [ "${cleantest}" = 1 ] && ; then
  #     echo "Clean Test"
  #     rm -rf ${serial_logs_folder}/*.txt
  #     rm -rf ${output_folder}/*.html
  #     rm -rf ${output_folder}/*.xml
  #     rm -rf ${log_dir}
  #     mkdir ${log_dir}
  # fi

  if [ "${test_suite}" = 0 ]; then          #only charging 
    name="charging_ha"
    charging_ha "$id" &
  elif [ "${test_suite}" = 1 ]; then        #burning 
    #check if valid bin 
    if [ ! -f "$bin" ]; then
      echo "Burn file: [$bin] does not exist, Exit."
      exit
    fi 
    burn_ha_test "$id" "$bin" &
    name="burn_ha_test"
    pid_list[$id]=$!
  elif [ "${test_suite}" = 2 ]; then        #basic test
    basic_test "$id" &
    name="basic_test"
    pid_list[$id]=$!
  elif [ "${test_suite}" = 3 ]; then        #burning+basic_test 
    if [ ! -f "$bin" ]; then
      echo "Burn file: [$bin] does not exist, Exit."
      exit
    fi 
    burn_ha_and_basic_test "$id" "$bin" &
    name="burn_ha_and_basic_test"
    pid_list[$id]=$!
  elif [ "${test_suite}" = 4 ]; then        #freq test
    name="bluetooth_test"
    bluetooth_test "$id" &
    pid_list[$id]=$!
  # elif [ "${test_suite}" = 5 ]; then        #burnin+freq_test
  # elif [ "${test_suite}" = 6 ]; then        #basic_test+freq_test
  # elif [ "${test_suite}" = 7 ]; then        #all
  #   if [ ! -f "$bin" ]; then
  #     echo "Burn file: [$bin] does not exist, Exit."
  #     exit
  #   fi 
  #   name="all_test"
  #   all_test "$id" "$bin" &
  #   pid_list[$id]=$!
  elif [ "${test_suite}" = 8 ]; then        #all
    name="ios_bluetooth_test"
    ios_bluetooth_test "$id" &
    pid_list[$id]=$!
  fi
done

cleanup() {
    echo "Receive ctrl+c, quit test"
    for ((i = 0; i < ${#pid_list[@]}; i++)); do
        if [ "${pid_list[$i]}" -ne 0 ]; then
            # quit[$i]=1
            kill ${pid_list[$i]}
            echo kill ${pid_list[$i]}
        fi
    done
}

trap cleanup SIGINT

wait 

echo "All threads quit..."

sleep 5

if [ "${test_suite}" != 0 ];then 
  for id in "${id_list[@]}"; do

    status="${status_table[$id]}"   
    if [ "${status}" = 0 ]; then
      # echo "Deivce: $id is not set up, please check."
      continue;
    fi
    
    log_dir=${output_folder}/bt_${bt_addr_table[$id]}
    cp ${log_dir}/*.xml ${total_folder}

    if [ "$(ls -A ${serial_logs_folder}/*_${bt_addr_table[$id]}.txt)" ]; then
      mv ${serial_logs_folder}/*_${bt_addr_table[$id]}.txt ${serial_folder}
    fi
    rebot --name Combined --log ${summary_folder}/${name}_${bt_addr_table[$id]}_log.html --report ${summary_folder}/${name}_${bt_addr_table[$id]}_report.html ${log_dir}/*.xml
  done 
  
  if [ "$(ls -A ${total_folder})" ]; then
    rebot --name Combined --log ${output}/total_log.html --report ${output}/total_report.html ${total_folder}/*.xml
  fi
  rm -rf  ${total_folder}
fi

popd

echo "Test Done!!!"
