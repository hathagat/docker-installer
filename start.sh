#!/bin/bash
################################################
#            Docker Install Script             #
# https://github.com/hathagat/docker-installer #
################################################

SCRIPT_PATH="$( cd "$(dirname "$0")" ; pwd -P )"
source ${SCRIPT_PATH}/.env

display_menu() {
    clear
    while :
    do
    cat<<EOF

========================================
    Docker Installer
----------------------------------------
    Basic Installation:
    1) Install Docker
    2) Install or update Docker Compose

    Application Container:
    3) Start or update Nginx
    4) Test Nginx
    5) Start or update DynDNS
    6) Start or update Nextcloud
    7) Start or update Hubzilla

    q) Quit
----------------------------------------

Please enter your choice:
EOF
    read -n1 -s
    case "$REPLY" in
    "1")  clear && echo && install_docker ;;
    "2")  clear && echo && install_docker_compose ;;
    "3")  clear && echo && start_nginx ;;
    "4")  clear && echo && test_nginx ;;
    "5")  clear && echo && start_dyndns ;;
    "6")  clear && echo && start_nextcloud ;;
    "7")  clear && echo && start_hubzilla ;;
    "q")  exit ;;
     * )  echo "invalid option" ;;
    esac
    done
}

install_docker() {
    if command_exists docker; then
        echo "Docker already installed!"
    else
        apt-get -y install apt-transport-https ca-certificates curl gnupg2
        curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg | apt-key add -
        cat >> /etc/apt/sources.list <<END
# Docker
deb [arch=amd64] https://download.docker.com/linux/debian stretch stable
#deb-src [arch=amd64] https://download.docker.com/linux/debian stretch stable

END
        apt-get update
        apt-get -y install docker-ce
    fi
    echo
    docker --version
}

install_docker_compose() {
    curl -L https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    curl -L https://raw.githubusercontent.com/docker/compose/${DOCKER_COMPOSE_VERSION}/contrib/completion/bash/docker-compose -o /etc/bash_completion.d/docker-compose
    echo
    docker-compose --version
}

start_nginx() {
    mkdir -p ${DOCKER_DATA_PATH}/nginx/
    ln -sf ${SCRIPT_PATH}/.env ${SCRIPT_PATH}/nginx/
    cd ${SCRIPT_PATH}/nginx

    curl https://raw.githubusercontent.com/jwilder/nginx-proxy/master/nginx.tmpl > ${DOCKER_DATA_PATH}/nginx/nginx.tmpl
    docker network create proxy_network
    docker-compose up -d
}

test_nginx() {
    docker run -d --name whoami -e VIRTUAL_HOST=whoami.local jwilder/whoami
    sleep 1s
    curl -H "Host: whoami.local" localhost
    docker stop whoami
    sleep 1s
    docker rm whoami
}

start_dyndns() {
    mkdir -p ${DOCKER_DATA_PATH}/dyndns/
    ln -sf ${SCRIPT_PATH}/.env ${SCRIPT_PATH}/dyndns/
    cd ${SCRIPT_PATH}/dyndns
    docker-compose up -d
}


start_nextcloud() {
    mkdir -p ${DOCKER_DATA_PATH}/nextcloud/
    ln -sf ${SCRIPT_PATH}/.env ${SCRIPT_PATH}/nextcloud/
    cd ${SCRIPT_PATH}/nextcloud

    docker-compose up -d database
    echo "Waiting for the database to come up..."
    sleep 15s
    docker-compose up -d
}

start_hubzilla() {
    mkdir -p ${DOCKER_DATA_PATH}/hubzilla/
    ln -sf ${SCRIPT_PATH}/.env ${SCRIPT_PATH}/hubzilla/
    cd ${SCRIPT_PATH}/hubzilla
    docker-compose up -d
}

command_exists() {
    command -v "$@" > /dev/null 2>&1
}

display_menu
