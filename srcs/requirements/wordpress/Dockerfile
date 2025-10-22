FROM debian:bookworm 

RUN apt-get update -y && apt-get install -y \ 
php8.2-fpm \ 
php8.2-mysql \ 
php8.2-curl \ 
php8.2-gd \ 
php8.2-intl \ 
php8.2-mbstring \ 
php8.2-soap \ 
php8.2-xml \ 
php8.2-zip \ 
wget \ 
curl \ 
&& ln -s /usr/sbin/php-fpm8.2 /usr/local/bin/php-fpm \ 
&& rm -rf /var/lib/apt/lists/*


EXPOSE 9000

COPY conf/www.conf /etc/php/8.2/fpm/pool.d/

COPY ./tools/wordpress.sh /usr/local/bin

RUN chmod +x /usr/local/bin/wordpress.sh

ENTRYPOINT ["/usr/local/bin/wordpress.sh"]
