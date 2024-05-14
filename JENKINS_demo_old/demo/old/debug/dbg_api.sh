#!/bin/bash -x

HF_TOKEN=s5gb1h2ak02hcj9p5eh18mvd83hyc1ah957hhr2w07by42gwfgwa
HOST_AUTHN_NAME=executor-master0
VAR_NAME=secrets/db_password

AUTHN_TOKEN=$(./get_authn_token.sh $HF_TOKEN $HOST_AUTHN_NAME)
./get_variable_value.sh $AUTHN_TOKEN $VAR_NAME
