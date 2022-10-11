#!/bin/bash
containers="conjur1 conjur2 conjur3"
conjur_network="conjur_master_network"

for conjur_node in $containers; do
  echo
  echo "#########################"
  echo "##### node $conjur_node #####"
  echo "#########################"

  node_role=$($DOCKER exec $conjur_node evoke role)
  echo "== Node role (per evoke): $($DOCKER exec $conjur_node evoke role)"

  echo "== IP Address:" $($DOCKER inspect $conjur_node | jq -Mr .[].NetworkSettings.Networks.${conjur_network}.IPAddress)

  echo "== Node status (per localhost/health):"
  node_status=$($DOCKER exec $conjur_node curl -sk http://localhost/health | jq -Mr .cluster.ok)
  $DOCKER exec $conjur_node curl -sk http://localhost/health | jq -Mr .cluster

  echo "== PG replication status (per localhost/health):"
  $DOCKER exec $conjur_node curl -sk http://localhost/health | jq -Mr .database.replication_status

#  echo "== Cluster members (per evoke):"
#  $DOCKER exec -it $conjur_node evoke cluster member list | jq -Mr .

  echo "== Cluster health (per etcdctl):"
  $DOCKER exec -it $conjur_node etcdctl cluster-health

  if [[ ($node_role == master) && ($node_status == true)  ]]; then
    health_output=$($DOCKER exec $conjur_node curl -sk http://localhost/health)
    lag_bytes=$(echo $health_output | jq -Mr .database.replication_status.pg_stat_replication[].replication_lag_bytes)
    echo "Lag bytes: $lag_bytes"
    if [[ $lag_bytes < 0 ]]; then
      echo 'lag_bytes count < 0.'
    fi
  fi
done
echo "****************************"
