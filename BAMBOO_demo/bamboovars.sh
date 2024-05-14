# Bamboo Datacenter demo vars
export DOCKER=docker
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
export BAMBOO_HOME=/opt/bamboo
export BAMBOO_DEMO_IMAGE=bambooserver
export BAMBOO_DEMO_CONTAINER=bambooserver
export BAMBOO_DEMO_VOLUME=bamboovolume
export BAMBOO_AGENT_IMAGE=bamboogent
export BAMBOO_AGENT_CONTAINER=bambooagent
export KEYSTORE=$JAVA_HOME/lib/security/cacerts
export BAMBOO_HOST_PVT_IP=$CONJUR_LEADER_HOST_IP
export BAMBOO_PUB_DNS=$CONJUR_LEADER_HOSTNAME
export BAMBOO_PORT=8085
export BAMBOO_HOST_ID=bamboo_bot
export BAMBOO_SHM_SIZE=1024m

######################
# Vault policy parameters & secrets
export VAULT_NAME=DemoVault
export LOB_NAME=CICD
export SAFE_NAME=CICD_Secrets
export ACCOUNT_NAME=MySQL
