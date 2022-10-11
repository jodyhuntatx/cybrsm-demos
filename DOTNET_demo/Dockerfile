FROM ubuntu:16.04

# Install utilities & dependencies
RUN apt-get update		\
    && apt-get install -y	\
	git			\
	wget			\
	vim			\
	curl			\
	unzip			\
	apt-transport-https 	\
	libelf-dev

# Install .NET Core SDK and runtime
RUN wget https://packages.microsoft.com/config/ubuntu/16.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb \
    && dpkg -i packages-microsoft-prod.deb
RUN apt-get update \
    && apt-get install -y \
    	dotnet-sdk-3.1 \
    	aspnetcore-runtime-3.1

WORKDIR /demo

# Install Conjur Client repo and build the dll
RUN wget https://github.com/AndrewCopeland/conjur-api-net-core/archive/master.zip \
    && unzip master.zip								  \
    && cd conjur-api-net-core-master/src					  \
    && dotnet build --configuration Release
