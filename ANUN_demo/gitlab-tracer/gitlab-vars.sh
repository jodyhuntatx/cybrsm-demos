###########################
# Runner token: glrt-EbLuv-2T9TCqwtAkp-1B

# GitLab demo container variables
export DOCKER=docker
export GITLAB_HOST_NAME=gitlab.com
export GITLAB_HTTPS_PORT=443

export GITLAB_TRACER_IMAGE=anun-gitlab-tracer:latest

# runner vars
export GITLAB_RUNNER_IMAGE=gitlab/gitlab-runner:latest
export GITLAB_RUNNER_CONTAINER=gitlab-docker
export GITLAB_RUNNER_VOLUME=gitlab-docker
