#!/bin/bash
CCP_HOST=$(echo $1 | cut  -d : -f 1)
APP_ID=$(echo $1 | cut -d : -f 2)
SAFE=$(echo $1 | cut -d : -f 3)
OBJECT=$(echo $1 | cut -d : -f 4)
PROPERTY=$(echo $1 | cut -d : -f 5)
case $PROPERTY in
  username|Username|UserName)
	PROPERTY="UserName"
	;;
  password|Password|PassWord|content|Content)
	PROPERTY="Content"
	;;
  *)
	>&2 echo "If error, ensure PROPERTY \"$PROPERTY\" is spelled correctly."
esac

echo $(curl -sk "https://$CCP_HOST/AIMWebService/api/Accounts?AppID=$APP_ID&Query=Safe=$SAFE;Object=$OBJECT" | jq -r .$PROPERTY)
