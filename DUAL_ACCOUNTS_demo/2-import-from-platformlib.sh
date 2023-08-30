#!/bin/bash

source ./env-vars.sh

main() {
  if [[ $# = 0 ]]; then
    echo -n "Enter Platform ID in platformlib to import: "
    read PLATFORM_ID
  else
    PLATFORM_ID=$1
  fi
  PLATFORM_FILENAME_ROOT=""
  find_platform_files
  if [[ "$PLATFORM_FILENAME_ROOT" != "" ]]; then
    echo import_platform $PLATFORM_FILENAME_ROOT
  else
    echo "Platform files for PlatformID $PLATFORM_ID not found in ./platformlib/"
    echo
    ./1-list-platform-library.sh
  fi
}

#####################################
find_platform_files() {
  cd ./platformlib
    INI_FILES=$(ls *.ini)
    PLATFORM_FILENAME_ROOT=""
    for iniFile in $INI_FILES; do
      filenameRoot=$(echo $iniFile | cut -d '.' -f 1)
      platformId=$(cat $iniFile | grep -v ^\; | grep PolicyID | cut -d '=' -f 2 | awk '{print $1}')
      if [[ "$platformId" == "$PLATFORM_ID" ]]; then
        PLATFORM_FILENAME_ROOT=$filenameRoot
        break
      fi
    done
  cd ..
}

#####################################
import_platform() {
  # clear import directory
  rm -f ./for_import/*

  # copy platform files 
  cp ./platformlib/$PLATFORM_FILENAME_ROOT.* ./for_import

  # create zipfile - cd into directory because vault does not like path prefixes in zipfile
  cd ./for_import	
    zip $PLATFORM_ID.zip $PLATFORM_FILENAME_ROOT.*
  cd ..

  ./cybrvault-cli.sh platform_import ./for_import/$PLATFORM_ID.zip
}

main "$@"
