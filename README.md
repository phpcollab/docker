# phpCollab Docker Image

This repository host the source to product a Docker Image for [phpCollab](https://www.phpcollab.com/).

## ... via [`docker stack deploy`](https://docs.docker.com/engine/reference/commandline/stack_deploy/) or [`docker-compose`](https://github.com/docker/compose)

Example `stack.yml` for `phpcollab`:

```yaml
version: "3.1"

services:
  phpcollab:
    image: phpcollab/phpcollab
    restart: always
    ports:
      - 8080:80
    environment:
      PHPCOLLAB_DB_HOST: db
      PHPCOLLAB_DB_USER: exampleuser
      PHPCOLLAB_DB_PASSWORD: examplepass
      PHPCOLLAB_DB_NAME: exampledb
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

Outstanding issues:

- Support Env config
- Fix up entry point
- Setup Error: `Attention: Erase the file setup.php!! We can not remove the file, it's not writtable. Please delete manually.`
