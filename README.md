# acme-haproxy docker

By default, certificates are in staging mode to avoid quota outaged, remove or rename the file `/path/to/certificates/STAGING.readme` in order to issue well-known certificates

1-Create folders for volumes:

 - haproxy configuration folder: `/path/to/haproxy`
 - letsencrypt certificates folder: `/path/to/certificates`

2-Start container: `docker run -d --restart always --name haproxy -e SYSLOG=1.2.3.4:514 -e BACKEND=www.example.com:8080 -p 80:80 -p 443:443 -v /path/to/certificates:/home -v /path/to/haproxy:/etc/haproxy fenrir/acme-haproxy`

 - default ports are 80/tcp and 443/tcp
 - ENV `SYSLOG` allows you to configure a syslog server
 - ENV `BACKEND` allows you to configure the default backend

4-To issue a certificate: `docker exec haproxy /docker-certissue -d www.example.com`

 - you can add other names (ALT) with -d, ie: `-d www.example.com -d mail.example.com -d example.com`

4-Certificate renewal: `docker exec haproxy /docker-certrenew`
 
 - all certificates will be renewed

5-Install previously created certificate in haproxy: `docker exec haproxy /docker-certinstall www.example.com`

 - do it for each certificate, the folder name (`/path/to/certificates/<**domain name**>`) is the key

6-Apply haproxy configuration changes: `docker exec haproxy /docker-restart`

nb: the haproxy configuration should be tuned and the TCP80 port must be accessible from LetsEncrypt servers
