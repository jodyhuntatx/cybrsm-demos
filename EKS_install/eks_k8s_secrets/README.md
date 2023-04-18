# Demo: K8s Secrets (Init Container)

## kubectl commands
| kubectl exploration commands                                                 |     |
|------------------------------------------------------------------------------|-----|
| kubectl -n conjur-cloud get secrets                                          |     |
| kubectl -n conjur-cloud describe secrets db-credentials                      |     |
| kubectl -n conjur-cloud get secret db-credentials -o jsonpath='{.data}' > tmpJson  |     |
| jq . tmpJson                                                                 |     |
| jq -r .DBName tmpJson &#124; base64 -d; echo                                 |     |
| jq -r .password tmpJson &#124; base64 -d; echo                               |     |
| jq -r ".\\"conjur-map\\"" tmpJson &#124; base64 -d; echo                     |     |
| kubectl get secret db-credentials -o yaml -n conjur-cloud                    |     |  
| kubectl describe deployment k8s-secrets-app1 -n conjur-cloud                 |     |
|                                                                              |     |
|                                                                              |     |
| kubectl get serviceaccounts -n conjur-cloud                                  |     |
| kubectl get configmap -n conjur-cloud                                        |     |
| kubectl get deployments -n conjur-cloud  <br/>                               |     |
| kubectl -n conjur-cloud-cloud describe configmap conjur-cloud                |     |
|                                                                              |     |
|                                                                              |     |
|                                                                              |     |
|                                                                              |     |
| /run/secrets/kubernetes.io/serviceaccount                                    |     |
|                                                                              |     |
|                                                                              |     |

jq -R '.' token  | jq 'split(".")|{header: .[0]|@base64d|fromjson, payload: .[1]|@base64d|fromjson}' 


