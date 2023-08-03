export DOCKER=docker
export ANUN_DEMO_IMAGE=anun-scanner:latest
export ANUN_DEMO=anun-scanner
export ANUN_TENANT=jody
case $ANUN_TENANT in
  jody)	export ANUN_APIKEY=$(keyring get anun jody-apikey)
	;;
  prod) export ANUN_APIKEY=$(keyring get anun prod-apikey)
	;;
esac
#export GITLAB_PTOKEN=$(keyring get anun gitlab_ptoken)
export GITLAB_PTOKEN=glpat-6mZ88GYEEt24iZkjVYKw
export GITHUB_PTOKEN=$(keyring get anun github_ptoken)
