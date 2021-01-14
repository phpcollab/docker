FROM php:7.4-apache

# Change the Apache root from /var/www/html to /var/www/phpcollab
ENV APACHE_DOCUMENT_ROOT /var/www/phpcollab

# Change the HTML root in the apache conf
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf; \
    sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf \
    
    # Install PDO drivers for MySQL and PostgreSQL
    && docker-php-ext-install pdo pdo_mysql mysqli \
    && docker-php-ext-install pdo pdo_pgsql \

    # Download and extract the phpcollab release
    && curl -o phpcollab.tar.gz -fL "https://phpcollab.com/phpcollab-v2.8.1.tar.gz" \
    && tar -xzf phpcollab.tar.gz -C /var/www/ \
    && phpcollab.tar.gz

