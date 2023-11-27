#!/bin/bash -x
scp -r -i ~/.ssh/jody-ca-central-1.pem $1 ubuntu@15.222.249.90:~/
