#!/bin/bash
                # set CONJUR_HOME to parent directory of this script
CONJUR_HOME="$(ls $0 | rev | cut -d "/" -f2- | rev)/.."
source $CONJUR_HOME/config/conjur.config

export AUTHN_USERNAME=$CONJUR_ADMIN_USERNAME
export AUTHN_PASSWORD=$CONJUR_ADMIN_PASSWORD
var_get_set_REST.sh get $1 $2
