HF_TOKEN=$(cat /var/jenkins_home/secrets/hostfactory)
echo $(curl -k -s -X POST -H "Authorization: Token token=\"$HF_TOKEN\"" https://jenkins/api/host_factories/hosts?id=$(hostname) | jq -r .api_key)
