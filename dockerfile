FROM php:7.4-apache

# Change the Apache root from /var/www/html to /var/www/phpcollab
ENV APACHE_DOCUMENT_ROOT /var/www/phpcollab

# Change the HTML root in the apache conf
RUN set -eux; \
    # version should be dynamically generated whent he dockerfile is "built"
    version='2.8.1'; \
    sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf; \
    sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf \
    # Install PDO drivers for MySQL
    && docker-php-ext-install pdo pdo_mysql mysqli \
    # Download and extract the phpcollab release
    && curl -o phpcollab.tar.gz -fL "https://phpcollab.com/phpcollab-v$version.tar.gz" \
    && tar -xzf phpcollab.tar.gz -C /var/www/ \
    && rm phpcollab.tar.gz \
    # Set the necessary permissions for phpCollab folders
	&& chmod -R 777 /var/www/phpcollab/files \
	&& chmod -R 777 /var/www/phpcollab/logos_clients \
	&& chmod -R 777 /var/www/phpcollab/logs \
	&& chmod -R 777 /var/www/phpcollab/includes

