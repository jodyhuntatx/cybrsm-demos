#!/bin/bash

source ./gitlabvars.sh

$DOCKER stop $GITLAB_RUNNER_CONTAINER
$DOCKER rm $GITLAB_RUNNER_CONTAINER
$DOCKER volume rm $GITLAB_RUNNER_VOLUME
$DOCKER system prune -f
