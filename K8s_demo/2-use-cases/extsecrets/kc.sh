#\bin\bash

usage() {
  echo "Usage: $0 [ r[esources] <namespace> | e[so-log] <namespace> ]"
  exit -1
}

if [[ $# != 2 ]]; then
  usage
fi

case $1 in
  r*) 	kubectl api-resources --verbs=list --namespaced -o name		\
	| xargs -n 1 kubectl get --show-kind --ignore-not-found -n $2
	;;

  e*) 	ESO_POD=$(kubectl get pods -n external-secrets --no-headers=true	\
	| grep -v webhook | grep -v cert-controller | awk '{print $1}')
	kubectl logs $ESO_POD -n external-secrets --since 5m
	;;

  *) 	usage
	;;
esac
