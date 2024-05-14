#!/bin/bash
source app.config
set -x
result=$(/opt/CARKaim/sdk/clipasswordsdk GetPassword	 \
	-p AppDescs.CredFilePath=/demo/cp/javacp.cred	 \
	-p Query="Safe=$SAFE;Folder=Root;Object=$OBJECT" \
	-p RequiredProps=Address,UserName 		 \
	-o Password,PassProps.Address,PassProps.UserName)
set +x
echo
echo "Result: $result"
echo
