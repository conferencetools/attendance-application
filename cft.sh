#!/usr/bin/env bash

NETWORK="cft_network"

function setup() {
    MYSQL_PASS=`tr -cd '[:alnum:]' < /dev/urandom | fold -w30 | head -n1`
    BASE_DIR="/var/www/html/"

    LINK_VOLUMES=`find vendor/ -type l -xtype d -exec bash -c 'for file in "${@:2}"; do echo -n "-v "; readlink -fn $file; echo -n ":$1$file "; done' bash $BASE_DIR {} +`

    docker network create $NETWORK
    docker run -d --network $NETWORK --name cft_app -v `pwd`:/var/www/html/ $LINK_VOLUMES \
        php:7.2-fpm-alpine3.7
    docker run -d --network $NETWORK --name cft_web -p 8103:80 -v `pwd`:/var/www/html/ $LINK_VOLUMES \
        nginx:1.13-alpine nginx -c /var/www/html/config/nginx.conf
}

function cleanup(){
    docker stop cft_app
    docker stop cft_web
    docker rm cft_app
    docker rm cft_web

    docker network rm cft_network
}

function dbreset(){
    #@TODO maybe make a copy and restore it instead
    docker exec -ti cft_app php /var/www/html/vendor/bin/doctrine-module orm:schema-tool:drop --force
    docker exec -ti cft_app php /var/www/html/vendor/bin/doctrine-module orm:schema-tool:create
}

case "$1" in
setup)
setup
exit 0
;;


cleanup)
cleanup
exit 0
;;


dbreset)
dbreset
exit 0
;;


*)
echo "Usage: cft.sh {setup|cleanup|dbreset}"
exit 1
;;

esac