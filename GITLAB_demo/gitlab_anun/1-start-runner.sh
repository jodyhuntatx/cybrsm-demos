#!/bin/bash

# Doc pages:
#  - https://docs.gitlab.com/ee/install/docker.html
#  - https://docs.gitlab.com/runner/register/index.html#docker

# Procedure implemented:
# - start runner container
# - download server cert
# - register runner
# - add SSH key for runner: ./opt/gitlab/embedded/service/gitlab-rails/doc/ci/ssh_keys

source ./gitlabvars.sh

main() {
  pushd build
    ./build.sh
  popd
  start_container
  register_container
  set_ssh_key
  generate_ci_file
}

########################################
start_container() {
        # create volume for persistence of state across container instances
  if [[ "$($DOCKER volume ls | grep $GITLAB_RUNNER_VOLUME)" == "" ]]; then
    $DOCKER volume create $GITLAB_RUNNER_VOLUME
  fi

  if [[ "$($DOCKER ps | grep $GITLAB_RUNNER_CONTAINER)" == "" ]]; then
    $DOCKER run --detach 					\
      --hostname $GITLAB_RUNNER_CONTAINER			\
      --name $GITLAB_RUNNER_CONTAINER				\
      --env ANUN_TENANT=$ANUN_TENANT				\
      --env ANUN_SECRET=$ANUN_SECRET				\
      --env ANUN_TRACE_PPID_HOOK=$ANUN_TRACE_PPID_HOOK		\
      --restart always 						\
      -v /var/run/docker.sock:/var/run/docker.sock	  	\
      --mount "src=$GITLAB_RUNNER_VOLUME,dst=/etc/gitlab-runner"  	\
      $GITLAB_RUNNER_IMAGE
  fi
}

########################################
register_container() {
  echo
  echo
  echo "Use 'shell' for executor when prompted."
  echo

  $DOCKER run 				\
  --rm -it 				\
  --mount "src=$GITLAB_RUNNER_VOLUME,dst=/etc/gitlab-runner"  	\
  $GITLAB_RUNNER_IMAGE			\
  register

  echo
  echo
  echo "Runner config info in /etc/gitlab-runner/config.toml:"
  $DOCKER exec $GITLAB_RUNNER_CONTAINER \
	cat /etc/gitlab-runner/config.toml

}

########################################
set_ssh_key() {
					# generate ssh keypair in runner
  GL_RUNNER_HOME=$($DOCKER exec -u gitlab-runner $GITLAB_RUNNER_CONTAINER	\
	bash -c "echo ~")
  $DOCKER exec $GITLAB_RUNNER_CONTAINER		\
	bash -c "mkdir -p $GL_RUNNER_HOME/.ssh; chown gitlab-runner $GL_RUNNER_HOME/.ssh; chmod 700 $GL_RUNNER_HOME/.ssh"
  $DOCKER exec -itu gitlab-runner  $GITLAB_RUNNER_CONTAINER	\
	bash -c "cd $GL_RUNNER_HOME; ssh-keygen -t rsa -b 2048 -C 'gitlab-runner key'"

  echo
  echo
  echo "##############################################################"
  echo "Add the following public SSH key as a Deploy key for the pipeline."
  echo "Navigation: <Project> -> Settings -> Repository -> Deploy keys"
  echo "##############################################################"
  echo
  $DOCKER exec $GITLAB_RUNNER_CONTAINER		\
	cat $GL_RUNNER_HOME/.ssh/id_rsa.pub
}

########################################
generate_ci_file() {
  cat ./templates/gitlab-ci.yml.template                   	  \
  | sed -e "s#{{ CONJUR_APPLIANCE_URL }}#$CONJUR_APPLIANCE_URL#"  \
  | sed -e "s#{{ SERVICE_ID }}#$SERVICE_ID#"                      \
  | sed -e "s#{{ CONJUR_ACCOUNT }}#$CONJUR_ACCOUNT#"              \
  | sed -e "s#{{ RETRIEVE_VAR_NAME }}#$RETRIEVE_VAR_NAME#"        \
  > ./.gitlab-ci.yml
  echo
  echo
  echo "##############################################################"
  echo "Use $PWD/.gitlab-ci.yml for pipeline."
  echo "##############################################################"
}

main "$@"
