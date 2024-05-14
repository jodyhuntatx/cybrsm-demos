#!/bin/bash
                # set CONJUR_HOME to parent directory of this script
CONJUR_HOME="$(ls $0 | rev | cut -d "/" -f2- | rev)/.."

if [[ "$1" != stop && "$1" != start ]]; then
  echo "Usage: $0 [ stop | start ]"
  exit -1
fi

cd $CONJUR_HOME
if [[ $1 == start ]]; then
  DIRS="K8S_followers CICD_demos JENKINS_demo SPLUNK_demo K8S_apps_demo"
else
  DIRS="K8S_apps_demo SPLUNK_demo JENKINS_demo K8S_followers CICD_demos"
fi
for i in $DIRS; do
  pushd $i && ./$1
  popd
done
