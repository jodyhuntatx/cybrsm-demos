#!/usr/bin/env ruby

require 'aws-sdk-core'
require 'aws-sigv4'
require 'conjur-api'

# name of Conjur var to retrieve
VAR_ID="#{ARGV.first}"

# debug output 
# puts "CONJUR_APPLIANCE_URL: #{ENV['CONJUR_APPLIANCE_URL']}"
# puts "AUTHN_IAM_SERVICE_ID: #{ENV['AUTHN_IAM_SERVICE_ID']}"
# puts "CONJUR_AUTHN_LOGIN: #{ENV['CONJUR_AUTHN_LOGIN']}"
# puts "CONJUR_CERT_FILE: #{ENV['CONJUR_CERT_FILE']}"
# puts "CONJUR_ACCOUNT: #{ENV['CONJUR_ACCOUNT']}"
# puts "VAR_ID: #{VAR_ID}"

# setup Conjur configuration object
Conjur.configuration.account = "#{ENV['CONJUR_ACCOUNT']}"
Conjur.configuration.appliance_url = "#{ENV['CONJUR_APPLIANCE_URL']}"
Conjur.configuration.authn_url = "#{Conjur.configuration.appliance_url}/authn-iam/#{ENV['AUTHN_IAM_SERVICE_ID']}"
Conjur.configuration.cert_file = "#{ENV['CONJUR_CERT_FILE']}"
Conjur.configuration.apply_cert_config!

# Make a signed request to STS to get an authorization header
header = Aws::Sigv4::Signer.new(
  service: 'sts',
  region: 'us-east-1',
  credentials_provider: Aws::InstanceProfileCredentials.new
).sign_request(
  http_method: 'GET',
  url: 'https://sts.amazonaws.com/?Action=GetCallerIdentity&Version=2011-06-15'
).headers

# Authenticate Conjur host identity using signed header in json format
conjur = Conjur::API.new_from_key("#{ENV['CONJUR_AUTHN_LOGIN']}", header.to_json)
# Get access token
conjur.token

# Use the cached token to get the secrets
variable_value = conjur.resource("#{ENV['CONJUR_ACCOUNT']}:variable:#{VAR_ID}").value
print "#{variable_value}"
