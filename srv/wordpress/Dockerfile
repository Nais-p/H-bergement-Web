FROM debian:9

RUN apt-get -y update && apt-get install -y nginx php7.0 wget unzip && apt-get install php-mysql -y
          
RUN apt-get -y install php-fpm php-cgi php-net-socket
RUN apt-get -y install nmap emacs

RUN echo "daemon off;" >> /etc/nginx/nginx.conf

COPY ./wordpress.sh /     
COPY ./nginx.conf /etc/nginx/sites-enabled/.

CMD service nginx start
ENTRYPOINT ["/wordpress.sh"]

# Expose ports.
EXPOSE 80