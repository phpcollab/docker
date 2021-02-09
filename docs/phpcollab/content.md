# Supported tags and respective `Dockerfile` links

-	[`2.8.2-apache`, `2.8-apache`, `2-apache`, `apache`, `2.8.2`, `2.8`, `2`, `latest`, `2.8.2-php7.4-apache`, `2.8-php7.4-apache`, `2-php7.4-apache`, `php7.4-apache`, `2.8.2-php7.4`, `2.8-php7.4`, `2-php7.4`, `php7.4`](https://github.com/phpcollab/docker/blob/97049d30e0aa1af346423f7c4ef6ae7060cae832/latest/php7.4/apache/Dockerfile)
-	[`2.8.2-fpm`, `2.8-fpm`, `2-fpm`, `fpm`, `2.8.2-php7.4-fpm`, `2.8-php7.4-fpm`, `2-php7.4-fpm`, `php7.4-fpm`](https://github.com/phpcollab/docker/blob/97049d30e0aa1af346423f7c4ef6ae7060cae832/latest/php7.4/php7.4/fpm/Dockerfile)
-	[`2.8.2-fpm-alpine`, `2.8-fpm-alpine`, `2-fpm-alpine`, `fpm-alpine`, `2.8.2-php7.4-fpm-alpine`, `2.8-php7.4-fpm-alpine`, `2-php7.4-fpm-alpine`, `php7.4-fpm-alpine`](https://github.com/phpcollab/docker/blob/97049d30e0aa1af346423f7c4ef6ae7060cae832/latest/php7.4/php7.4/fpm-alpine/Dockerfile)
-	[`2.8.2-php7.3-apache`, `2.8-php7.3-apache`, `2-php7.3-apache`, `php7.3-apache`, `2.8.2-php7.3`, `2.8-php7.3`, `2-php7.3`, `php7.3`](https://github.com/phpcollab/docker/blob/97049d30e0aa1af346423f7c4ef6ae7060cae832/latest/php7.3/apache/Dockerfile)
-	[`2.8.2-php7.3-fpm`, `2.8-php7.3-fpm`, `2-php7.3-fpm`, `php7.3-fpm`](https://github.com/phpcollab/docker/blob/97049d30e0aa1af346423f7c4ef6ae7060cae832/latest/php7.3/fpm/Dockerfile)
-	[`2.8.2-php7.3-fpm-alpine`, `2.8-php7.3-fpm-alpine`, `2-php7.3-fpm-alpine`, `php7.3-fpm-alpine`](https://github.com/phpcollab/docker/blob/97049d30e0aa1af346423f7c4ef6ae7060cae832/latest/php7.3/fpm-alpine/Dockerfile)

# What is phpCollab?

[phpCollab](https:/phpcollab.com?utm_source=docker_hub&utm_medium=cpc&utm_campaign=docker_image) is a free and open source project management tool and content management system (CMS) using PHP and MySQL/PostgresSQL, which runs on a web hosting service. Features include task management, file versioning, client area, and much more.

![phpCollab Logo](logo.png)

![GitHub Repo stars](https://img.shields.io/github/stars/phpcollab/phpcollab?color=2d609f&logo=github&style=for-the-badge&labelColor=6d6e71) ![GitHub release (latest by date)](https://img.shields.io/github/v/release/phpcollab/phpcollab?color=2d609f&logo=github&style=for-the-badge&labelColor=6d6e71) ![Docker Stars](https://img.shields.io/docker/stars/phpcollab/phpcollab?color=2d609f&logo=docker&logoColor=ffffff&style=for-the-badge&labelColor=6d6e71) ![Docker Pulls](https://img.shields.io/docker/pulls/phpcollab/phpcollab?color=2d609f&logo=docker&logoColor=ffffff&style=for-the-badge&labelColor=6d6e71)

# How to use this image

```console
$ docker run --name phpcollab --network some-network -d %%IMAGE%%
```

## Environment variables

The following environment variables are also honored for configuring your phpCollab instance:

| Parameter                      | Function                                        |
|--------------------------------|-------------------------------------------------|
| `-e PHPCOLLAB_DB_HOST=...`     | The name/IP of the database instance            |
| `-e PHPCOLLAB_DB_USER=...`     | Database user name                              |
| `-e PHPCOLLAB_DB_PASSWORD=...` | Database user password                          |
| `-e PHPCOLLAB_DB_NAME=...`     | Name of the database                            |
| `-e PHPCOLLAB_DB_TYPE=...`     | Database type Mysql                             |
| `-e PHPCOLLAB_SITE_URL=...`    | Specify the domain/IP to access the application |
| `-e PHPCOLLAB_ADMIN_EMAIL=...` | Email address of the admin user                 |
| `-v /logos_clients`            | Location of uploaded client logos               |
| `-v /files`                    | Location of uploaded files                      |

If you'd like to be able to access the instance from the host without the container's IP, standard port mappings can be used:

```console
$ docker run --name some-%%REPO%% -p 8080:80 -d %%IMAGE%%
```

Then, access it via `http://localhost:8080` or `http://host-ip:8080` in a browser.

If you'd like to use an external database instead of a `mysql`/`postgres` container, specify the hostname and port with `PHPCOLLAB_DB_HOST` along with the password in `PHPCOLLAB_DB_PASSWORD` and the username in `PHPCOLLAB_DB_USER` (if it is something other than `root`):

```console
$ docker run --name some-%%REPO%% -e PHPCOLLAB_DB_HOST=10.1.2.3:3306 \
    -e PHPCOLLAB_DB_USER=... -e PHPCOLLAB_DB_PASSWORD=... -d %%IMAGE%%
```

## Docker Secrets

As an alternative to passing sensitive information via environment variables, `_FILE` may be appended to the previously listed environment variables, causing the initialization script to load the values for those variables from files present in the container. In particular, this can be used to load passwords from Docker secrets stored in `/run/secrets/<secret_name>` files. For example:

```console
$ docker run --name some-phpcollab -e PHPCOLLAB_DB_PASSWORD_FILE=/run/secrets/mysql-root ... -d %%IMAGE%%:tag
```

Currently, this is supported for `PHPCOLLAB_DB_HOST`, `PHPCOLLAB_DB_USER`, `PHPCOLLAB_DB_PASSWORD`, `PHPCOLLAB_DB_NAME`, `PHPCOLLAB_TABLE_PREFIX`, and `PHPCOLLAB_DEBUG`<sup>1</sup>

## ... via [`docker stack deploy`](https://docs.docker.com/engine/reference/commandline/stack_deploy/) or [`docker-compose`](https://github.com/docker/compose)

Example `stack.yml` for `phpcollab`:

```yaml
version: "3.1"

services:
  phpcollab:
    image: phpcollab/phpcollab:latest
    restart: always
    ports:
      - 8080:80
    environment:
      PHPCOLLAB_DB_HOST: db
      PHPCOLLAB_DB_USER: exampleuser
      PHPCOLLAB_DB_PASSWORD: examplepass
      PHPCOLLAB_DB_NAME: exampledb
      PHPCOLLAB_DB_TYPE: mysql
      PHPCOLLAB_SITE_URL: http://localhost:8080
      PHPCOLLAB_ADMIN_EMAIL: admin@example.com
    volumes:
      - phpcollab_files:/var/www/phpcollab/files
      - phpcollab_logos_clients:/var/www/phpcollab/logo_clients
      - phpcollab_settings:/var/data/phpcollab

  db:
    image: mysql:5.7
    restart: always
    environment:
      MYSQL_DATABASE: exampledb
      MYSQL_USER: exampleuser
      MYSQL_PASSWORD: examplepass
      MYSQL_RANDOM_ROOT_PASSWORD: "1"
    volumes:
      - db:/var/lib/mysql

volumes:
  phpcollab_files:
  phpcollab_logos_clients:
  phpcollab_settings:
  db:
```

[![Try in PWD](https://github.com/play-with-docker/stacks/raw/cff22438cb4195ace27f9b15784bbb497047afa7/assets/images/button.png)](http://play-with-docker.com?stack=https://raw.githubusercontent.com/phpcollab/docker/master/stack.yml)

Run `docker stack deploy -c stack.yml phpcollab` (or `docker-compose -f stack.yml up`), wait for it to initialize completely, and visit `http://swarm-ip:8080`, `http://localhost:8080`, or `http://host-ip:8080` (as appropriate).

The following Docker Hub features can help with the task of keeping your dependent images up-to-date:

-	[Automated Builds](https://docs.docker.com/docker-hub/builds/) let Docker Hub automatically build your Dockerfile each time you push changes to it.

## Persisting data and uploaded files

Mount a local volume mapped to the following locations. Ensure read/write/execute permissions are in place for the user.

-	Files go in a subdirectory in `/var/www/phpcollab/files`
-	Client logos go in a subdirectory in `/var/www/phpcollab/logos_clients`
-	Settings file goes in `/var/data/phpcollab`

| Parameter                                                    | Function                                 |
|--------------------------------------------------------------|------------------------------------------|
| `-v phpcollab_files:/var/www/phpcollab/files`                | Location where uploaded files are stored |
| `-v phpcollab_logos_clients:/var/www/phpcollab/logo_clients` | Location where client logos are stored   |
| `-v phpcollab_settings:/var/data/phpcollab`                  | Location where settings.php is stored    |

## Configuring PHP directives

See [the "Configuration" section of the `php` image documentation](https://hub.docker.com/_/php/).

For example, to adjust common `php.ini` flags like `upload_max_filesize`, you could create a `custom.ini` with the desired parameters and place it in the `$PHP_INI_DIR/conf.d/` directory.
