#!/bin/bash
sudo snap install terraform
sudo snap install jq
sudo curl -sSL https://raw.githubusercontent.com/cyberark/summon/master/install.sh \
      | sudo env TMPDIR=$(mktemp -d) bash
