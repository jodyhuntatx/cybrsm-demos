#!/bin/bash
source ../gitlabvars.sh

export ANUN_TENANT=demo
export ANUN_SECRET=MZIE4q1amwtQXzlo7WGQgkUZxe415ylDC4mcTcnc3PzahXRz9wThhibpQwHjoax8

export TRACER_INSTALLER_URL="https://downloads.anun.cloud/tracer/pub/anun-installer.sh"

export GENERATED_LINK=$(curl "https://api.anun.cloud/api/tracer/external/get-link?tenantId=$ANUN_TENANT&secret=$ANUN_SECRET")
TRACER_PACKAGE_URL=$(sed -e 's/^"//' -e 's/"$//' <<< "$GENERATED_LINK")

$DOCKER build 							\
	-t $GITLAB_RUNNER_IMAGE					\
	--build-arg TRACER_INSTALLER_URL="$TRACER_INSTALLER_URL"\
	--build-arg TRACER_PACKAGE_URL="$TRACER_PACKAGE_URL"	\
	.

