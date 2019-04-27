#!/bin/bash
#################################################
#               Docker Installer                #
#                                               #
# The purpose of this script is to provide a    #
# quick way to get applications up and running. #
#                                               #
# https://github.com/hathagat/docker-installer  #
#################################################

SCRIPT_PATH="$( cd "$(dirname "$0")" ; pwd -P )"
source ${SCRIPT_PATH}/.env
docker network create frontends

display_menu() {
    clear
    while :
    do
    cat<<EOF

========================================
    Docker Installer
----------------------------------------
    Start Application Container:

    1)  Nginx
    2)  Watchtower
    3)  Duplicati
    4)  DynDNS
    5)  Heimdall
    6)  Wordpress
    7)  Gitea
    8)  Wekan
    9)  Nextcloud
    10) Hubzilla
    11) Tautulli
    12) OpenProject
    13) Lychee

    q) Quit
----------------------------------------

Please enter your choice:
EOF
    read
    case "$REPLY" in
    "1")  clear && echo && start_nginx ;;
    "2")  clear && echo && start_watchtower ;;
    "3")  clear && echo && start_duplicati ;;
    "4")  clear && echo && start_dyndns ;;
    "5")  clear && echo && start_heimdall ;;
    "6")  clear && echo && start_wordpress ;;
    "7")  clear && echo && start_gitea ;;
    "8")  clear && echo && start_wekan ;;
    "9")  clear && echo && start_nextcloud ;;
    "10") clear && echo && start_hubzilla ;;
    "11") clear && echo && start_tautulli ;;
    "12") clear && echo && start_openproject ;;
    "13") clear && echo && start_lychee ;;
    "q")  exit ;;
     * )  echo "invalid option" ;;
    esac
    done

    # TODO https://hub.docker.com/search/?q=mail

    # TODO Prometheus und Grafana https://andrewaadland.net/2018/01/18/hosting-your-own-cloud/
}

# TODO alle ymls in den Hauptordner, jede so benannt wie die derzeitigen Unterordenr
# dann Aufruf: docker-compose -f nginx.yml -p <yamlDateiNameBisZumPunkt> up -d

# TODO Proxy Templates können wohl so sehr einfach erstellt werden:
# https://github.com/nextcloud/docker/tree/master/.examples/docker-compose/with-nginx-proxy/mariadb-cron-redis/fpm/proxy

start_nginx() {
    ln -sf ${SCRIPT_PATH}/.env ${SCRIPT_PATH}/nginx/
    cd ${SCRIPT_PATH}/nginx
    mkdir -p ${DOCKER_DATA_PATH}/nginx
    curl https://raw.githubusercontent.com/jwilder/nginx-proxy/master/nginx.tmpl > ${DOCKER_DATA_PATH}/nginx/nginx.tmpl
    docker-compose up -d
    docker logs letsencrypt

    # TODO https://github.com/jwilder/docker-gen/issues/223#issuecomment-271085589
}

test_nginx() {
    docker run -d --name whoami -e VIRTUAL_HOST=whoami.local jwilder/whoami
    sleep 3s
    curl -H "Host: whoami.local" localhost
    docker stop whoami
    sleep 1s
    docker rm whoami
}

start_watchtower() {
    DOCKER_CONFIG="${HOME}/.docker/config.json"
    if [[ ! -f ${DOCKER_CONFIG} ]]
    then
        mkdir -p ${HOME}/.docker
        echo '{\n\n}' >${DOCKER_CONFIG}
    fi

    ln -sf ${SCRIPT_PATH}/.env ${SCRIPT_PATH}/watchtower/
    cd ${SCRIPT_PATH}/watchtower
    docker-compose up -d

    # TODO --stop-timeout ist noch nicht released -> auf Version nach 0.3.0 warten
    # TODO https://github.com/v2tec/watchtower#notifications
}

start_duplicati() {
    ln -sf ${SCRIPT_PATH}/.env ${SCRIPT_PATH}/duplicati/
    cd ${SCRIPT_PATH}/duplicati
    docker-compose up -d
}

start_dyndns() {
    ln -sf ${SCRIPT_PATH}/.env ${SCRIPT_PATH}/dyndns/
    cd ${SCRIPT_PATH}/dyndns
    docker-compose up -d
}

start_heimdall() {
    ln -sf ${SCRIPT_PATH}/.env ${SCRIPT_PATH}/heimdall/
    cd ${SCRIPT_PATH}/heimdall
    docker-compose up -d
}

start_wordpress() {
    ln -sf ${SCRIPT_PATH}/.env ${SCRIPT_PATH}/wordpress/
    cd ${SCRIPT_PATH}/wordpress

    docker-compose up -d database
    echo "Waiting for the database to start..."
    sleep 10s
    docker-compose up -d
}

start_gitea() {
    SSH_PORT=$(echo $SSH_CLIENT | awk '{print $3}')
    echo "SSH_PORT=$SSH_PORT" >> ${SCRIPT_PATH}/.env

    ln -sf ${SCRIPT_PATH}/.env ${SCRIPT_PATH}/gitea/
    cd ${SCRIPT_PATH}/gitea

    docker-compose up -d database
    echo "Waiting for the database to start..."
    sleep 10s
    docker-compose up -d

    # dirty fix for Gitea not setting the domain variable
    echo "Fixing Gitea domain name..."
    while [ ! -f ${DOCKER_DATA_PATH}/gitea/data/gitea/conf/app.ini ]
    do
        sleep 1
    done
    sed -i "/server/a DOMAIN        = ${GITEA_DOMAIN}" ${DOCKER_DATA_PATH}/gitea/data/gitea/conf/app.ini
    docker-compose restart gitea

    # TODO SSH aktivieren und durch den Host schleusen
    # z.B. so: http://www.ateijelo.com/blog/2016/07/09/share-port-22-between-docker-gogs-ssh-and-local-system
}

start_wekan() {
    ln -sf ${SCRIPT_PATH}/.env ${SCRIPT_PATH}/wekan/
    cd ${SCRIPT_PATH}/wekan
    docker-compose up -d
}

# TODO Infos: NC config, nginx, OO Pfade:
# https://help.nextcloud.com/t/onlyoffice-error-while-downloading-the-document-file-to-be-converted/45195/5

start_nextcloud() {
    # TODO eigene Funktion, können dann alle nutzen
    ln -sf ${SCRIPT_PATH}/.env ${SCRIPT_PATH}/nextcloud/
    cd ${SCRIPT_PATH}/nextcloud
    # TODO check, ob nginx läuft. Wenn nicht, start_nginx()

    docker-compose up -d database
    echo "Waiting for the database to start..."
    # TODO https://github.com/blacklabelops/jira#database-wait-feature
    sleep 10s

    update_nc_webserver
    docker-compose up -d --build --force-recreate

    echo "Waiting for Nextcloud to finish startup configuration. This may take some time..."
    SECONDS=0
    while (( $(curl -sL -w "%{http_code}" "https://${NEXTCLOUD_DOMAIN}" -o /dev/null) != $(echo "200") ))
    do
        if [[ "$SECONDS" -ge 600 ]]; then
            docker-compose logs
            docker-compose down
            echo "ERROR: Nextcloud did not start properly!"
            exit 1
        fi
        sleep 1
        ((SECONDS++))
    done

    docker exec nextcloud occ config:system:set trusted_domains 1 --value="nextcloud" >/dev/null

    docker exec nextcloud occ config:system:set redis host --value="redis" >/dev/null
    docker exec nextcloud occ config:system:set redis port --value="6379" >/dev/null
    docker exec nextcloud occ config:system:set redis timeout --value="0.0" >/dev/null
    docker exec nextcloud occ config:system:set redis password --value="${NEXTCLOUD_REDIS_PASS}" >/dev/null
    docker exec nextcloud occ config:system:set filelocking.enabled --value="true" >/dev/null
    docker exec nextcloud occ config:system:set memcache.distributed --value="\OC\Memcache\Redis" >/dev/null
    docker exec nextcloud occ config:system:set memcache.locking --value="\OC\Memcache\Redis" >/dev/null

    install_onlyoffice
    docker-compose restart nextcloud
}


update_nc_webserver() {
    wget -qO ${SCRIPT_PATH}/nextcloud/app/nginx.conf https://raw.githubusercontent.com/benyanke/docker-nextcloud/master/rootfs/nginx/sites-enabled/nginx.conf

    sed -i '/server {/i\
# Onlyoffice variables\
map $http_host $this_host {\
  "" $host;\
  default $http_host;\
}\
map $http_x_forwarded_host $real_host {\
  default $http_x_forwarded_host;\
  "" $this_host;\
}\
' ${SCRIPT_PATH}/nextcloud/app/nginx.conf

    sed -i '/updater|oc/i \
        # Onlyoffice configuration\
        location ~* ^/ds-vpath/ {\
            rewrite /ds-vpath/(.*) /$1  break;\
            proxy_pass http://onlyoffice;\
            proxy_redirect     off;\
\
            client_max_body_size 100m;\
\
            proxy_http_version 1.1;\
            proxy_set_header Upgrade $http_upgrade;\
            proxy_set_header Connection "upgrade";\
\
            proxy_set_header Host $http_host;\
            proxy_set_header X-Real-IP $remote_addr;\
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;\
            proxy_set_header X-Forwarded-Host $real_host/ds-vpath;\
            proxy_set_header X-Forwarded-Proto $real_scheme;\
        }\
' ${SCRIPT_PATH}/nextcloud/app/nginx.conf
}

install_onlyoffice() {
    docker exec nextcloud occ app:install onlyoffice

    docker exec nextcloud occ config:system:set onlyoffice DocumentServerUrl --value="/ds-vpath/" >/dev/null
    docker exec nextcloud occ config:system:set onlyoffice DocumentServerInternalUrl --value="http://onlyoffice/" >/dev/null
    docker exec nextcloud occ config:system:set onlyoffice StorageUrl --value="http://nextcloud:8888/" >/dev/null

    docker exec nextcloud-onlyoffice supervisorctl status all
}

start_hubzilla() {
    ln -sf ${SCRIPT_PATH}/.env ${SCRIPT_PATH}/hubzilla/
    cd ${SCRIPT_PATH}/hubzilla

    docker-compose up -d database
    echo "Waiting for the database to start..."
    sleep 10s
    docker-compose up -d
}

start_tautulli() {
    ln -sf ${SCRIPT_PATH}/.env ${SCRIPT_PATH}/tautulli/
    cd ${SCRIPT_PATH}/tautulli
    docker-compose up -d
}

start_openproject() {
    ln -sf ${SCRIPT_PATH}/.env ${SCRIPT_PATH}/openproject/
    cd ${SCRIPT_PATH}/openproject
    # TODO externe Datenbank hinzufügen
    # siehe "Production" hier: https://hub.docker.com/r/openproject/community/
    # und auch hier: https://www.openproject.org/docker/
    docker-compose up -d
}

start_lychee() {
    # database host in Lychee UI is "database"
    ln -sf ${SCRIPT_PATH}/.env ${SCRIPT_PATH}/lychee/
    cd ${SCRIPT_PATH}/lychee
    # TODO Variablen setzen
    # TODO Nginx hinzufügen: client_max_body_size 0;
    # entweder sauber template anpassen oder halt per sed einfügen...
    docker-compose up -d
}

command_exists() {
    command -v "$@" > /dev/null 2>&1
}

display_menu
