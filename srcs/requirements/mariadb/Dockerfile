FROM debian:bullseye

RUN apt-get update && apt-get install -y mariadb-server \
 	&& rm -rf /var/lib/apt/lists/*

COPY ./conf/50-server.cnf /etc/mysql/mariadb.conf.d

COPY tools/init_sql.sh /init_sql.sh
RUN chmod +x /init_sql.sh

EXPOSE 3306

ENTRYPOINT ["/init_sql.sh"]
