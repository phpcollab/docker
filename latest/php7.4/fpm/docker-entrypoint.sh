#!/bin/bash
set -euo pipefail

# usage: file_env VAR [DEFAULT]
#    ie: file_env 'XYZ_DB_PASSWORD' 'example'
# (will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
#  "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
file_env() {
	local var="$1"
	local fileVar="${var}_FILE"
	local def="${2:-}"
	if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
		echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
		exit 1
	fi
	local val="$def"
	if [ "${!var:-}" ]; then
		val="${!var}"
	elif [ "${!fileVar:-}" ]; then
		val="$(< "${!fileVar}")"
	fi
	export "$var"="$val"
	unset "$fileVar"
}

if [[ "$1" == apache2* ]] || [ "$1" == php-fpm ]; then
	if [ "$(id -u)" = '0' ]; then
		case "$1" in
			apache2*)
				user="${APACHE_RUN_USER:-www-data}"
				group="${APACHE_RUN_GROUP:-www-data}"

				# strip off any '#' symbol ('#1000' is valid syntax for Apache)
				pound='#'
				user="${user#$pound}"
				group="${group#$pound}"
				;;
			*) # php-fpm
				user='www-data'
				group='www-data'
				;;
		esac
	else
		user="$(id -u)"
		group="$(id -g)"
	fi

	envs=(
		PHPCOLLAB_DB_HOST
		PHPCOLLAB_DB_USER
		PHPCOLLAB_DB_PASSWORD
		PHPCOLLAB_DB_NAME
		PHPCOLLAB_DB_TYPE
		PHPCOLLAB_DB_TYPE
    PHPCOLLAB_SITE_URL
    PHPCOLLAB_ADMIN_EMAIL
	)
	haveConfig=
	for e in "${envs[@]}"; do
		file_env "$e"
		if [ -z "$haveConfig" ] && [ -n "${!e}" ]; then
			haveConfig=1
		fi
	done

	# only touch "includes/settings.php" if we have environment-supplied configuration values
	if [ "$haveConfig" ]; then
		while ! curl -s ${PHPCOLLAB_DB_HOST}:3306 > /dev/null; do
			echo waiting for mysql to start
			sleep 3;
		done
		sleep 3;

		if ! TERM=dumb php -- <<'EOPHP'
<?php
use phpCollab\Installation\Installation;

error_reporting(2039);

define('APP_ROOT', dirname(__FILE__));

require_once dirname(__FILE__) . '/vendor/autoload.php';

try {
    $settingsData = array(
        "dbServer" => getenv('PHPCOLLAB_DB_HOST'),
        "dbLogin" => getenv('PHPCOLLAB_DB_USER'),
        "dbPassword" => getenv('PHPCOLLAB_DB_PASSWORD'),
        "dbName" => getenv('PHPCOLLAB_DB_NAME'),
        "databaseType" => getenv('PHPCOLLAB_DB_TYPE'),
        "siteUrl" => getenv('PHPCOLLAB_SITE_URL'),
        "adminEmail" => getenv('PHPCOLLAB_ADMIN_EMAIL'),
        "adminPassword" => bin2hex(openssl_random_pseudo_bytes(5)),
		"loginMethod" => "crypt",
        "appRoot" => APP_ROOT
    );

    $installation = new Installation([
        'dbServer' => $settingsData["dbServer"],
        'dbUsername' => getenv('PHPCOLLAB_DB_USER'),
        'dbPassword' => $settingsData["dbPassword"],
        'dbName' => $settingsData["dbName"],
        'dbType' => $settingsData["databaseType"],
    ], $settingsData["appRoot"]);

    echo <<<SETUP_INTRO
Welcome to \e[1;32m
        _            _____      _ _       _
       | |          / ____|    | | |     | |
  _ __ | |__  _ __ | |     ___ | | | __ _| |__
 | '_ \| '_ \| '_ \| |    / _ \| | |/ _` | '_ \
 | |_) | | | | |_) | |___| (_) | | | (_| | |_) |
 | .__/|_| |_| .__/ \_____\___/|_|_|\__,_|_.__/
 | |         | |
 |_|         |_| \e[0m

SETUP_INTRO;

    /**
     * Sanity checks to make sure we are ready to install
     *
     * Checking for an existing settings.php file
     */
    if (!file_exists($settingsData["appRoot"] . "/includes/settings.php")) {
      if ($installation->setup($settingsData)) {
          // If setup returns true, then output the password to the CLI
          echo <<<ADMIN_PW_OUTPUT
  \e[0;32m==================
  | ADMIN PASSWORD |
  ==================\e[0m
  🔒 The admin password has been set to: {$settingsData["adminPassword"]}
  ==================

  ADMIN_PW_OUTPUT;
      };
    } else {
        echo <<<EXISTING_INSTALL


\e[1;33m=====================================================================================
 ⚠️  WARNING: settings.php file found
    There appears to already be an includes/settings.php file.
    If you have not previously installed phpCollab, please try again.
    For additional help, refer to the README @ https://github.com/phpcollab/docker
=====================================================================================\e[0m

EXISTING_INSTALL;

    }


} catch (PDOException $e) {
    echo <<<EXCEPTION
\e[0;31m==================
❗️ ERROR: Database
==================
{$e}\e[0m

EXCEPTION;
    return false;
} catch (Exception $e) {
    echo <<<EXCEPTION
\e[0;31m==================
❗️ ERROR: Setup
==================
{$e}\e[0m

EXCEPTION;
    return false;
}
?>
EOPHP
			rm -rf installation/
		then
			echo >&2
			echo >&2 "WARNING: unable to establish a database connection to '$PHPCOLLAB_DB_HOST'"
			echo >&2 '  continuing anyways (which might have unexpected results)'
			echo >&2
		fi
	fi

	# now that we're definitely done writing configuration, let's clear out the relevant environment variables (so that stray "phpinfo()" calls don't leak secrets from our code)
	for e in "${envs[@]}"; do
		unset "$e"
	done

  # Delete the phpCollab installation directory
  if [[ -d "/var/www/phpcollab/installation" ]]
  then
     rm -rf /var/www/phpcollab/installation
     echo "Deleted installation directory"
  fi

fi

exec "$@"