#!/bin/bash

source ./gitlabvars.sh

main() {
  case $1 in
    server)
	delete_server
	;;
    runner)
	delete_runner
	;;
    all)
	delete_runner
	delete_server
	;;
    *)
	echo
	echo "Usage: $0 server | runner | all"
	echo
	exit -1
	;;
  esac
  $DOCKER system prune -f
}

delete_server() {
  $DOCKER stop $GITLAB_SERVER_CONTAINER
  $DOCKER rm $GITLAB_SERVER_CONTAINER

  $DOCKER volume rm $GITLAB_CONFIG_VOLUME
  $DOCKER volume rm $GITLAB_LOGS_VOLUME
  $DOCKER volume rm $GITLAB_DATA_VOLUME
}

delete_runner() {
  $DOCKER stop $GITLAB_RUNNER_CONTAINER
  $DOCKER rm $GITLAB_RUNNER_CONTAINER
  $DOCKER volume rm $GITLAB_RUNNER_VOLUME
}

main "$@"
