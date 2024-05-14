FROM centos/systemd

RUN yum update -y	&& \
    yum install -y	\
	sudo		\
	audit 		\
	policycoreutils \
	systemd-sysv 	\
	sysvinit-tools	\
	openssh-server	\
	openssh-clients	\
	unzip		&& \
    yum upgrade -y      && \
    yum clean all

# Generate ssh keys
RUN ssh-keygen -q -t dsa -f /etc/ssh/ssh_host_dsa_key -N '' && 	\
    ssh-keygen -q -t rsa -f /etc/ssh/ssh_host_rsa_key -N '' && 	\
    ssh-keygen -q -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key -N '' && \
    ssh-keygen -q -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N ''

# Do systemd init & cleanup stuff
RUN (cd /lib/systemd/system/sysinit.target.wants/;      \
    for i in *; do [ $i == systemd-tmpfiles-setup.service ] || rm -f $i; done); \
    rm -f /lib/systemd/system/multi-user.target.wants/*;        \
    rm -f /etc/systemd/system/*.wants/*;                        \
    rm -f /lib/systemd/system/local-fs.target.wants/*;          \
    rm -f /lib/systemd/system/sockets.target.wants/*udev*;      \
    rm -f /lib/systemd/system/sockets.target.wants/*initctl*;   \
    rm -f /lib/systemd/system/basic.target.wants/*;             \
    rm -f /lib/systemd/system/anaconda.target.wants/*
VOLUME [ "/sys/fs/cgroup" ]
