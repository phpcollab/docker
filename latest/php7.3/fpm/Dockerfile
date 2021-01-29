#
# NOTE: THIS DOCKERFILE IS GENERATED VIA "apply-templates.sh"
#
# PLEASE DO NOT EDIT IT DIRECTLY.
#

FROM php:7.3-fpm

# persistent dependencies
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
    ; \
    rm -rf /var/lib/apt/lists/*

# install the PHP extensions we need (https://make.wordpress.org/hosting/handbook/handbook/server-environment/#php-extensions)
RUN set -ex; \
    \
    savedAptMark="$(apt-mark showmanual)"; \
    \
    apt-get update; \
    apt-get install -y --no-install-recommends \
    libfreetype6-dev \
    libjpeg-dev \
    libpng-dev \
    libzip-dev \
    ; \
    docker-php-ext-install -j "$(nproc)" \
    pdo pdo_mysql mysqli \
    zip \
    ; \
    # reset apt-mark's "manual" list so that "purge --auto-remove" will remove all build dependencies
apt-mark auto '.*' > /dev/null; \
    apt-mark manual $savedAptMark; \
    ldd "$(php -r 'echo ini_get("extension_dir");')"/*.so \
    | awk '/=>/ { print $3 }' \
    | sort -u \
    | xargs -r dpkg-query -S \
    | cut -d: -f1 \
    | sort -u \
    | xargs -rt apt-mark manual; \
    \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
    rm -rf /var/lib/apt/lists/*

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

# https://wordpress.org/support/article/editing-wp-config-php/#configure-error-logging
RUN { \
    # https://www.php.net/manual/en/errorfunc.constants.php
    # https://github.com/docker-library/wordpress/issues/420#issuecomment-517839670
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
    version='2.8.1'; \
    sha1='1f0a41545a28d12e7364167544c55ade7b7e7814'; \
    \
    curl -o phpcollab.tar.gz -fL "https://phpcollab.com/phpcollab-v$version.tar.gz"; \
    echo "$sha1 *phpcollab.tar.gz" | sha1sum -c -; \
    \
    # upstream tarballs include ./phpcollab/ so this gives us /var/www/phpcollab
    tar -xzf phpcollab.tar.gz -C /var/www/; \
    rm phpcollab.tar.gz; \
    \
    # https://wordpress.org/support/article/htaccess/
    # [ ! -e /var/www/phpcollab/.htaccess ]; \
    # { \
    # echo '# BEGIN phpcollab'; \
    # echo ''; \
    # echo 'RewriteEngine On'; \
    # echo 'RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]'; \
    # echo 'RewriteBase /'; \
    # echo 'RewriteRule ^index\.php$ - [L]'; \
    # echo 'RewriteCond %{REQUEST_FILENAME} !-f'; \
    # echo 'RewriteCond %{REQUEST_FILENAME} !-d'; \
    # echo 'RewriteRule . /index.php [L]'; \
    # echo ''; \
    # echo '# END phpcollab'; \
    # } > /var/www/phpcollab/.htaccess; \
    \
    chown -R www-data:www-data /var/www/phpcollab; \
    # pre-create wp-content (and single-level children) for folks who want to bind-mount themes, etc so permissions are pre-created properly instead of root:root
    # wp-content/cache: https://github.com/docker-library/wordpress/issues/534#issuecomment-705733507
    mkdir wp-content; \
    for dir in /var/www/phpcollab/wp-content/*/ cache; do \
    dir="$(basename "${dir%/}")"; \
    mkdir "wp-content/$dir"; \
    done; \
    chown -R www-data:www-data wp-content; \
    chmod -R 777 wp-content

COPY docker-entrypoint.sh /usr/local/bin/

VOLUME /var/www/phpcollab
WORKDIR /var/www/phpcollab
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["php-fpm"]