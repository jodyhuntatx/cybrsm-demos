#!/bin/bash

# Builds an Ubuntu 16.04 image with CP & Java SDK installed 

source ./javacpdemo.config

main() {
  ./stop
  stop
  build
  start
  install_cp
  docker commit $BUILD_CONTAINER $DEMO_IMAGE
  stop
}

######################
stop() {
  docker stop $BUILD_CONTAINER && docker rm $BUILD_CONTAINER
}

######################
build() {
  docker build . -t $BUILD_IMAGE
}

######################
start() {
  docker run -d \
    -h $DEMO_HOSTNAME \
    --name $BUILD_CONTAINER \
    --entrypoint sh \
    $BUILD_IMAGE \
    -c "sleep infinity"
}

######################
install_cp() {
  rm -rf ./tmp && mkdir ./tmp
  unzip $CP_ZIPFILE_PATH/$CP_ZIPFILE_NAME -d ./tmp
  pushd tmp > /dev/null

set -x

    # Set hostname to demo image name
    CONTAINER_HOSTNAME=$(docker exec $BUILD_CONTAINER hostname)
    docker exec $BUILD_CONTAINER 	\
	sed -i bak "s/$CONTAINER_HOSTNAME/$DEMO_IMAGE/gp" /etc/hostname	\
	&& sed -i bak "s/$CONTAINER_HOSTNAME/$DEMO_IMAGE/gp" /etc/hosts

    # Create cp installation directory
    docker exec $BUILD_CONTAINER mkdir -p $CP_INSTALL_DIR

    # Setup Vault.ini file
    sed -i bak "/^ADDRESS/ s/1.1.1.1/$VAULT_IP/" Vault.ini
    docker cp Vault.ini $BUILD_CONTAINER:$CP_INSTALL_DIR

    # Copy over cred file utility, but do NOT create credfile
    docker cp ./CreateCredFile $BUILD_CONTAINER:/tmp
    docker exec $BUILD_CONTAINER chmod +x /tmp/CreateCredFile

    # Setup aimparams file
    sed -i bak '/^AcceptCyberArkEULA/ s/No/Yes/' aimparms.sample
    awk "/^#CreateVault/ {print \"CreateVaultEnvironment=yes\"; next} {print}" aimparms.sample \
    | awk "/^CredFilePath/ {print \"CredFilePath=$CP_INSTALL_DIR/$CREDFILE_NAME\"; next} { print }" \
    | awk "/^VaultFilePath/ {print \"VaultFilePath=$CP_INSTALL_DIR/Vault.ini\"; next} { print }" \
    | awk "/^CacheRefreshInterval/ {print \"CacheRefreshInterval=1\"; next} { print }" \
    > aimparms
    docker cp aimparms $BUILD_CONTAINER:/var/tmp

    # Copy over CP installation package, but do NOT install
    DEBFILE=$(ls CARKaim*)
    docker cp $DEBFILE $BUILD_CONTAINER:/tmp
  popd > /dev/null
}

main "$@"
