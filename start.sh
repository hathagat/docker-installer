#!/bin/bash
################################################
#            Docker Install Script             #
# https://github.com/hathagat/docker-installer #
################################################

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
    Application Container:

    1)  start Nginx
    2)  start Watchtower
    3)  start Duplicati
    4)  start DynDNS
    5)  start Heimdall
    6)  start Wordpress
    7)  start Gitea
    8)  start Wekan
    9)  start Nextcloud
    10) start Hubzilla
    11) start Tautulli

    q) Quit
----------------------------------------

Please enter your choice:
EOF
    read -n1 -s
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
    "q")  exit ;;
     * )  echo "invalid option" ;;
    esac
    done
}

start_nginx() {
    ln -sf ${SCRIPT_PATH}/.env ${SCRIPT_PATH}/nginx/
    cd ${SCRIPT_PATH}/nginx
    mkdir -p ${DOCKER_DATA_PATH}/nginx
    curl https://raw.githubusercontent.com/jwilder/nginx-proxy/master/nginx.tmpl > ${DOCKER_DATA_PATH}/nginx/nginx.tmpl
    docker-compose up -d
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
}

start_wekan() {
    ln -sf ${SCRIPT_PATH}/.env ${SCRIPT_PATH}/wekan/
    cd ${SCRIPT_PATH}/wekan
    docker-compose up -d
}

start_nextcloud() {
    ln -sf ${SCRIPT_PATH}/.env ${SCRIPT_PATH}/nextcloud/
    cd ${SCRIPT_PATH}/nextcloud

    docker-compose up -d database
    echo "Waiting for the database to start..."
    sleep 10s
    docker-compose up -d
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

command_exists() {
    command -v "$@" > /dev/null 2>&1
}

display_menu
