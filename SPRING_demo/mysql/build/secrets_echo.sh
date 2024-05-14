#!/bin/bash 
echo "DB_UNAME is $DB_UNAME"
echo "DB_PWD is $DB_PWD"
read -n1 -r -p "Press space to continue..." key
set -x
mysql -h $DB_URL -u $DB_UNAME --password=$DB_PWD petclinic
