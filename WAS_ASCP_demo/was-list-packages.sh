#/bin/bash
source wasascpdemo.config
echo "Retrieving package list for IBM repository:"
echo "   $WAS_REPOSITORY"
echo "This takes about 20 seconds..."
docker exec -it $DEMO_CONTAINER bash -c			\
  "./installer/tools/imcl listAvailablePackages		\
  -repositories $WAS_REPOSITORY				\
  -secureStorageFile $IBM_CREDFILE"
