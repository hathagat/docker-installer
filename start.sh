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
    14) Jellyfin

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
    "14") clear && echo && start_jellyfin ;;
    "q")  exit ;;
     * )  echo "invalid option" ;;
    esac
    done
}

# Configuration:
# https://github.com/jwilder/nginx-proxy#per-virtual_host
# https://github.com/jwilder/nginx-proxy#per-virtual_host-location-configuration
start_nginx() {
    ln -sf ${SCRIPT_PATH}/.env ${SCRIPT_PATH}/nginx/
    cd ${SCRIPT_PATH}/nginx
    mkdir -p ${DOCKER_DATA_PATH}/nginx
    curl https://raw.githubusercontent.com/jwilder/nginx-proxy/master/nginx.tmpl > ${DOCKER_DATA_PATH}/nginx/nginx.tmpl
    sed -i '/access_log off;/i server_tokens off;' ${DOCKER_DATA_PATH}/nginx/nginx.tmpl

    docker-compose up -d
    docker logs letsencrypt
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
}

start_wekan() {
    ln -sf ${SCRIPT_PATH}/.env ${SCRIPT_PATH}/wekan/
    cd ${SCRIPT_PATH}/wekan
    docker-compose up -d
}

# https://help.nextcloud.com/t/onlyoffice-error-while-downloading-the-document-file-to-be-converted/45195/5

start_nextcloud() {
    ln -sf ${SCRIPT_PATH}/.env ${SCRIPT_PATH}/nextcloud/
    cd ${SCRIPT_PATH}/nextcloud

    docker-compose up -d database
    echo "Waiting for the database to start..."
    # WAIT-FOR: https://docs.docker.com/compose/startup-order/
    sleep 10s

    update_nc_webserver
    set_coturn_config
    set_readonlyrest_config
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
    install_fulltextsearch

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

set_coturn_config() {
    wget -qO turnserver.conf https://raw.githubusercontent.com/coturn/coturn/master/examples/etc/turnserver.conf

    #sed -i "s/^#external-ip/external-ip=???/g" turnserver.conf
    sed -i "s/^#log-file/log-file=stdout/g" turnserver.conf
    sed -i "s/^#min-port/min-port=49160/g" turnserver.conf
    sed -i "s/^#max-port/max-port=49200/g" turnserver.conf
    sed -i "s/^#listening-port/listening-port=3478/g" turnserver.conf
    sed -i "s/^#fingerprint/fingerprint/g" turnserver.conf
    sed -i "s/^#lt-cred-mech/lt-cred-mech/g" turnserver.conf
    sed -i "s/^#use-auth-secret/use-auth-secret/g" turnserver.conf
    sed -i "s/^#static-auth-secret/static-auth-secret=${NEXTCLOUD_TURN_SECRET}/g" turnserver.conf
    sed -i "s/^#realm/realm=${NEXTCLOUD_DOMAIN}/g" turnserver.conf
    sed -i "s/^#total-quota/total-quota=100/g" turnserver.conf
    sed -i "s/^#bps-capacity/bps-capacity=0/g" turnserver.conf
    sed -i "s/^#stale-nonce/stale-nonce/g" turnserver.conf
    sed -i "s/^#no-loopback-peers/no-loopback-peers/g" turnserver.conf
    sed -i "s/^#no-multicast-peers/no-multicast-peers/g" turnserver.conf
    sed -i "s/^#no-tlsv1/no-tlsv1/g" turnserver.conf
    sed -i "s/^#no-tlsv1_1/no-tlsv1_1/g" turnserver.conf

    mkdir -p ${DOCKER_DATA_PATH}/nextcloud/turn
    mv turnserver.conf ${DOCKER_DATA_PATH}/nextcloud/turn/turnserver.conf
}

install_onlyoffice() {
    docker exec nextcloud occ app:install onlyoffice

    docker exec nextcloud occ config:system:set onlyoffice DocumentServerUrl --value="/ds-vpath/" >/dev/null
    docker exec nextcloud occ config:system:set onlyoffice DocumentServerInternalUrl --value="http://onlyoffice/" >/dev/null
    docker exec nextcloud occ config:system:set onlyoffice StorageUrl --value="http://nextcloud:8888/" >/dev/null

    docker exec nextcloud-onlyoffice supervisorctl status all
}

set_readonlyrest_config() {
    # Place current version of https://readonlyrest.com/download/ in elasticsearch folder and edit Dockerfile.
    sed -i "s/^username: USER/username: ${NEXTCLOUD_FTS_USER}/g" ${SCRIPT_PATH}/nextcloud/elasticsearch/readonlyrest.yml
    sed -i "s/^auth_key: USER:PASS/auth_key: ${NEXTCLOUD_FTS_USER}:${NEXTCLOUD_FTS_PASS}/g" ${SCRIPT_PATH}/nextcloud/elasticsearch/readonlyrest.yml
}

install_fulltextsearch() {
    # https://www.elastic.co/guide/en/elasticsearch/reference/current/vm-max-map-count.html
    echo "vm.max_map_count=262144" >> /etc/sysctl.conf && sysctl -p

    docker exec nextcloud occ app:install fulltextsearch
    docker exec nextcloud occ app:install fulltextsearch_elasticsearch
    docker exec nextcloud occ app:install files_fulltextsearch
    #docker exec nextcloud occ app:install bookmarks_fulltextsearch

    # https://github.com/nextcloud/fulltextsearch/wiki/Basic-Installation#first-index
    docker exec nextcloud occ fulltextsearch:index
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

    docker-compose up -d
}

start_lychee() {
    # database host in Lychee UI is "database"
    ln -sf ${SCRIPT_PATH}/.env ${SCRIPT_PATH}/lychee/
    cd ${SCRIPT_PATH}/lychee

    docker-compose up -d
}

start_jellyfin() {
    ln -sf ${SCRIPT_PATH}/.env ${SCRIPT_PATH}/jellyfin/
    cd ${SCRIPT_PATH}/jellyfin

    docker-compose up -d
}

command_exists() {
    command -v "$@" > /dev/null 2>&1
}

display_menu
