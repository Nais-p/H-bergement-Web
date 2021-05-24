# Install Docker

Pour pouvoir avoir les droits sudo il faut ajouter votre user au fichier sudoers dans `emacs /etc/sudoers` et donner les autorisations d'écriture `chmod +w /etc/sudoers` sur le fichier.
Pour le user deployer ajouter ceci dans le fichier `deployer    ALL=(ALL:ALL) ALL` afin d'obtenir tout les droits.


Mise à jour des paquets et ajouts des nouveaux paquets :
* `sudo apt-get update`
* `sudo apt-get install apt-transport-https ca-certificates curl gnupg2 software-properties-common`


Ajout de la clé Docker :
* `curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add`

Installation de Docker :
* `sudo apt-get install docker-ce`
* `sudo systemctl status docker` -> *Voir si le docker run ou non.*
* `docker -v` -> *Commande pour voir la version*.
* `docker run hello-world` -> *Test, l'image ne doit pas fonctionner*.
* `sudo groupadd docker` -> *Création du groupe docker.*
* `sudo usermod -aG docker deployer` -> *Ajout du user au groupe docker.*
* `su -s deployer`
* `sudo reboot` -> *Redémarrage de la machine.*
* `docker run hello-world` -> *Vérification que Docker Engine est correctement installé en exécutant l'image hello-world.*

Donnez tout les droits liées a docker au user deployer :
* `sudo setfacl -R -m u:deployer:rwx /srv` ou `sudo chown -R deployer:deployer /srv/`

## Installation Docker-Compose

Télechargement de la version actuelle de Docker Compose : 
* `sudo curl -L "https://github.com/docker/compose/releases/download/1.29.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose`

Donner les autorisations exécutables :
* `sudo chmod +x /usr/local/bin/docker-compose`

Vérifier si le docker-compose a bien été installé en regardant sa version :
* `docker-compose --version`

# Hébergement Web

Création et configuration des 3 services : Database, Wordpress & File Serving.
Création du `docker-compose.yml` où dedans se trouve une configuration pour chaque service avec le `build` qui consiste à donner le chemin de construction de l'image, `image` pour le nom de l'image avec son tag, `container_name` pour le nom du container ainsi que le `volumes` pour faire persister les données. Pour finir à la fin du fichier on peut trouver un `volumes` qui consiste a appeler les différents volumes de chaque services. 

## Database
Construction d'une image exécutant un serveur MariaDB grâce à un `Dockerfile`.
Le `Dockerfile` est composé de `RUN` pour installer et mêttre à jour les paquets.
Nous avons `COPY` qui sert a copié les fichiers / répertoires dans un système de fichiers du conteneur correspondant à l'image, `CMD` la commande par défaut et pour finir `EXPOSE` pour le numéro de port.

Plus en détails pour le container database nous faisons:
1. Installation de MariaDB, emacs et nmap pour vérifier si le port est ouvert depuis le container database.
2. Récupération du script `maria.sh` pour le coller dans le container et ainsi pouvoir l'utiliser et lancer les commandes qu'il contient.
3. On attribue les droits d'éxecution à notre script et on le lance.
4. On lance le serveur mysqld, le safe est une mesure de	sécurité car il permet le redémarrage du serveur lorsqu'une erreur se produit.
5. On spécifie le port d'exposition.
```
FROM debian:9

RUN apt-get update && apt-get -y install mariadb-server nmap emacs

COPY ./maria.sh /
WORKDIR /
RUN chmod +x maria.sh
RUN /maria.sh
CMD ["mysqld_safe"]

# Expose ports.
EXPOSE 3306

```
Nous avons fait le script `maria.sh` pour créer une base de donnée, un user et lui attribuer les droits. De plus, nous modifions le fichier de configuration mariadb `50-server.cnf` dans `/etc/mysql/mariadb.conf.d` en changeant la ligne `bind-address = 127.0.0.1` par `bind-address = 0.0.0.0` afin que les connexions en locales ne soient plus limitées et donc pouvoir créer notre wordpress.

Nous avons donc dans notre script:
1. Nous commençons par lancer mysql.
2. Nous nous connectons à mysql en tant que root pour pouvoir faire des commandes sql.
3. Dans le cas où il existerait déjà un utilisateur "deployer" nous le supprimons.
4. Puis nous créons l'utilisateur "deployer" et nous lui donnons tous les droits.
5. Enfin nous supprimons la base de donnée "wordpress" si elle existe puis nous la créons avant de notifier la fin des commande sql.
6. Pour finir ce script nous faisons donc le remplacement de ligne dans le fichier `50-server.cnf`

```
#!/bin/bash

/etc/init.d/mysql start

mysql -u root <<MYSQL_SCRIPT
DROP USER IF EXISTS deployer;
CREATE USER 'deployer'@'%' IDENTIFIED BY 'bob';
GRANT ALL PRIVILEGES ON . TO 'deployer'@'%';
DROP DATABASE IF EXISTS wordpress;
CREATE DATABASE wordpress;
FLUSH PRIVILEGES;
MYSQL_SCRIPT

cd /etc/mysql/mariadb.conf.d/
sed -i 's/bind.*/bind-address = 0.0.0.0/' 50-server.cnf
```
Pour finir dans le fichier `docker-compose.yml` nous rajoutons un volume pour la persistance de la base de donnée :
>  volumes:
>       - Maria:/var/lib/mysql

## Wordpress

Construction d'une image qui permet de lancer un serveur web, déployant un site Wordpress grâce a un `Dockerfile`.
Nous gardons la même structure que le `Dockerfile` précedent.

Pour le container wordpress nous avons donc fait:
1. Mise à jour des packages et installation de nginx, php7.0, wget, unzip, php-fpm php-cgi, php-net-socke, php-mysql puis emacs et nmap pour vérifier les ports.
2. On fait appelle à l'option “daemon off;” pour éviter que le conteneur ne se stoppe juste après avoir exécuté la commande (CMD), ce qui est le comportement normal d'un conteneur.
3. On copie le script `wordpress.sh` à la racine de notre container pour pouvoir s'en servir.
4. Nous copions notre configuration dans le `sites-enabled` répertoire, dans lequel Nginx lit au démarrage.
5. On lance nginx.
6. Nous exécutons le script `wordpress.sh` avec un entrypoint.
7. On spécifie le port d'exposition.

```
FROM debian:9

RUN apt-get -y update && apt-get install -y nginx php7.0 wget unzip php-fpm php-cgi php-net-socket nmap emacs && apt-get install php-mysql -y
RUN echo "daemon off;" >> /etc/nginx/nginx.conf

COPY ./wordpress.sh /     
COPY ./nginx.conf /etc/nginx/sites-enabled/.

CMD service nginx start
ENTRYPOINT ["/wordpress.sh"]

# Expose ports.
EXPOSE 80
```

Nous avons fait un script `wordpress.sh` qui récupère le fichier zip d'installation de wordpress et configure wordpress afin d'accéder à notre "site" wordpress.

En détail, nous faisons:
1. On met à jour les packages.
2. Nous nous plaçons dans le dossier /tmp pour télécharger le zip d'installation wordpress.
3. Puis nous supprimons le fichier `/var/www/html/index.html` si il est toujours présent. Il s'agit de la page par défaut de nginx.
4. On stoppe apache pour passer avec nginx.
5. Et nous lançon php7.0-fpm start.

```
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
```

Nous avons aussi fait la configuration de nginx dans `nginx.conf` de manière à ce que nginx puisse servir wordrpress sur le port 80.

```
server {
       listen 80;
       listen [::]:80;

       root /var/www/html;
       index index.php;

    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    location ~ \.php$ {
        include fastcgi.conf;
        fastcgi_pass unix:/run/php/php7.0-fpm.sock;
    }
}
```

Par la suite il y aura une configuration à effectuer dans mariadb pour accepter les communications distantes, pour cela nous faisons ceci (Les manipulations permettant d'ouvrir le port 3306 de la ligne 1 à 7 sont réalisées dans le script `maria.sh`):

1. Aller dans le container de wordpress `docker container exec -ti wordpress bash`
2. nmap <ip du container mariadb> -> Voir si le port 3306 est ouvert. Si il est fermé alors effectuer les changements dans le container maria.
3. `emacs /etc/mysql/mariadb.conf.d/50-server.cnf` -> fichier de conf mariadb
4. Changer la ligne `bind-address = 127.0.0.1` par `bind-address = 0.0.0.0`.
Nous changeons ceci car 127.0.0.1 limite les connexions en locale alors que 0.0.0.0 non.
5. Restart mariadb -> Pour obtenir les modifications.
6. Retourner dans container wordpress
7. Refaire un nmap <ip du container mariadb> -> Voir si le port 3306 est ouvert
8. Ensuite si ouvert récuperer l'IP et se connecter au host sur wordpress `docker inspect <CONTAINER ID>` 

## File Serving

Constructions d'une image nginx avec un `Dockerfile`.
Nous reprenons la même structure que le `Dockerfile` précedent.

```
FROM debian:9

RUN apt-get update && apt-get install -y nginx nmap emacs && apt-get clean && echo "daemon off;" >> /etc/nginx/nginx.conf

COPY ./ser.conf /etc/nginx/sites-enabled/.
COPY ./nginx2.conf /etc/nginx/nginx.conf

CMD service nginx start

EXPOSE 9000
```

Nous avons aussi fait la configuration de nginx dans `ser.conf`.
```
server {
       listen 9000;
       listen [::]:9000;

	root /usr/share/nginx/html;

    location / {
        root /usr/share/nginx/html;
    	index test.html;
    }
}
```

Puis nous repronons le `docker-compose.yml` afin de monter le dossier `./nginx/static` dans le container nginx en mode `read only` grâce aux volumes comme suit:  

> volumes:
>   - "./nginx/static:/var/www/html/static:ro"
> 
> 

Aprés avoir configurer le dossier en **read-only** nous pouvons exécuter les fichiers dans notre navigateur, pour les afficher et les télécharger, pour cela nous faisons de la façon suivant : `Adresse Ip:port/fichier qu'on veux éxecuter` par exemple `http://192.168.1.34:9000/stitch.pdf` pour l'affichage et nous faisons dans notre terminal `wget http://192.168.1.34:9000/stitch.pdf` pour le téléchargement du fichier.
 

Enfin nous avons fait un fichier `nginx2.conf` pour changer notre nginx.conf du container afin de gérer les logs. Ce fichier remplacera le `nginx.conf` déjà existant grâce a la ligne suivante:`COPY ./nginx2.conf /etc/nginx/nginx.conf`qui se situe dans le Dockerfile, pour que notre changement fonctionne. 


# Exposition

Début de la construction d’une image `traefik` sur le port 8080.
Nous gardons la même structure que le Dockerfile précedent.

```
FROM debian:9

RUN apt-get update && apt-get install -y wget

COPY ./traefik.sh /  

#CMD [traefik]

ENTRYPOINT ["/traefik.sh"]

# Expose ports.
EXPOSE 8080
```

Nous avons fait un script `traefik.sh` qui télécharge traefik et qui lui donne les droits d'éxecution.

```
#!/bin/bash

wget https://github.com/traefik/traefik/releases/download/v1.7.30/traefik
chmod +x traefik

exec "$@"
```

# Utilisation du projet.

Après avoir installé docker et récupéré tous les fichiers du dossier /srv sur le repo, nous lançons les containers `docker-compose up --build` pour les construirent et les lancer en même temps ou alors nous pouvons faire un `docker-compose up -d` pour lancer les containers en fond.      
Nous vérifions que les containers se sont bien lancés avec un `docker ps`.

Dans un premier temps, nous pouvons nous rendre sur notre site wordpress avec `ipVm:port` tel que `http://192.168.1.190:80`, nous devrions obtenir les pages de set up du site. Il suffit de suivre la configuration présentée ci-dessous:

En tout premier nous sélectionnons la langue et continuons.
![](https://i.imgur.com/HBsc0Yi.png)

Ensuite nous retournons sur notre terminal, sur lequel nous faisons un `docker ps` pour obetnir l'Id du container, et nous faisons un `docker inspect <Container Id de database>`pour obtenir l'adress Ip de notre container.
![](https://i.imgur.com/HnFK1Ij.png)

Pour finir nous remplissons le formulaire avec les informations créees dans notre `maria.sh` puis grâce à notre commande précedente nous récuperons l'IP de notre container que nous venons coller dans **Adresse de la base de donnée**. 
![](https://i.imgur.com/QmdGFch.png)

Et dans un second temps, nous pouvons nous rendre 





# Commandes Utiles

Lancer les containers et avoir les logs, (erreurs) : `docker-compose up`

Emplacement des volumes: `sudo ls /var/lib/docker/volumes`

Liste des volumes: `docker volume ls`

Supprimer les volumes : `docker volume prune`

Pour lancer/tester sur internet : `curl localhost`

Arrêt des containers et supprime les c, les volumes et les images créés par up : `docker-compose down`

Suppression de toutes les images : `docker image prune -a`

Suppression de tous les containers : `docker system prune`

Stop le run du container : docker stop {id container}, `docker stop 09fdb80f3399`

Supprimer le container : docker rm {id container}, `docker rm 09fdb80f3399`

Voir tous les users dans mariadb : `SELECT User FROM mysql.user;`
