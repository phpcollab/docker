# What is phpCollab?

[phpCollab](https://phpcollab.com?utm_source=docker_hub&utm_medium=cpc&utm_campaign=docker_image) is a free and open source project management tool and content management system (CMS) using PHP and MySQL/PostgresSQL, which runs on a web hosting service. Features include task management, file versioning, client area, and much more.

%%LOGO%%

![GitHub Repo stars](https://img.shields.io/github/stars/phpcollab/phpcollab?color=2d609f&logo=github&style=for-the-badge&labelColor=6d6e71) ![GitHub release (latest by date)](https://img.shields.io/github/v/release/phpcollab/phpcollab?color=2d609f&logo=github&style=for-the-badge&labelColor=6d6e71) ![Docker Stars](https://img.shields.io/docker/stars/phpcollab/phpcollab?color=2d609f&logo=docker&logoColor=ffffff&style=for-the-badge&labelColor=6d6e71) ![Docker Pulls](https://img.shields.io/docker/pulls/phpcollab/phpcollab?color=2d609f&logo=docker&logoColor=ffffff&style=for-the-badge&labelColor=6d6e71)

# How to use this image

```console
$ docker run --name %%REPO%% --network some-network -d %%IMAGE%%
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
$ docker run --name some-%%REPO%% -e PHPCOLLAB_DB_PASSWORD_FILE=/run/secrets/mysql-root ... -d %%IMAGE%%:tag
```

Currently, this is supported for `PHPCOLLAB_DB_HOST`, `PHPCOLLAB_DB_USER`, `PHPCOLLAB_DB_PASSWORD`, `PHPCOLLAB_DB_NAME`, `PHPCOLLAB_TABLE_PREFIX`, and `PHPCOLLAB_DEBUG`<sup>1</sup>

## %%STACK%%

Run `docker stack deploy -c stack.yml %%REPO%%` (or `docker-compose -f stack.yml up`), wait for it to initialize completely, and visit `http://swarm-ip:8080`, `http://localhost:8080`, or `http://host-ip:8080` (as appropriate).

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
