FROM debian:9

# Install MariaDB.

RUN apt-get update && apt-get -y install mariadb-server && apt-get update


RUN apt-get -y install nmap emacs


COPY ./maria.sh /
WORKDIR /
RUN chmod +x maria.sh
RUN /maria.sh
CMD ["mysqld_safe"]

#ENTRYPOINT ["/maria.sh"]

# Expose ports.
EXPOSE 3306