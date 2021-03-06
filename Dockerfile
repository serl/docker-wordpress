FROM php:7-apache
MAINTAINER Sergio Livi <me@serl.it>
LABEL Name=wordpress Build=1

RUN \
    echo 'APT::Install-Suggests "0";' >> /etc/apt/apt.conf.d/01usersetting && \
    echo 'APT::Install-Recommends "0";' >> /etc/apt/apt.conf.d/01usersetting && \
    echo 'APT::Get::Assume-Yes "true";' >> /etc/apt/apt.conf.d/01usersetting && \
    echo 'APT::Get::force-yes "true";' >> /etc/apt/apt.conf.d/01usersetting && \
    echo 'mysql-server mysql-server/root_password password easy' | debconf-set-selections && \
    echo 'mysql-server mysql-server/root_password_again password easy' | debconf-set-selections && \
    apt-get update && apt-get install \
        # Utilities for WP-CLI
        sudo less bash-completion nano \
        # PHP extensions deps
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng12-dev \
        # MySQL
        mysql-server mysql-client \
    && apt-get clean && rm -rf /var/lib/apt/lists/* && \
    # load Apache extensions
    a2enmod rewrite expires && \
    # install PHP extensions
    docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-png-dir=/usr --with-jpeg-dir=/usr/include/ && \
    docker-php-ext-install -j$(nproc) iconv gd mysqli opcache && \
    # set recommended PHP.ini settings, see https://secure.php.net/manual/en/opcache.installation.php
    { \
        echo 'opcache.memory_consumption=128'; \
        echo 'opcache.interned_strings_buffer=8'; \
        echo 'opcache.max_accelerated_files=4000'; \
        echo 'opcache.revalidate_freq=2'; \
        echo 'opcache.fast_shutdown=1'; \
        echo 'opcache.enable_cli=1'; \
    } > /usr/local/etc/php/conf.d/opcache-recommended.ini && \
    # increase upload filesize :)
    { \
        echo 'upload_max_filesize=500M'; \
        echo 'post_max_size=500M'; \
    } > /usr/local/etc/php/conf.d/upload-size.ini && \
    # MySQL credentials, so that any CLI will work freely
    { \
        echo '[client]'; \
        echo 'user=root'; \
        echo 'password=easy'; \
    } > /etc/my.cnf && \
    chmod go-rw /etc/my.cnf && \
    # WP-CLI
    curl -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x /usr/local/bin/wp && \
    curl -o /etc/bash_completion.d/wp https://raw.githubusercontent.com/wp-cli/wp-cli/master/utils/wp-completion.bash

VOLUME /output
VOLUME /var/www/html

ADD container_files/bashrc /root/bashrc
RUN cat /root/bashrc >> /root/.bashrc && rm /root/bashrc
ADD container_files/wordpress-entrypoint.sh /usr/local/bin/wordpress-entrypoint.sh

ENTRYPOINT ["wordpress-entrypoint.sh"]
CMD ["apache2-foreground"]
