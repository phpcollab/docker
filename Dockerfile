FROM php:7.4-apache

RUN set -eux; \
    version='2.8.1'; \
    sed -ri -e 's!/var/www/html!/var/www/phpcollab!g' /etc/apache2/sites-available/*.conf; \
    sed -ri -e 's!/var/www/!/var/www/phpcollab!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf \
    && docker-php-ext-install pdo pdo_mysql mysqli \
    && curl -o phpcollab.tar.gz -fL "https://phpcollab.com/phpcollab-v$version.tar.gz" \
    && tar -xzf phpcollab.tar.gz -C /var/www/ \
    && rm phpcollab.tar.gz \
    && chmod -R 777 /var/www/phpcollab/files \
    && chmod -R 777 /var/www/phpcollab/logos_clients \
    && chmod -R 777 /var/www/phpcollab/logs \
    && chmod -R 777 /var/www/phpcollab/includes

