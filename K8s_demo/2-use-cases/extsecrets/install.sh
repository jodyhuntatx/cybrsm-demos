kubectl create ns external-secrets
helm install external-secrets ./deploy/charts/external-secrets -n external-secrets
