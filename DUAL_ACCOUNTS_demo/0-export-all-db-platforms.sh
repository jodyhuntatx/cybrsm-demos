#!/bin/bash

# Example of how to automate export of all platforms of systemType Database

source ./demo-vars.sh

# Get all Platform Ids of systemType Database
PLATFORM_IDS=$(./pcloud-cli.sh platforms_get | jq -r '.Platforms[] | select(.general.systemType=="Database").general.id')

for platId in $PLATFORM_IDS; do
  echo "Exporting $platId..."
  ./pcloud-cli.sh platform_export $platId ./export/$platId.zip
done

exit

####################################
# Other useful queries

# Get all Platform Names
#./pcloud-cli.sh platforms_get | jq -r '.Platforms[].general.name'

# Get all Platform systemTypes 

#./pcloud-cli.sh platforms_get | jq -r '[.Platforms[].general.systemType] | unique | .[]'
			# jq explainer: put all systemTypes in array, uniqueify, return elements of uniqueified array
