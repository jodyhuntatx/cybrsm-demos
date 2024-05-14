#!/bin/bash

echo "Files in ./platformlib/"
echo "======================================"
ls ./platformlib
echo "======================================"
echo
echo "Platform IDs in ./platformlib/"
echo "======================================"
cd ./platformlib
INI_FILES=$(ls *.ini)
for iniFile in $INI_FILES; do
  xmlFile=$(echo $iniFile | cut -d '.' -f 1).xml
  platformId=$(cat $iniFile | grep -v ^\; | grep PolicyID | cut -d '=' -f 2 | awk '{print $1}')
  systemType=$(cat $xmlFile | grep "Device Name" | cut -d '=' -f 2 | awk '{print $1}' | tr -cd '[:alnum:]-_')
  echo "PlatformID: $platformId		SystemType: $systemType"
done

