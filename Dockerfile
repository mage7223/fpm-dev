# Set master image
FROM php:7.4.18-fpm-buster

# Set working directory
WORKDIR /var/www/html

# Install Additional dependencies
RUN apt-get -y update && apt-get -y install apt-transport-https lsb-release ca-certificates curl wget
RUN wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
RUN sh -c 'echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list'


RUN apt-get -y update
RUN apt-get install -y --no-install-recommends vim nano git  gcc musl-dev make openssh-server unzip python

ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/
RUN chmod +x /usr/local/bin/install-php-extensions && sync && \
    install-php-extensions gd xdebug-2.8.1 pdo_mysql mysqli mcrypt mbstring xml openssl json phar zip dom session zlib

# Add and Enable PHP-PDO Extenstions
RUN docker-php-ext-install pdo pdo_mysql
RUN docker-php-ext-enable pdo_mysql
RUN docker-php-ext-install mysqli && docker-php-ext-enable mysqli
RUN echo "xdebug.remote_host=host.docker.internal" >> $(php --ini | grep xde | cut -f 1 -d ,)
RUN echo "xdebug.remote_port=9000" >> $(php --ini | grep xde | cut -f 1 -d ,)
RUN echo "xdebug.remote_enable=1" >> $(php --ini | grep xde | cut -f 1 -d ,)
RUN curl "https://s3.amazonaws.com/aws-cli/awscli-bundle-1.18.69.zip" -o "awscli-bundle.zip" 
RUN unzip awscli-bundle.zip
RUN ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws 
RUN rm -rf awscli-bundle.zip awscli-bundle/ 

RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
RUN chmod a+x wp-cli.phar
RUN mv wp-cli.phar /usr/local/bin/wp

RUN apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false;

# Add UID '1000' to www-data
RUN usermod -u 1000 www-data

# Copy existing application directory permissions
COPY --chown=www-data:www-data . /var/www/html

# Change current user to www
USER www-data

# Expose port 9000 and start php-fpm server
EXPOSE 9000
CMD ["php-fpm"]
