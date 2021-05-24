FROM debian:9

RUN apt-get update && apt-get install -y nginx && apt-get clean && echo "daemon off;" >> /etc/nginx/nginx.conf
RUN apt-get -y install nmap emacs

COPY ./ser.conf /etc/nginx/sites-enabled/.
COPY ./nginx2.conf /etc/nginx/nginx.conf

CMD service nginx start

EXPOSE 9000