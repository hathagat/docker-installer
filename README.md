# Docker Installer
The purpose of this script is to install Docker and Docker Compose on a Debian based system and to provide a quick way to get applications up and running.

## Usage

- clone or download this repository
- copy sample.env to .env
- edit .env to suit your needs
- run start.sh

You can easily test the Nginx stack by running the [whoami](https://github.com/jwilder/whoami) service like this:
```
docker run --name whoami -e VIRTUAL_HOST=whoami.domain.tld -e LETSENCRYPT_HOST=whoami.domain.tld -e LETSENCRYPT_EMAIL=ssl@domain.tld --net frontends jwilder/whoami
```

## Applications

#### Nginx
- [Nginx](https://hub.docker.com/_/nginx/)
- [docker-gen](https://hub.docker.com/r/jwilder/docker-gen/)
- [Lets Encrypt](https://hub.docker.com/r/jrcs/letsencrypt-nginx-proxy-companion/)

#### DynDNS
- [DynDNS](https://hub.docker.com/r/davd/docker-ddns/)

#### Wordpress
- [Wordpress](https://hub.docker.com/_/wordpress/)
- [MariaDB](https://hub.docker.com/r/webhippie/mariadb/)

#### Nextcloud
- [Nextcloud](https://hub.docker.com/r/wonderfall/nextcloud/)
- [MariaDB](https://hub.docker.com/r/webhippie/mariadb/)
- [Solr](https://hub.docker.com/_/solr/)
- [Redis](https://hub.docker.com/_/redis/)
- [Collabora Online](https://hub.docker.com/r/collabora/code/)

#### Hubzilla
- [Hubzilla](https://hub.docker.com/r/silviof/hubzilla-docker/)
- [MariaDB](https://hub.docker.com/r/webhippie/mariadb/)

##### ...more to come
