FROM ubuntu:22.04

# Install systemd - this is a special setup for running systemd in Docker
ENV container docker
RUN apt-get update && apt-get install -y systemd systemd-sysv
RUN (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i = systemd-tmpfiles-setup.service ] || rm -f $i; done); \
    rm -f /lib/systemd/system/multi-user.target.wants/*; \
    rm -f /etc/systemd/system/*.wants/*; \
    rm -f /lib/systemd/system/local-fs.target.wants/*; \
    rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
    rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
    rm -f /lib/systemd/system/basic.target.wants/*; \
    rm -f /lib/systemd/system/anaconda.target.wants/*;

# Install Apache, Nginx, and other dependencies
RUN apt-get update && apt-get install -y \
    apache2 \
    nginx \
    snapd \
    curl \
    netcat-openbsd \
    iputils-ping \
    dnsutils \
    python3 \
    python3-pip \
    python3-venv \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set up a directory for the script
WORKDIR /app

# Copy the script into the container
COPY lecbh.sh /app/
RUN chmod +x /app/lecbh.sh

# Use systemd as the entrypoint
VOLUME [ "/sys/fs/cgroup" ]
ENTRYPOINT ["/lib/systemd/systemd"]