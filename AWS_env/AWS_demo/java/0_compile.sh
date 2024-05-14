#!/bin/bash -x

sudo apt-get -y install maven
git clone https://github.com/AndrewCopeland/conjur-api-java.git
mv conjur-api-java-master conjur-api-java

pushd conjur-api-java
#mvn clean
#mvn install dependency:copy-dependencies
mvn -e package -Dskiptests
popd
