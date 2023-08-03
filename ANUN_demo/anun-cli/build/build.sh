#!/bin/bash
source ../anun-vars.sh

$DOCKER build -t $ANUN_DEMO_IMAGE .

$DOCKER run -d 			\
    --platform linux/amd64 	\
    --name $ANUN_DEMO		\
    -e "TERM=xterm" 		\
    -e "GITLAB_PTOKEN=$GITLAB_PTOKEN" 		\
    -e "GITHUB_PTOKEN=$GITHUB_PTOKEN" 		\
    --entrypoint "sh" 		\
    $ANUN_DEMO_IMAGE		\
    -c "sleep infinity"

$DOCKER exec $ANUN_DEMO bash -c "	\
	python3 -m venv anun_env	\
	&& source anun_env/bin/activate	\
	&& pip3 install \"https://downloads.anun.cloud/anun-configure-customer/anun_configure_customer-1.7.93-py3-none-any.whl?Expires=1687282348&Signature=PDosP5elrnbNQA1F23hDX82Jinn4u0iPYFKDJJf5DZz3J-VKYJrOYpCYgVmLiJSkehrh364umzijz98dXR-UaOyrJCnJMAyFmf6bU7zOvgxMHL~idr5j0AKuoHFAxzvGEp0omG4oT4VTEymCq0ISsUf4aTDyk7pUC4yW-40MHLahVhwy2iQySBTg~IgEHofqiQlXVZru-uElVQTOp1dCBQ~MvZZl68keMn~WhFTJgXS8bHrlZ99FcDsoU4tbQiSS-9hzRMqJ0DlNvUDLYpPpS9BtNNd~nLSzdOTHJ32iGvKgfVcvaYRKelFbbWcnJfC1WqG4MGzNxlEo4Myv4Bli8Q__&Key-Pair-Id=K3I8ZP4ALY4308\"
	"

$DOCKER commit $ANUN_DEMO $ANUN_DEMO_IMAGE
$DOCKER stop $ANUN_DEMO && $DOCKER rm $ANUN_DEMO
