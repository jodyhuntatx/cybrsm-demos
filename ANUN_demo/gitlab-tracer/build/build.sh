#!/bin/bash
source ../gitlab-vars.sh

$DOCKER build -t $GITLAB_TRACER_IMAGE .
$DOCKER tag $GITLAB_TRACER_IMAGE jodyhuntatx/$GITLAB_TRACER_IMAGE
$DOCKER push jodyhuntatx/$GITLAB_TRACER_IMAGE
