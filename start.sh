#!/bin/bash
##
## Start up script for httpd on CentOS docker container
##

## Initialise any variables being called:
# Set the correct timezone
TZ=${TZ:-UTC}
PHP_TZ_CONT=`echo $PHP_TZ | awk 'BEGIN { FS="/" } { print $1 }'`
PHP_TZ_CITY=`echo $PHP_TZ | awk 'BEGIN { FS="/" } { print $2 }'`
setup=/config/httpd/.setup
INSTALL_PATH=${INST:-/data/vmb}

## We always want to set the timezone correctly
rm -f /etc/localtime
cp /usr/share/zoneinfo/$TZ /etc/localtime

## Configure the PHP timezone correctly:
if [ "$PHP_TZ_CITY" = "" ]; then
  sed -i "s/;date.timezone =/date.timezone = ${PHP_TZ_CONT}/" /etc/php.ini
else
  sed -i "s/;date.timezone =/date.timezone = ${PHP_TZ_CONT}\/${PHP_TZ_CITY}/" /etc/php.ini
fi

## If this is the first time setting things up, we need to download ViMBAdmin and set up the MariaDB dataabase
if [ ! -f "${setup}" ]; then
  
  ## This is downloading and installing the ViMBAdmin software
  mkdir -p $INSTALL_PATH; cd $INSTALL_PATH
  curl -sS https://getcomposer.org/installer | php
  php composer.phar create-project opensolutions/vimbadmin $INSTALL_PATH -s dev
  chown -R apache:apache $INSTALL_PATH/var
  cp $INSTALL_PATH/application/configs/application.ini.dist $INSTALL_PATH/application/configs/application.ini
    
  ## This is setting up MariaDB with the database for ViMBAdmin
  # Start up the mariadb instance:
  mysqld_safe --basedir=/usr --nowatch
  sleep 10

  # Make sure that NOBODY can access the server without a password - to be updated with a variable for a password ***
  #mysql -e "UPDATE mysql.user SET Password = PASSWORD('CHANGEME') WHERE User = 'root'"

  # Kill the anonymous users
  mysql -e "DROP USER ''@'localhost'"

  # Because our hostname varies we'll use some Bash magic here.
  mysql -e "DROP USER ''@'$(hostname)'"

  # Kill off the demo database
  mysql -e "DROP DATABASE test"

  # Setting up the ViMBAdmin database - need to change the vimbadmin db user password to use a variable at some point ***
  (
      echo "CREATE DATABASE IF NOT EXISTS vimbadmin;"
      echo "GRANT ALL ON vimbadmin.* TO 'vimbadmin'@'localhost' IDENTIFIED BY 'vimbadmin';"
      echo "quit"
  ) |
  mysql
  
  # Make our changes take effect
  mysql -e "FLUSH PRIVILEGES"
  
  # Any subsequent tries to run queries this way will get access denied because lack of usr/pwd param
  # Stop the MariaDB, as it will be controlled via supervisord
  kill `pgrep mysqld`
  
  ## Finalising the VIMBAdmin installation
  cp $INSTALL_PATH/public/.htaccess.dist $INSTALL_PATH/public/.htaccess
  cd $INSTALL_PATH
  ./bin/doctrine2-cli.php orm:schema-tool:create

  echo "You need to alter the application.ini file to have the correct database settings - and the correct salt information when setting ViMBAdmin up"
  touch $setup
fi

## Start up httpd and postfix daemons via supervisord
/usr/bin/supervisord -n -c /etc/supervisord.conf
