# Base on latest CentOS image
FROM centos:latest

MAINTAINER “Jonathan Ervine” <jon.ervine@gmail.com>
ENV container docker

# Install updates
RUN yum install -y http://mirror.pnl.gov/epel/7/x86_64/e/epel-release-7-5.noarch.rpm
RUN yum install -y httpd postfix supervisor php php-php-gettext php-mbstring php-mcrypt php-mysql php-pdo git-core mariadb-server
RUN yum update -y
RUN yum clean all

ADD supervisord.conf /etc/supervisord.conf
ADD httpd.ini /etc/supervisord.d/httpd.ini
ADD httpd.ini /etc/supervisord.d/mariadb.ini
ADD vimbadmin.conf /etc/httpd/conf.d/vimbadmin.conf
ADD start.sh /usr/sbin/start.sh
RUN chmod 755 /usr/sbin/start.sh

VOLUME /config
VOLUME /data

EXPOSE 25 80 443 3306 9006
ENTRYPOINT ["/usr/sbin/start.sh"]
