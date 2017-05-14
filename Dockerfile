# fenrir/acme-haproxy
# HAproxy and LetsEncrypt
# TODO :zero downtime
# TODO :staging as ENV
# TODO :scripts in PATH
# TODO :...
#
# VERSION 0.5.0
#
FROM debian:stretch-slim
MAINTAINER Fenrir <dont@want.spam>

ENV	DEBIAN_FRONTEND noninteractive
ENV SYSLOG 127.0.0.1:514

# Configure APT and install packages
RUN	echo 'APT::Install-Suggests "false";' > /etc/apt/apt.conf &&\
	echo 'APT::Install-Recommends "false";' >> /etc/apt/apt.conf &&\
	echo 'Aptitude::Recommends-Important "false";' >> /etc/apt/apt.conf &&\
	echo 'Aptitude::Suggests-Important "false";' >> /etc/apt/apt.conf &&\
	apt-get update &&\
	apt-get -y dist-upgrade &&\
	apt-get -y install \
	ca-certificates \
	curl \
	haproxy \
	netcat &&\
	apt-get autoclean && apt-get clean && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*.deb /tmp/* /var/tmp/*

# Configure docker
RUN	mv /etc/haproxy /etc/haproxy.dist &&\
	mkdir -p /run/haproxy &&\
	mkdir -p /root/.acme.sh &&\
# Create entrypoint
	echo "#!/bin/bash" > /docker-entrypoint &&\
# Create haproxy.cfg
	echo "if [ ! -f /etc/haproxy/haproxy.cfg ]; then" >> /docker-entrypoint &&\
	echo "	mkdir -p /etc/haproxy/ssl" >> /docker-entrypoint &&\
	echo "	cp -r /etc/haproxy.dist/* /etc/haproxy/." >> /docker-entrypoint &&\
	echo "	sed -i '3 d' /etc/haproxy/haproxy.cfg" >> /docker-entrypoint &&\
	echo "	sed -i '2 d' /etc/haproxy/haproxy.cfg" >> /docker-entrypoint &&\
	echo "	sed -i '2ilog $SYSLOG local1' /etc/haproxy/haproxy.cfg" >> /docker-entrypoint &&\
	echo "	sed -i '20itune.ssl.default-dh-param 2048' /etc/haproxy/haproxy.cfg" >> /docker-entrypoint &&\
	echo "	echo 'frontend ssl_redirector' >> /etc/haproxy/haproxy.cfg" >> /docker-entrypoint &&\
	echo "	echo '	bind *:443 ssl crt /etc/haproxy/ssl/' >> /etc/haproxy/haproxy.cfg" >> /docker-entrypoint &&\
	echo "	echo '	http-request del-header X-Forwarded-Proto' >> /etc/haproxy/haproxy.cfg" >> /docker-entrypoint &&\
	echo "	echo '	http-request set-header X-Forwarded-Proto https if { ssl_fc }' >> /etc/haproxy/haproxy.cfg" >> /docker-entrypoint &&\
	echo "	echo '	acl letsencrypt-request path_beg -i /.well-known/acme-challenge/' >> /etc/haproxy/haproxy.cfg" >> /docker-entrypoint &&\
	echo "	echo '	use_backend letsencrypt_backend if letsencrypt-request' >> /etc/haproxy/haproxy.cfg" >> /docker-entrypoint &&\
	echo "	echo '	default_backend website_backend' >> /etc/haproxy/haproxy.cfg" >> /docker-entrypoint &&\
	echo "	echo 'frontend http_redirect' >> /etc/haproxy/haproxy.cfg" >> /docker-entrypoint &&\
	echo "	echo '	bind *:80' >> /etc/haproxy/haproxy.cfg" >> /docker-entrypoint &&\
	echo "	echo '	acl letsencrypt-request path_beg -i /.well-known/acme-challenge/' >> /etc/haproxy/haproxy.cfg" >> /docker-entrypoint &&\
	echo "	echo '	redirect scheme https code 302 if !letsencrypt-request' >> /etc/haproxy/haproxy.cfg" >> /docker-entrypoint &&\
	echo "	echo '	use_backend letsencrypt_backend if letsencrypt-request' >> /etc/haproxy/haproxy.cfg" >> /docker-entrypoint &&\
	echo "	echo 'backend letsencrypt_backend' >> /etc/haproxy/haproxy.cfg" >> /docker-entrypoint &&\
	echo "	echo '	server letsencrypt 127.0.0.1:11444' >> /etc/haproxy/haproxy.cfg" >> /docker-entrypoint &&\
	echo "	echo 'backend website_backend' >> /etc/haproxy/haproxy.cfg" >> /docker-entrypoint &&\
	echo "	echo '	server server01 127.0.0.1:11080' >> /etc/haproxy/haproxy.cfg" >> /docker-entrypoint &&\
	echo "fi" >> /docker-entrypoint &&\
# Create temp cert file
	echo "if [ ! -f /etc/haproxy/ssl/temp.pem ]; then" >> /docker-entrypoint &&\
	echo "	openssl req -subj '/CN=temp/O=ora/C=RY' -new -newkey rsa:2048 -sha256 -days 100 -nodes -x509 -keyout /tmp/temp.key -out /tmp/temp.crt" >> /docker-entrypoint &&\
	echo "	cat /tmp/temp.key /tmp/temp.crt > /etc/haproxy/ssl/temp.pem" >> /docker-entrypoint &&\
	echo "fi" >> /docker-entrypoint &&\
# Install acme.sh
	echo "if [ ! -f /root/.acme.sh/acme.sh ]; then" >> /docker-entrypoint &&\
	echo "	curl -o /root/.acme.sh/acme.sh https://raw.githubusercontent.com/Neilpang/acme.sh/master/acme.sh" >> /docker-entrypoint &&\
	echo "	chmod +x /root/.acme.sh/acme.sh" >> /docker-entrypoint &&\
	echo "fi" >> /docker-entrypoint &&\
	echo "/usr/sbin/haproxy-systemd-wrapper -f /etc/haproxy/haproxy.cfg -p /run/haproxy.pid &" >> /docker-entrypoint &&\
	echo "sleep infinity" >> /docker-entrypoint &&\
	chmod +x /docker-entrypoint &&\

# Certificate issue
	echo "#!/bin/bash" > /docker-certissue &&\
	echo '/root/.acme.sh/acme.sh --issue --staging --standalone --httpport 11444 --force --debug $@' >> /docker-certissue &&\
	chmod +x /docker-certissue &&\

# Certificate renew
	echo "#!/bin/bash" > /docker-certrenew &&\
	echo "/root/.acme.sh/acme.sh --renew-all --staging --standalone --httpport 11444 --force --debug" >> /docker-certrenew &&\
	chmod +x /docker-certrenew &&\

# Certificate install
	echo "#!/bin/bash" > /docker-certinstall &&\
	echo 'DOMAIN=$1' >> /docker-certinstall &&\
	echo 'ACMESTORE="/root/.acme.sh"' >> /docker-certinstall &&\
	echo 'HAPROXYSTORE="/etc/haproxy/ssl"' >> /docker-certinstall &&\
	echo 'if [ -f $ACMESTORE/$DOMAIN/$DOMAIN.cer ]; then' >> /docker-certinstall &&\
	echo '	cat $ACMESTORE/$DOMAIN/$DOMAIN.key $ACMESTORE/$DOMAIN/$DOMAIN.cer $ACMESTORE/$DOMAIN/ca.cer > $HAPROXYSTORE/$DOMAIN.pem' >> /docker-certinstall &&\
	echo "fi" >> /docker-certinstall &&\
	echo 'haproxy -f /etc/haproxy/haproxy.cfg -p /run/haproxy.pid -sf $(cat /run/haproxy.pid) &' >> /docker-certinstall &&\
	chmod +x /docker-certinstall &&\

# Restart haproxy
	echo "#!/bin/bash" > /docker-restart &&\
	echo 'haproxy -f /etc/haproxy/haproxy.cfg -p /run/haproxy.pid -sf $(cat /run/haproxy.pid) &' >> /docker-restart &&\
	chmod +x /docker-restart &&\
	echo "end"

EXPOSE 80/tcp 443/tcp
	
VOLUME ["/root/.acme.sh", "/etc/haproxy"]

ENTRYPOINT	["/docker-entrypoint"]
# ENTRYPOINT	["/bin/bash"]