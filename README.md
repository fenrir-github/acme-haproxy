# acme-haproxy docker
not ready for production use

`docker run -d --restart always --name haproxy -p 80:80 -p 443:443 -v /path/to/letsencrypt:/root/.acme.sh -v /path/to/haproxy:/etc/haproxy fenrir/acme-haproxy`

 1-Create data folders:

 - haproxy configuration folder: /path/to/haproxy
 - letsencrypt certificates folder: /path/to/letsencrypt

2-Create image: `docker build -t acme-haproxy /path/to/dockerfile/`

3-Start container: `docker run -d --restart always --name haproxy -e SYSLOG=127.0.0.1:514 -p 80:80 -p 443:443 -v /path/to/letsencrypt:/root/.acme.sh -v /path/to/haproxy:/etc/haproxy acme-haproxy`

 - default ports are 80/tcp and 443/tcp
 - SYSLOG allows you to configure à syslog server, ie: `-e SYSLOG=syslog.server.ip.addressadresse:514`

4-To create a certificat : `docker exec haproxy /docker-certissue -d www.domain.com`

 - you can add other names with -d, ie: `-d www.domain.com -d mail.domain.com -d domaine.com`

4-Certificat renewal: `docker exec haproxy /docker-certrenew`

5-Install previously create certificate: `docker exec haproxy /docker-certinstall www.domain.com`

 - do it for each certificate, the folder name (/path/to/letsencrypt/<**domain name**>) is the key

6-Apply changes : docker exec haproxy /docker-restart

