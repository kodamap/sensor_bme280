FROM centos:centos7
MAINTAINER Hiroshi KODAMA

RUN yum -y update
RUN yum -y install httpd-tools

COPY nginx.repo /etc/yum.repos.d/
RUN yum -y install nginx
RUN openssl req -new -nodes -x509 -subj "/C=JP/ST=Tokyo/L=XX/O=XX/CN=xx.xx.xx" -days 3650 -keyout /etc/nginx/conf.d/server.key -out /etc/nginx/conf.d/server.crt

COPY run.sh /

RUN chmod 755 /run.sh
CMD ["/run.sh"]
