#!/bin/bash -x

# Ruby version needs to be 2.5 or greater
export PATH=/usr/local/lib/ruby/gems/2.5/bin:$PATH
export LDFLAGS="-L/usr/local/opt/ruby@2.5/lib"
export CPPFLAGS="-I/usr/local/opt/ruby@2.5/include"
export PKG_CONFIG_PATH="/usr/local/opt/ruby@2.5/lib/pkgconfig"

source ../demo.config

main() {
  create_zipfile
#  delete_lambda
#  create_lambda
#  update_lambda_config
  update_lambda_code
}

create_zipfile() {
  rm -rf function.zip vendor/
  bundle install --path vendor/bundle
  zip -r function.zip lambda.rb conjur-dev.pem vendor
}

# Create new function
create_lambda() {
  aws lambda create-function						\
	--function-name Conjur-Lambda-Function				\
	--runtime ruby2.5						\
	--role arn:aws:iam::$AWS_ACCOUNT:role/service-role/$AWS_IAM_ROLE \
	--handler lambda.handler					\
	--zip-file fileb://function.zip 
}

# Update configuration
update_lambda_config() {
  aws lambda update-function-configuration 				\
	--function-name Conjur-Lambda-Function 				\
	--role arn:aws:iam::$AWS_ACCOUNT:role/service-role/$AWS_IAM_ROLE \
	--handler lambda.handler 
}

# Update function code
update_lambda_code() {
  aws lambda update-function-code		\
	--function-name Conjur-Lambda-Function	\
	--zip-file fileb://function.zip
}

# Delete function
delete_lambda() {
  aws lambda delete-function \
	--function-name Conjur-Lambda-Function
}

main "$@"
