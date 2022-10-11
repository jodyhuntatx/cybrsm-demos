FROM centos:7

# Install basics
RUN yum -y install unzip tar sudo vim wget curl openssh-server jq

# Generate ssh keys
RUN ssh-keygen -q -t dsa -f /etc/ssh/ssh_host_dsa_key -N '' && 	\
    ssh-keygen -q -t rsa -f /etc/ssh/ssh_host_rsa_key -N '' && 	\
    ssh-keygen -q -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key -N '' && \
    ssh-keygen -q -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N ''

# Install SELinux libraries - taken from:
RUN yum -y install 			\
	policycoreutils			\
	policycoreutils-python		\
	selinux-policy			\
	selinux-policy-targeted		\
	libselinux-utils		\
	setroubleshoot-server		\
	setools				\
	setools-console			\
	mcstrans

# systemd install and start from: https://serverfault.com/questions/824975/failed-to-get-d-bus-connection-operation-not-permitted
RUN yum -y install 			\
	systemd			     && \
    yum upgrade -y 		     && \
    yum clean all		     && \
    (cd /lib/systemd/system/sysinit.target.wants/; 	\
    for i in *; do [ $i == systemd-tmpfiles-setup.service ] || rm -f $i; done); \
    rm -f /lib/systemd/system/multi-user.target.wants/*;	\
    rm -f /etc/systemd/system/*.wants/*;			\
    rm -f /lib/systemd/system/local-fs.target.wants/*; 		\
    rm -f /lib/systemd/system/sockets.target.wants/*udev*; 	\
    rm -f /lib/systemd/system/sockets.target.wants/*initctl*; 	\
    rm -f /lib/systemd/system/basic.target.wants/*;		\
    rm -f /lib/systemd/system/anaconda.target.wants/*
VOLUME [ "/sys/fs/cgroup" ]
CMD ["/usr/sbin/init"]
