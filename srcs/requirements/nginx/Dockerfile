FROM debian:bullseye

RUN apt-get update && apt-get install -y \
nginx \
openssl \ 
&& rm -rf /var/lib/apt/lists/*

RUN usermod -u 33 www-data && groupmod -g 33 www-data

#COPY conf/default.conf /etc/nginx/nginx.conf

COPY tools/script.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/script.sh

EXPOSE 443

ENTRYPOINT ["/usr/local/bin/script.sh"]
