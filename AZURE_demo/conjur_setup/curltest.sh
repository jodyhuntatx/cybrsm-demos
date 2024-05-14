#!/bin/bash -x

echo "Access token for system-assigned identity"
curl 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://management.azure.com/' -H Metadata:true

echo "Access token for user-assigned identity"
client_id=b3af4cc0-2f36-4fa6-a58b-43db541352b6
curl "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&client_id=${client_id}&resource=https://management.azure.com/" -H Metadata:true
echo
