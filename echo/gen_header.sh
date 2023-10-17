#!/bin/bash

# Define the input JSON configuration file
JSON_CONFIG="bluepigeon_defs.json"

OUTPUT_FILE="bluepigeon_defs.h"

rm $OUTPUT_FILE

length=$(jq -r "length" ${JSON_CONFIG})
echo "length is " $length

echo "#ifndef __BLUEPIGEON_DEFS_H__" >> $OUTPUT_FILE
echo "#define __BLUEPIGEON_DEFS_H__" >> $OUTPUT_FILE
for ((i = 0; i < $length; i++)); do
  echo "typedef enum {" >> $OUTPUT_FILE
  type_prefix=$(jq -r "to_entries[${i}] | .key | ascii_upcase" $JSON_CONFIG)
  echo "type prefix is " ${type_prefix}
  jq -r "to_entries[${i}] | .value | to_entries[] | \"${type_prefix}_\" + (.key | gsub(\" \"; \"_\") | ascii_upcase) + \"=\" + (.value) + \",\"" ${JSON_CONFIG} >> $OUTPUT_FILE
  echo "} ${type_prefix}_t;" >> $OUTPUT_FILE
done

echo "#endif // __BLUEPIGEON_DEFS_H__" >> $OUTPUT_FILE

clang-format-12 --style=LLVM -i ${OUTPUT_FILE}
