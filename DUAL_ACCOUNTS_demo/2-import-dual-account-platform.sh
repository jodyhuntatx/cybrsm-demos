#!/bin/bash

source ./demo-vars.sh

main() {
  if [[ $# != 1 ]]; then
    show_usage
  fi
  PLATFORM_ID=$1
  PLATFORM_FILENAME_ROOT=""
  find_platform_files
  if [[ "$PLATFORM_FILENAME_ROOT" != "" ]]; then
    echo import_platform $PLATFORM_FILENAME_ROOT
  else
    echo "Platform files for PlatformID $PLATFORM_ID not found in ./templates."
    echo "Supported Dual Account platforms:"
    ./list-dual-account-platforms.sh
  fi
}

#####################################
show_usage() {
  echo "Usage: $0 <dual-account-platform-id>"
  echo " Run 1-list-dual-account-platforms.sh to see a list of platforms for import."
  exit -1
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

  # create zipfile - Import does not like path prefixes in zipfile
  cd ./for_import	
    zip $PLATFORM_ID.zip $PLATFORM_FILENAME_ROOT.*
  cd ..

  ./pcloud-cli.sh platform_import ./for_import/$PLATFORM_ID.zip
}

main "$@"
