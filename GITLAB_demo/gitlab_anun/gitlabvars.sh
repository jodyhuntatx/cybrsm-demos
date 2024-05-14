export CONJUR_HOME=${CONJUR_HOME:-~/Conjur/cybrsm-demos}

###########################
export CURL="curl -sk"

# Anun tenant vars
export ANUN_TENANT=demo
export ANUN_SECRET=MZIE4q1amwtQXzlo7WGQgkUZxe415ylDC4mcTcnc3PzahXRz9wThhibpQwHjoax8
export ANUN_TRACE_PPID_HOOK=0


# GitLab demo container variables
export DOCKER=docker
export GITLAB_HOST_NAME=gitlab.com

# runner vars
export GITLAB_RUNNER_IMAGE=gitlab-anun:latest
export GITLAB_RUNNER_CONTAINER=gitlab-anun
export GITLAB_RUNNER_VOLUME=gitlab-anun
