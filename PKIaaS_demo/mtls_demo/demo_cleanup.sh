#!/bin/bash
source ../../config/conjur.config

main() {
#  echo "Logging in as Conjur admin..."
#  cybr conjur login -a $CONJUR_ACCOUNT -b $CONJUR_LEADER_URL -l admin --self-signed
  delete_objects variable pki/certificates/
  delete_objects group pki/certificates/
}

delete_objects() {
  local oKind=$1; shift
  local oFilter=$1; shift

  for i in $(cybr conjur list | grep "$oKind:$oFilter"); do
    oName=$(echo $i | cut -d : -f 3 | tr -d '", ')
    echo "Deleting: $oName"
    tee > _pki_foo <<EOF;
- !delete
  record: !$oKind $oName
EOF
    cybr conjur update-policy -b root -f _pki_foo
  done
  rm _pki_foo
}

main "$@"
