#!/bin/bash
                # set CONJUR_HOME to parent directory of this script
CONJUR_HOME="$(ls $0 | rev | cut -d "/" -f2- | rev)/.."
source $CONJUR_HOME/config/conjur.config
kubectl delete -f $CONJUR_HOME/bin/k8sdashboard.yaml
