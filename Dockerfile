FROM php:7.4-apache as stage

RUN set -eux; \
    version='2.8.1'; \
    curl -o phpcollab.tar.gz -fL "https://phpcollab.com/phpcollab-v$version.tar.gz" \
    && tar -xzf phpcollab.tar.gz -C /var/www/ \
    && cd /var/www/phpcollab \
    && chmod -R 777 files logos_clients logs includes

FROM php:7.4-apache

COPY --from=stage /var/www/phpcollab /var/www/phpcollab

RUN set -eux; \ 
    sed -ri -e 's!/var/www/html!/var/www/phpcollab!g' /etc/apache2/sites-available/*.conf; \
    sed -ri -e 's!/var/www/!/var/www/phpcollab!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf \
    && docker-php-ext-install pdo pdo_mysql mysqli \
