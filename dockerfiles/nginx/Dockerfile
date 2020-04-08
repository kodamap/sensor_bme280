FROM nginx:latest
MAINTAINER Hiroshi KODAMA

RUN apt-get update -y
RUN apt-get install certbot python-certbot-nginx cron -y
RUN openssl req -new -nodes -x509 -subj "/C=JP/ST=Tokyo/L=XX/O=XX/CN=xx.xx.xx" -days 3650 -keyout /etc/nginx/conf.d/server.key -out /etc/nginx/conf.d/server.crt

COPY run.sh /
RUN chmod 755 /run.sh
CMD ["/run.sh"]
