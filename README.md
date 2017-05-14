# acme-haproxy docker
not ready for production use

docker run -d --restart always --name haproxy -p 80:80 -p 443:443 -v /path/to/letsencrypt:/root/.acme.sh -v /path/to/haproxy:/etc/haproxy fenrir/acme-haproxy
