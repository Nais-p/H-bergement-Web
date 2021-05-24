#!/bin/bash

apt-get update 
cd /tmp

wget http://wordpress.org/latest.zip

unzip latest.zip -d /var/www/html

cd /var/www/html

file="index.html"

if [ -f "$file" ] ; then
    rm "$file"
fi

cp -R wordpress/* ./
rm -Rf wordpress

default="/etc/nginx/sites-enabled/default"

if [ -f "$default" ] ; then
    rm "$default"
fi


cd /var/www/
chown -R www-data:www-data  *
chown -R www-data:www-data /var/www/html

service apache2 stop
service php7.0-fpm start

exec "$@"
