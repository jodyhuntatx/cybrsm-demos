source ../../jenkinsvars.sh
docker build -f ./Dockerfile.lts -t $JENKINS_DEMO_IMAGE:latest .
