#!/bin/bash
/etc/init.d/mysql start

mysql -u root <<MYSQL_SCRIPT
CREATE DATABASE wordpress; 
CREATE USER 'deployer'@'%' IDENTIFIED BY 'bob';
GRANT ALL PRIVILEGES ON *.* TO 'deployer'@'%';

# Puis je refresh tout pour que sa fonctionne
FLUSH PRIVILEGES;
MYSQL_SCRIPT

cd /etc/mysql/mariadb.conf.d/
sed -i 's/bind.*/bind-address = 0.0.0.0/' 50-server.cnf

#exec "$@"
