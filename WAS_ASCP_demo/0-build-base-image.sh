#!/bin/bash
source wasascpdemo.config

main() {
  clear
  get_ibm_credentials
  stop_build_container
  create_build_image 
  start_build_container
  install_ibm_install_manager
  install_websphere
  create_was_server_profile
  stage_cp
#  install_ascp_credmapper
  commit_build_image
  stop_build_container
}

######################
function get_ibm_credentials() {
  echo
  echo
  echo "If you do not already have one, you will need to create an IBM account at:"
  echo
  echo "  https://www.ibm.com/account/reg/us-en/subscribe?formid=urx-30292"
  echo
  echo "They are free, but required for repository access. If you need to"
  echo "create one, ctrl-C out of this script now."
  echo
  echo -n "Please enter your IBM account username: "
  read IBM_USERNAME
  echo
  echo -n "Please enter your IBM account password: "
  read -s IBM_PASSWORD
  echo
}

######################
function create_build_image() {
  echo "Creating build image..."

  docker build . -f ./Dockerfile.was -t $DEMO_IMAGE
}

######################
function start_build_container() {
  docker run -d \
    -h $DEMO_HOSTNAME \
    --name $DEMO_CONTAINER \
    --entrypoint sh \
    $DEMO_IMAGE \
    -c "sleep infinity"
}

######################
function install_ibm_install_manager() {
  echo "Copying installer zipfile and unzipping..."
  docker cp $IBM_INSTALLER_ZIPFILE \
	$DEMO_CONTAINER:$DEMO_DIR/ibm.installer.linux.zip
  docker exec -it $DEMO_CONTAINER \
	mkdir -p ./installer
  docker exec -it $DEMO_CONTAINER \
        unzip -q ibm.installer.linux.zip -d ./installer

  echo "Installing IBM Installation manager..."
  docker exec -it $DEMO_CONTAINER bash -c \
	"cd ./installer \
	&& ./userinstc -log log_file -acceptLicense \
	&& cd $DEMO_DIR \
	&& rm ibm.installer.linux.zip"
}

######################
function install_websphere() {
  echo "Creating credentials file for your IBM account - takes about a minute..."
  docker exec -it $DEMO_CONTAINER bash -c						\
	"./installer/tools/imutilsc saveCredential 					\
	-url http://www.ibm.com/software/repositorymanager/entitled/repository.xml 	\
	-userName $IBM_USERNAME 		\
	-userPassword $IBM_PASSWORD 		\
	-secureStorageFile $IBM_CREDFILE"

  echo "Installing WebSphere AppServer. This takes 12-15 minutes..."
  docker exec -it $DEMO_CONTAINER bash -c				\
	"./installer/tools/imcl install $WAS_PACKAGE $JAVA_PACKAGE	\
          -repositories $WAS_REPOSITORY 		\
	  -installationDirectory $INSTALL_DIR		\
	  -sharedResourcesDirectory $SHARED_DIR		\
	  -preferences $PREFERENCES			\
	  -secureStorageFile $IBM_CREDFILE		\
	  -acceptLicense				\
	  -showProgress					\
	  -log $INSTALLER_LOGFILE"
}

######################
function create_was_server_profile() {
  echo "Creating default server profile..."

  docker exec -it $DEMO_CONTAINER bash -c 						\
	"/opt/IBM/WebSphere/AppServer/bin/manageprofiles.sh -create 			\
		-profileName default 							\
		-profilePath "/opt/IBM/WebSphere/AppServer/profiles/default" 		\
		-templatePath "/opt/IBM/WebSphere/AppServer/profileTemplates/default" 	\
		-enableAdminSecurity true 		\
		-adminUserName admin 			\
		-adminPassword Cyberark1 		\
		-winserviceAccountType localsystem 	\
		-winserviceCheck true 			\
		-winserviceStartupType automatic 	\
		-omitAction samplesInstallAndConfig"
}

######################
function stage_cp() {
set -x
  echo "Staging CP installation resources..."

  rm -rf ./tmp && mkdir ./tmp
  unzip -q $CP_ZIPFILE_PATH/$CP_ZIPFILE -d ./tmp

  pushd tmp > /dev/null
    # Set hostname to demo image name
    CONTAINER_HOSTNAME=$(docker exec $DEMO_CONTAINER hostname)
    docker exec $DEMO_CONTAINER 					\
	sed -i bak "s/$CONTAINER_HOSTNAME/$DEMO_IMAGE/gp" /etc/hostname	\
	&& sed -i bak "s/$CONTAINER_HOSTNAME/$DEMO_IMAGE/gp" /etc/hosts

    # make CP_INSTALL_DIR installation directory
    docker exec $DEMO_CONTAINER mkdir -p $CP_INSTALL_DIR

    # Setup Vault.ini file & copy to CP_INSTALL_DIR
    sed -i bak "/^ADDRESS/ s/1.1.1.1/$VAULT_IP/" Vault.ini
    docker cp Vault.ini $DEMO_CONTAINER:$CP_INSTALL_DIR

    # Install utility but do not create credfile
    docker cp ./CreateCredFile $DEMO_CONTAINER:/tmp
    docker exec $DEMO_CONTAINER chmod +x /tmp/CreateCredFile

    # Setup aimparams file
    sed -i bak '/^AcceptCyberArkEULA/ s/No/Yes/' aimparms.sample
    awk "/^#CreateVault/ {print \"CreateVaultEnvironment=yes\"; next} {print}" aimparms.sample 		\
    | awk "/^CredFilePath/ {print \"CredFilePath=$CP_INSTALL_DIR/$CREDFILE_NAME\"; next} { print }" 	\
    | awk "/^VaultFilePath/ {print \"VaultFilePath=$CP_INSTALL_DIR/Vault.ini\"; next} { print }" 	\
    | awk "/^CacheRefreshInterval/ {print \"CacheRefreshInterval=1\"; next} { print }" 			\
    > aimparms
    docker cp aimparms $DEMO_CONTAINER:/var/tmp

    # Stage CP install package
    DEBFILE=$(ls CARKaim*)
    docker cp $DEBFILE $DEMO_CONTAINER:/tmp
  popd > /dev/null

  rm -rf ./tmp	# delete local CP install dir 
set +x
}

######################
function install_ascp_credmapper() {
  echo "Copying credmapper to container..."  

  mkdir -p ./tmp
  unzip -q $ASCP_ZIPFILE_PATH/$ASCP_ZIPFILE -d ./tmp
  CREDMAPPER_JARFILE="$(ls ./tmp/App*/WebSphere/CACred*)"
  docker cp "$CREDMAPPER_JARFILE" $DEMO_CONTAINER:$WAS_LIB_DIR
  rm -rf ./tmp
}

######################
function commit_build_image() {
  echo "Committing container as demo image..."

  docker commit $DEMO_CONTAINER $DEMO_IMAGE
}

######################
function stop_build_container() {
  echo "Stopping and removing build container..."

  docker stop $DEMO_CONTAINER > /dev/null 	\
    && docker rm $DEMO_CONTAINER > /dev/null
}

main "$@"
