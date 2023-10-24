#!/bin/bash

# Define the input JSON configuration file
JSON_CONFIG="blue_pigeon_defs.json"

C_HEADER="blue_pigeon_defs.h"

PY_HEADER="cmd_defs.py"

rm $C_HEADER 
rm $PY_HEADER 

now=$(date +"%y-%m-%d %T")
length=$(jq -r "length" ${JSON_CONFIG})
echo "Totally " $length "Types"

# C Header 
echo "// Update Time ${now}" >> $C_HEADER
echo "#ifndef __BLUEPIGEON_DEFS_H__" >> $C_HEADER 
echo "#define __BLUEPIGEON_DEFS_H__" >> $C_HEADER 
for ((i = 0; i < $length; i++)); do
  echo "typedef enum {" >> $C_HEADER 
  type_prefix=$(jq -r "to_entries[${i}] | .key | ascii_upcase" $JSON_CONFIG)
  echo "Generating C Enum Type" ${type_prefix}"_t" 
  jq -r "to_entries[${i}] | .value | to_entries[] | \"${type_prefix}_\" + (.key | gsub(\" \"; \"_\") | ascii_upcase) + \"=\" + (.value) + \",\"" ${JSON_CONFIG} >> $C_HEADER 
  echo "} ${type_prefix}_t;" >> $C_HEADER 
done
echo "#endif // __BLUEPIGEON_DEFS_H__" >> $C_HEADER

# Python Header 
echo "# Update Time ${now}" >> $PY_HEADER
echo "from enum import Enum" >> $PY_HEADER
for ((i = 0; i < $length; i++)); do
  type_name=$(jq -r "to_entries[${i}] | .key | ascii_upcase" $JSON_CONFIG)
  echo "Generating Py Enum Class" ${type_name}
  echo "class " ${type_name} "(Enum):" >> $PY_HEADER 
  jq -r "to_entries[${i}] | .value | to_entries[] | \"    \" + (.key | gsub(\" \"; \"_\") | ascii_upcase) + \"=\" + (.value)" ${JSON_CONFIG} >> $PY_HEADER 
done


#clang-format-12 --style=LLVM -i ${OUTPUT_FILE}
