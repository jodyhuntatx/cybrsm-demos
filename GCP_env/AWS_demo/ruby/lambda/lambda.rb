#!/usr/bin/env ruby

require "aws-sdk-core"
require "aws-sigv4"
require "conjur-api"
require "pp"

def handler(event:, context:)  # Event handler entry point
  puts "event: #{event}"
  puts "context: #{context}"

#  pp ENV  # pretty print all env vars

  # name of Conjur var to retrieve
  varId = String.new("#{ENV['VAR_ID']}")

  # setup Conjur configuration object
  Conjur.configuration.account = "#{ENV['CONJUR_ACCOUNT']}"
  Conjur.configuration.appliance_url = "#{ENV['CONJUR_APPLIANCE_URL']}"
  Conjur.configuration.authn_url = "#{Conjur.configuration.appliance_url}/authn-iam/#{ENV['AUTHN_IAM_SERVICE_ID']}"
  Conjur.configuration.cert_file = "#{ENV['CONJUR_CERT_FILE']}"
  Conjur.configuration.apply_cert_config!
  puts "Applied Conjur configuration..."

  # if access key env var is blank, use EC2 instance creds to assume lambda identity
  if "#{ENV['AWS_ACCESS_KEY_ID']}" == "" then
    function_creds = Aws::InstanceProfileCredentials.new
    puts "Created function credentials: #{function_creds}"

    # use function creds to assume lambda role
    role_credentials = Aws::AssumeRoleCredentials.new(
      client: Aws::STS::Client.new(credentials: function_creds, region: 'us-east-1'),
      role_arn: "arn:aws:iam::313705343335:role/service-role/lambda_demo-role-awae09qn",
      role_session_name: "Conjur-retrieval"
    )
    puts "Created assumed role credentials: #{role_credentials}"

    signer = Aws::Sigv4::Signer.new(
      service: 'sts',
      region: 'us-east-1',
      credentials_provider: role_credentials
    )
  else # use access key, secret key and session token to create creds

    #   this should work but the constructor generates an error, 
    #   so use env vars in signer constructor
#    function_creds = Aws::Credentials.new(
#      access_key_id: "#{ENV['AWS_ACCESS_KEY_ID']}",
#      secret_access_key: "#{ENV['AWS_SECRET_ACCESS_KEY']}",
#      session_token: "#{ENV['AWS_SESSION_TOKEN']}"
#    )

    signer = Aws::Sigv4::Signer.new(
      service: 'sts',
      region: 'us-east-1',
      access_key_id: "#{ENV['AWS_ACCESS_KEY_ID']}",
      secret_access_key: "#{ENV['AWS_SECRET_ACCESS_KEY']}",
      session_token: "#{ENV['AWS_SESSION_TOKEN']}"
    )
  end
  puts "Created new v4 Signer..."

  # Make a signed request to STS to get an authorization header
  header = signer.sign_request(
    http_method: 'GET',
    url: 'https://sts.amazonaws.com/?Action=GetCallerIdentity&Version=2011-06-15'
  ).headers
  puts "Created signed header: #{header}"

  # Authenticate Conjur host identity using signed header in json format
  conjur = Conjur::API.new_from_key("#{ENV['CONJUR_AUTHN_LOGIN']}", header.to_json)
  # Get access token
  conjur.token

  # Use the cached token to get the secrets
  variable_value = conjur.resource("#{ENV['CONJUR_ACCOUNT']}:variable:#{varId}").value
  puts "Variable ID: #{varId}"
  puts "Variable value: #{variable_value}"

end

handler(event: "foo", context: "bar")
