#!/bin/bash
for i in $(env | grep AWS); do
  echo $i
done
echo "AWS_SHARED_CREDENTIALS_FILE:"
echo "Before:"
cat $AWS_SHARED_CREDENTIALS_FILE
echo
echo

cat localtemplate 						\
  | sed -e "s#{{ AWS_ACCESS_KEY_ID }}#$AWS_ACCESS_KEY_ID#g"	\
  | sed -e "s#{{ AWS_SECRET_ACCESS_KEY }}#$AWS_SECRET_KEY#g"	\
  > $AWS_SHARED_CREDENTIALS_FILE

echo "After:"
cat $AWS_SHARED_CREDENTIALS_FILE
echo
echo
