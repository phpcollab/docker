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
	)
	haveConfig=
	for e in "${envs[@]}"; do
		file_env "$e"
		if [ -z "$haveConfig" ] && [ -n "${!e}" ]; then
			haveConfig=1
		fi
	done
echo "Here 1: ${haveConfig}"
	# only touch "includes/settings.php" if we have environment-supplied configuration values
	if [ "$haveConfig" ]; then

		if ! TERM=dumb php -- <<'EOPHP'
<?php

include_once '/var/www/phpcollab/includes/library.php';
require_once '/var/www/phpcollab/classes/Installation/Installation.php';
use phpCollab\Installation\Installation;

$databaseInfo = [
	"dbServer" => getenv('PHPCOLLAB_DB_HOST'),
	"dbUsername" => getenv('PHPCOLLAB_DB_USER'),
	"dbPassword" => getenv('PHPCOLLAB_DB_PASSWORD'),
	"dbName" => getenv('PHPCOLLAB_DB_NAME'),
	"dbType" => getenv('PHPCOLLAB_DB_USER')
];

$appRoot = dirname(dirname(__FILE__));
$installation = new Installation($databaseInfo, $appRoot);
$installation->setup([]);

$maxTries = 10;
do {
	$error = false;
	try {
		$installation->setup([]);
	} catch (Exception $e) {
    	fwrite($stderr, 'Caught exception: ' .  $e->getMessage() . "\n");
		$error = true;
	}
	if ($error) {
		--$maxTries;
		if ($maxTries <= 0) {
			exit(1);
		}
		sleep(3);
	}
} while ($mysql->connect_error);
?>
EOPHP
		then
			echo >&2
			echo >&2 "WARNING: unable to establish a database connection to '$PHPCOLLAB_DB_HOST'"
			echo >&2 '  continuing anyways (which might have unexpected results)'
			echo >&2
		fi
	fi

	# now that we're definitely done writing configuration, let's clear out the relevant envrionment variables (so that stray "phpinfo()" calls don't leak secrets from our code)
	for e in "${envs[@]}"; do
		unset "$e"
	done
fi

exec "$@"