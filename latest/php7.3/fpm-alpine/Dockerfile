#
# NOTE: THIS DOCKERFILE IS GENERATED VIA "apply-templates.sh"
#
# PLEASE DO NOT EDIT IT DIRECTLY.
#

FROM php:7.3-fpm-alpine

# persistent dependencies
RUN set -eux; \
    apk add --no-cache \
    # in theory, docker-entrypoint.sh is POSIX-compliant, but priority is a working, consistent image
    bash \
    # BusyBox sed is not sufficient for some of our sed expressions
    sed \
    ;

# install the PHP extensions we need (https://make.wordpress.org/hosting/handbook/handbook/server-environment/#php-extensions)
RUN set -ex; \
    docker-php-ext-install -j "$(nproc)" \
    pdo pdo_mysql mysqli

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN set -eux; \
    docker-php-ext-enable opcache; \
    { \
    echo 'opcache.memory_consumption=128'; \
    echo 'opcache.interned_strings_buffer=8'; \
    echo 'opcache.max_accelerated_files=4000'; \
    echo 'opcache.revalidate_freq=2'; \
    echo 'opcache.fast_shutdown=1'; \
    } > /usr/local/etc/php/conf.d/opcache-recommended.ini

# Mirror WP Logging: https://wordpress.org/support/article/editing-wp-config-php/#configure-error-logging
RUN { \
    # https://www.php.net/manual/en/errorfunc.constants.php
    echo 'error_reporting = E_ERROR | E_WARNING | E_PARSE | E_CORE_ERROR | E_CORE_WARNING | E_COMPILE_ERROR | E_COMPILE_WARNING | E_RECOVERABLE_ERROR'; \
    echo 'display_errors = Off'; \
    echo 'display_startup_errors = Off'; \
    echo 'log_errors = On'; \
    echo 'error_log = /dev/stderr'; \
    echo 'log_errors_max_len = 1024'; \
    echo 'ignore_repeated_errors = On'; \
    echo 'ignore_repeated_source = Off'; \
    echo 'html_errors = Off'; \
    } > /usr/local/etc/php/conf.d/error-logging.ini


RUN set -eux; \
    version='2.8.2'; \
    sha1='0ba2767ea50611c5812f715a35b07fb80c8c118b'; \
    \
    curl -o phpcollab.tar.gz -fL "https://github.com/phpcollab/phpcollab/releases/download/v$version/phpcollab-v$version.tar.gz"; \
    echo "$sha1 *phpcollab.tar.gz" | sha1sum -c -; \
    \
    # upstream tarballs include ./phpcollab/ so this gives us /var/www/phpcollab
    tar -xzf phpcollab.tar.gz -C /var/www/; \
    rm phpcollab.tar.gz; \
    # Patching Installation.php setting the root (remove in v2.8.3)
    sed -ri -e 's!"../!$this->appRoot . "/!g' /var/www/phpcollab/classes/Installation/Installation.php; \
    \
    chown -R www-data:www-data /var/www/phpcollab; \
    # Create a location for the settings volume to be mounted to, and the setting.php to be linked from 
    mkdir -p /var/data/phpcollab; \
    chown -R www-data:www-data /var/data/phpcollab

COPY docker-entrypoint.sh /usr/local/bin/

VOLUME ["/var/www/phpcollab/files", "/var/www/phpcollab/logo_clients", "/var/data/phpcollab"]
WORKDIR /var/www/phpcollab
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["php-fpm"]
