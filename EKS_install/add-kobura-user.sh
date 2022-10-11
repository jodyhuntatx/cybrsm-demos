#!/usr/bin/env bash
set -e   # set -o errexit
set -u   # set -o nounset
set -o pipefail
[ "x${DEBUG:-}" = "x" ] || set -x

CA_AWK_COMMAND='
BEGIN{kobura_found=0}
/mapRoles: \|/{
  print;
  print "    - username: cyberark:kobura:475601244925:CyberArkEKSRoleForKobura023673983569-893ec969249968a8\n      rolearn: arn:aws:iam::475601244925:role/CyberArkEKSRoleForKobura023673983569-893ec969249968a8\n      groups:\n        - cyberark:kobura";
  next}
/username: cyberark:kobura:475601244925:CyberArkEKSRoleForKobura023673983569\-893ec969249968a8/ {
  kobura_found=1;
  next
}
/^(    -|  mapUsers: \||[^ ].*)/{
  if (kobura_found)
  {
    kobura_found=0
  };
  print;
  next
}
{
  if (!kobura_found)
  {
    print
  }
}'

function CheckPreReqs
{
  command -v awk >/dev/null 2>&1 || { echo >&2 "We could not find the 'awk' command. Make sure it's in installed and in PATH."; exit 1; }
  command -v kubectl >/dev/null 2>&1 || { echo >&2 "We could not find the 'kubectl' command. Make sure it's installed and in PATH."; exit 1; }
}

function PatchAWSConfigFile
{
    #save old aws-auth file
    kubectl get -n kube-system configmap/aws-auth -o yaml > original-aws-auth.yaml

    # Add cyberark:kobura user to aws-auth configfile, replace if it already contains one
    UPDATED_AWS_CONFIG=$(kubectl get -n kube-system configmap/aws-auth -o yaml | awk "$CA_AWK_COMMAND")

    # Patch aws-config with the cyberark:kobura user
    kubectl patch configmap/aws-auth -n kube-system --patch "$UPDATED_AWS_CONFIG" > /dev/null
}

function ApplyRBACPermissions
{
    kubectl apply -f 'https://bitbucket.org/cyberarkhexagon/kubernetes-deployment-manager/raw/master/eks/kobura-permissions.yaml' > /dev/null
}

CheckPreReqs
PatchAWSConfigFile
ApplyRBACPermissions
echo "Environment configured successfully"