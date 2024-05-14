#!/bin/bash

source ./javacpdemo.config

main() {
  ./stop
  if [ $? -ne 0 ]; then
    exit
  fi
  start
  compile_app
  ./exec-into-app.sh
}

######################
start() {
  docker run -d 	   \
    -h $DEMO_HOSTNAME	   \
    --name $DEMO_CONTAINER \
    --entrypoint sh 	   \
    $DEMO_IMAGE 	   \
    -c "sleep infinity"

set -x
  # create credfile
  docker exec -it $DEMO_CONTAINER \
	/tmp/CreateCredFile $CP_INSTALL_DIR/$CREDFILE_NAME \
	Password -Username $VAULT_USERNAME -Password $VAULT_PASSWORD \
	-Hostname -Entropyfile

  # install package & start credential provider
  DEBFILE=$(docker exec $DEMO_CONTAINER bash -c "ls /tmp/CARKaim*")
  docker exec $DEMO_CONTAINER dpkg -i $DEBFILE

  # update CacheRefreshInterval in config file before starting CP
  # Note: awk works better outside of docker shells
  conf_filename=$(docker exec -it $DEMO_CONTAINER bash -c \
	"ls /var/opt/CARKaim/main_appprovider.conf.linux*")
  conf_filename=$(echo $conf_filename | tr -d '\r\n')
#  docker exec -it $DEMO_CONTAINER cat $conf_filename > ./conf.orig
#  awk "/^CacheRefreshInterval/ 							\
#		{print \"CacheRefreshInterval=$CACHE_REFRESH_INTERVAL\"; next}	\
#		{print}"							\
#	./conf.orig 								\
#	> ./conf.new 
#  docker cp ./conf.new $DEMO_CONTAINER:$conf_filename
#  rm conf.orig conf.new

  status=$(docker exec $DEMO_CONTAINER /etc/init.d/aimprv start)
  if [[ $(echo $status | grep failed) != "" ]]; then
    echo
    echo "############################################################"
    echo ">> CP startup failed. >>"
    echo "   Use the Private Ark client to delete existing Prov_$DEMO_HOSTNAME user in Applications folder."
    echo "############################################################"
    echo
    exit -1
  fi

  echo
  echo "############################################################"
  echo ">> Be sure to add Prov_$DEMO_HOSTNAME as a member of the safe(s) it needs access to."
  echo "############################################################"
  echo
}

######################
compile_app() {
  for i in $(ls app/); do
    docker cp ./app/$i $DEMO_CONTAINER:$DEMO_DIR/
  done
  docker exec $DEMO_CONTAINER ./compile.sh
}

main "$@"
