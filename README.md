# docker-centos-vimbadmin
## Apache, Postfix, and ViMBAdmin on CentOS docker image

This docker image creates a latest CentOS dokcer contianer runinng Apache2, Postfix, and ViMBAdmin. ViMBAdmin and Postfix use a MariaDB database which is located on a different docker container. You should supply an environment variable 'TZ' when the container is first run to set the correct timezone in /etc/php.ini - otherwise a default timezone of UTC is used:

    docker run -d --name="centos-mail" --hostname="centos-mail" --cap-add net_raw --cap-add net_admin -e TZ="Europe/London" -v /data/mail:/var/spool/mail -v /data/vmb:/data/vmb -p 80:80 -p 443:443 -p 9006:9006 jervine/docker-centos-vimbadmin

The container requires some extra (non-default) capabilities added. These are added so that the non-root container users can use the ping command. The port 9006 is used for the supervisor daemon. This can be disabled if needs be. The Dockerfile removes and re-adds the iputils package. Again, this is to ensure that the container non-root users can use ping correctly. 

The /var/spool/mail directories should be mapped from a local filesystem with the -v argument.

When first spun up, the web interface can be configured via http://\<docker host\>/vmb
