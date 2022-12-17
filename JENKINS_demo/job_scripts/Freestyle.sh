echo "Freestyle shell step:"
echo -n DB_UNAME=
echo $DB_UNAME | sed 's/./& /g'
echo -n DB_PWD=
echo $DB_PWD | sed 's/./& /g'
