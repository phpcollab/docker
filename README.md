# phpCollab Docker Image

This repository host the source to product a Docker Image for [phpCollab](https://phpcollab.com/?utm_source=dockerhub&utm_medium=cpc&utm_campaign=docker_hub).

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
      - phpcollab:/var/www/phpcollab

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
  phpcollab:
  db:
```
