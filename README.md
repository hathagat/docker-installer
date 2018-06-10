# Docker Installer
The purpose of this script is to provide a quick way to get applications up and running.

The Nginx stack acts as a proxy which automatically generates new certificates and sets up domains for new applications.

## Usage

- clone or download this repository
- copy sample.env to .env
- edit .env to suit your needs
- run start.sh

You can easily test the Nginx stack by running the [whoami](https://github.com/jwilder/whoami) container like this:
```
docker run --name whoami -e VIRTUAL_HOST=whoami.domain.tld -e LETSENCRYPT_HOST=whoami.domain.tld -e LETSENCRYPT_EMAIL=ssl@domain.tld --net frontends jwilder/whoami
```

## Applications

#### [Nginx](https://hub.docker.com/_/nginx/)
- [docker-gen](https://hub.docker.com/r/jwilder/docker-gen/)
- [Lets Encrypt](https://hub.docker.com/r/jrcs/letsencrypt-nginx-proxy-companion/)

#### [Watchtower](https://hub.docker.com/r/v2tec/watchtower/)

#### [Duplicati](https://hub.docker.com/r/linuxserver/duplicati/)

#### [DynDNS](https://hub.docker.com/r/davd/docker-ddns/)

#### [Heimdall](https://hub.docker.com/r/linuxserver/heimdall/)

#### [Wordpress](https://hub.docker.com/_/wordpress/)
- [MariaDB](https://hub.docker.com/r/webhippie/mariadb/)

#### [Gitea](https://hub.docker.com/r/gitea/gitea/)
- [MariaDB](https://hub.docker.com/r/webhippie/mariadb/)

#### [Wekan](https://hub.docker.com/r/wekanteam/wekan/)
- [MongoDB](https://hub.docker.com/r/library/mongo/)

#### [Nextcloud](https://hub.docker.com/r/wonderfall/nextcloud/)
- [MariaDB](https://hub.docker.com/r/webhippie/mariadb/)
- [Redis](https://hub.docker.com/_/redis/)
- [Collabora Online](https://hub.docker.com/r/collabora/code/)

#### [Hubzilla](https://hub.docker.com/r/silviof/hubzilla-docker/)
- [MariaDB](https://hub.docker.com/r/webhippie/mariadb/)

#### [Tautulli](https://hub.docker.com/r/linuxserver/tautulli/)

##### ...more to come
