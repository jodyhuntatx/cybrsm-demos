#!/bin/bash

# Automated export of all platforms of systemType Database

source ./env-vars.sh

mkdir -p ./exported_zipfiles

echo "Platform system types in vault:"
./cybrvault-cli.sh platforms_get | jq -r '[.Platforms[].general.systemType] | unique | .[]'
			# jq explainer: put all systemTypes in array, uniqueify, return elements of uniqueified array
echo
echo


SYSTEMTYPE=Database

echo "Exporting all Platform Ids of systemType $SYSTEMTYPE:"
printf -v query '.Platforms[] | select(.general.systemType=="%s")' $SYSTEMTYPE
PLATFORM_IDS=$(./cybrvault-cli.sh platforms_get | jq -r "$query")

echo $PLATFORM_IDS

exit

for platId in $PLATFORM_IDS; do
  echo "Exporting $platId..."
  ./cybrvault-cli.sh platform_export $platId ./exported_zipfiles/$platId.zip
done

exit

####################################
# Other useful queries

# Get all Platform Names
#./cybrvault-cli.sh platforms_get | jq -r '.Platforms[].general.name'

