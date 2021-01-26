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

	# allow any of these "Authentication Unique Keys and Salts." to be specified via
	# environment variables with a "PHPCOLLAB_" prefix (ie, "PHPCOLLAB_AUTH_KEY")
	uniqueEnvs=(
		AUTH_KEY
		SECURE_AUTH_KEY
		LOGGED_IN_KEY
		NONCE_KEY
		AUTH_SALT
		SECURE_AUTH_SALT
		LOGGED_IN_SALT
		NONCE_SALT
	)
	envs=(
		PHPCOLLAB_DB_HOST
		PHPCOLLAB_DB_USER
		PHPCOLLAB_DB_PASSWORD
		PHPCOLLAB_DB_NAME
		PHPCOLLAB_DB_CHARSET
		PHPCOLLAB_DB_COLLATE
		"${uniqueEnvs[@]/#/PHPCOLLAB_}"
		PHPCOLLAB_TABLE_PREFIX
		PHPCOLLAB_DEBUG
		PHPCOLLAB_CONFIG_EXTRA
	)
	haveConfig=
	for e in "${envs[@]}"; do
		file_env "$e"
		if [ -z "$haveConfig" ] && [ -n "${!e}" ]; then
			haveConfig=1
		fi
	done
echo "Here 1: ${haveConfig}"
	# linking backwards-compatibility
	if [ -n "${!MYSQL_ENV_MYSQL_*}" ]; then
		haveConfig=1
		# host defaults to "mysql" below if unspecified
		: "${PHPCOLLAB_DB_USER:=${MYSQL_ENV_MYSQL_USER:-root}}"
		if [ "$PHPCOLLAB_DB_USER" = 'root' ]; then
			: "${PHPCOLLAB_DB_PASSWORD:=${MYSQL_ENV_MYSQL_ROOT_PASSWORD:-}}"
		else
			: "${PHPCOLLAB_DB_PASSWORD:=${MYSQL_ENV_MYSQL_PASSWORD:-}}"
		fi
		: "${PHPCOLLAB_DB_NAME:=${MYSQL_ENV_MYSQL_DATABASE:-}}"
	fi
echo "Here 2: ${haveConfig}"
	# only touch "includes/settings.php" if we have environment-supplied configuration values
	if [ "$haveConfig" ]; then
		: "${PHPCOLLAB_DB_HOST:=mysql}"
		: "${PHPCOLLAB_DB_USER:=root}"
		: "${PHPCOLLAB_DB_PASSWORD:=}"
		: "${PHPCOLLAB_DB_NAME:=phpollab}"
echo "Here 3: ${haveConfig}"
		if [ ! -e includes/settings.php ]; then
			awk '
				/^\/\*.*stop editing.*\*\/$/ && c == 0 {
					c = 1
					system("cat")
					if (ENVIRON["PHPCOLLAB_CONFIG_EXTRA"]) {
						print "// PHPCOLLAB_CONFIG_EXTRA"
						print ENVIRON["PHPCOLLAB_CONFIG_EXTRA"] "\n"
					}
				}
				{ print }
			' includes/settings_default.php > includes/settings.php <<'EOPHP'
// If we're behind a proxy server and using HTTPS, we need to alert phpCollab of that fact
// see also http://codex.wordpress.org/Administration_Over_SSL#Using_a_Reverse_Proxy
if (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && $_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {
	$_SERVER['HTTPS'] = 'on';
}

EOPHP
			chown "$user:$group" includes/settings.php
		elif [ -e includes/settings.php ] && [ -n "$PHPCOLLAB_CONFIG_EXTRA" ] && [[ "$(< includes/settings.php)" != *"$PHPCOLLAB_CONFIG_EXTRA"* ]]; then
			# (if the config file already contains the requested PHP code, don't print a warning)
			echo >&2
			echo >&2 'WARNING: environment variable "PHPCOLLAB_CONFIG_EXTRA" is set, but "includes/settings.php" already exists'
			echo >&2 '  The contents of this variable will _not_ be inserted into the existing "includes/settings.php" file.'
			echo >&2 '  (see https://github.com/docker-library/wordpress/issues/333 for more details)'
			echo >&2
		fi

		# see http://stackoverflow.com/a/2705678/433558
		sed_escape_lhs() {
			echo "$@" | sed -e 's/[]\/$*.^|[]/\\&/g'
		}
		sed_escape_rhs() {
			echo "$@" | sed -e 's/[\/&]/\\&/g'
		}
		php_escape() {
			local escaped="$(php -r 'var_export(('"$2"') $argv[1]);' -- "$1")"
			if [ "$2" = 'string' ] && [ "${escaped:0:1}" = "'" ]; then
				escaped="${escaped//$'\n'/"' + \"\\n\" + '"}"
			fi
			echo "$escaped"
		}
		set_config() {
			key="$1"
			value="$2"
			var_type="${3:-string}"
			start="(['\"])$(sed_escape_lhs "$key")\2\s*,"
			end="\);"
			if [ "${key:0:1}" = '$' ]; then
				start="^(\s*)$(sed_escape_lhs "$key")\s*="
				end=";"
			fi
			sed -ri -e "s/($start\s*).*($end)$/\1$(sed_escape_rhs "$(php_escape "$value" "$var_type")")\3/" includes/settings.php
		}

		set_config 'MYSERVER' "$PHPCOLLAB_DB_HOST"
		set_config 'MYLOGIN' "$PHPCOLLAB_DB_USER"
		set_config 'MYPASSWORD' "$PHPCOLLAB_DB_PASSWORD"
		set_config 'MYDATABASE' "$PHPCOLLAB_DB_NAME"

		for unique in "${uniqueEnvs[@]}"; do
			uniqVar="PHPCOLLAB_$unique"
			if [ -n "${!uniqVar}" ]; then
				set_config "$unique" "${!uniqVar}"
			else
				# if not specified, let's generate a random value
				currentVal="$(sed -rn -e "s/define\(\s*(([\'\"])$unique\2\s*,\s*)(['\"])(.*)\3\s*\);/\4/p" includes/settings.php)"
				if [ "$currentVal" = 'put your unique phrase here' ]; then
					set_config "$unique" "$(head -c1m /dev/urandom | sha1sum | cut -d' ' -f1)"
				fi
			fi
		done

		if [ "$PHPCOLLAB_TABLE_PREFIX" ]; then
			set_config '$table_prefix' "$PHPCOLLAB_TABLE_PREFIX"
		fi

		if ! TERM=dumb php -- <<'EOPHP'
<?php
// database might not exist, so let's try creating it (just to be safe)

$stderr = fopen('php://stderr', 'w');

// https://codex.wordpress.org/Editing_wp-config.php#MySQL_Alternate_Port
//   "hostname:port"
// https://codex.wordpress.org/Editing_wp-config.php#MySQL_Sockets_or_Pipes
//   "hostname:unix-socket-path"
list($host, $socket) = explode(':', getenv('PHPCOLLAB_DB_HOST'), 2);
$port = 0;
if (is_numeric($socket)) {
	$port = (int) $socket;
	$socket = null;
}
$user = getenv('PHPCOLLAB_DB_USER');
$pass = getenv('PHPCOLLAB_DB_PASSWORD');
$dbName = getenv('PHPCOLLAB_DB_NAME');

$maxTries = 10;
do {
	$mysql = new mysqli($host, $user, $pass, '', $port, $socket);
	if ($mysql->connect_error) {
		fwrite($stderr, "\n" . 'MySQL Connection Error: (' . $mysql->connect_errno . ') ' . $mysql->connect_error . "\n");
		--$maxTries;
		if ($maxTries <= 0) {
			exit(1);
		}
		sleep(3);
	}
} while ($mysql->connect_error);

if (!$mysql->query('CREATE DATABASE IF NOT EXISTS `' . $mysql->real_escape_string($dbName) . '`')) {
	fwrite($stderr, "\n" . 'MySQL "CREATE DATABASE" Error: ' . $mysql->error . "\n");
	$mysql->close();
	exit(1);
}

$mysql->close();
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