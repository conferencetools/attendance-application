#!/usr/bin/env bash

NETWORK="cft_network"
APP_CONTAINER="cft_app"
WEB_CONTAINER="cft_web"
APP_IMAGE="php:7.3-fpm-alpine3.10-gd-mysql"
WEB_IMAGE="nginx:1.17-alpine"

function installComposer() {
    EXPECTED_SIGNATURE="$(wget -q -O - https://composer.github.io/installer.sig)"
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    ACTUAL_SIGNATURE="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"

    if [ "$EXPECTED_SIGNATURE" != "$ACTUAL_SIGNATURE" ]
    then
        >&2 echo 'ERROR: Invalid composer installer signature'
        rm composer-setup.php
        exit 1
    fi

    php composer-setup.php --quiet
    RESULT=$?
    rm composer-setup.php
    return $RESULT
}

function install() {
    command -v jq >/dev/null 2>&1 || { echo >&2 "jq is required to support local development of composer packages, please install using your OS package manager before continuing"; exit 1; }
    command -v php >/dev/null 2>&1 || { echo >&2 "php (>=7.2) is required to run this installer, please install using your OS package manager before continuing"; exit 1; }
    command -v git >/dev/null 2>&1 || { echo >&2 "git is required to support local development of composer packages, please install using your OS package manager before continuing"; exit 1; }

    echo "+ Building development docker container"
    docker build -t $APP_IMAGE -f dev/Dockerfile .

    echo "+ Installing modules for local development"

    [ -d ../admin-module ] || $(cd ../ && git clone git@github.com:conferencetools/admin-module.git)
    [ -d ../attendance-module ] || $(cd ../ && git clone git@github.com:conferencetools/attendance-module.git)
    [ -d ../auth-module ] || $(cd ../ && git clone git@github.com:conferencetools/auth-module.git)
    [ -d ../stripe-payment-provider-module ] || $(cd ../ && git clone git@github.com:conferencetools/stripe-payment-provider-module.git)
    [ -d ../messaging-module ] || $(cd ../ && git clone git@github.com:conferencetools/messaging-module.git)

    echo "+ Conference tools modules cloned, you may wish to manually run composer install in each to support IDE auto completion"

    echo "+ Installing composer"
    installComposer

    echo "+ Installing dependencies"
    if [ -f composer.local.json ]; then
        echo "+ composer.local.json already exists, not overwriting. If install fails, you may need to delete this file or manually edit to match the distributed file"
    else
        cp composer.local.json.dist composer.local.json
    fi;

    composer install
}

function up() {
    docker container start $APP_CONTAINER
    docker container start $WEB_CONTAINER

    echo "+ Application running at http://localhost:8103"

    if [ ! -f data/db.sqlite ]; then
        dbreset
    fi;
}

function down() {
    docker container stop $APP_CONTAINER
    docker container stop $WEB_CONTAINER
}

function create() {
    MYSQL_PASS=`tr -cd '[:alnum:]' < /dev/urandom | fold -w30 | head -n1`
    BASE_DIR="/var/www/html/"

    LINK_VOLUMES=`find vendor/ -type l -xtype d -exec bash -c 'for file in "${@:2}"; do echo -n "-v "; readlink -fn $file; echo -n ":$1$file "; done' bash $BASE_DIR {} +`

    docker network inspect $NETWORK > /dev/null 2>&1 || docker network create $NETWORK
    docker container inspect $APP_CONTAINER > /dev/null 2>&1 || docker container create --network $NETWORK --name $APP_CONTAINER --env-file app.env \
        -v `pwd`:$BASE_DIR $LINK_VOLUMES $APP_IMAGE
    docker container inspect $WEB_CONTAINER > /dev/null 2>&1 || docker container create --network $NETWORK --name $WEB_CONTAINER -p 8103:80 -v `pwd`:$BASE_DIR $LINK_VOLUMES \
        $WEB_IMAGE nginx -c /var/www/html/config/nginx.conf

    up
}

function destroy(){
    down

    docker rm $APP_CONTAINER
    docker rm $WEB_CONTAINER

    docker network rm $NETWORK
}

function dbreset(){
    #@TODO maybe make a copy and restore it instead
    docker exec -ti cft_app php /var/www/html/vendor/bin/doctrine-module orm:schema-tool:drop --force
    docker exec -ti cft_app php /var/www/html/vendor/bin/doctrine-module orm:schema-tool:create
    echo "+ Creating default admin user [username: admin, password: Password1]"
    ADMIN_PASS=`php -r "echo password_hash('Password1', \PASSWORD_DEFAULT);"`
    docker exec -ti cft_app php /var/www/html/vendor/bin/doctrine-module dbal:run-sql "INSERT INTO User (username, password, permissions) values ('admin', '$ADMIN_PASS', '[\"tickets\",\"orders\",\"discounts\",\"reports\",\"user-management\"]')"
    docker exec -ti cft_app chown -R www-data /var/www/html/data
}

function dbdiff() {
    docker exec -ti cft_app php /var/www/html/vendor/bin/doctrine-module orm:schema-tool:update --dump-sql
}

function dbmigrate() {
    docker exec -ti cft_app php /var/www/html/vendor/bin/doctrine-module orm:schema-tool:update --dump-sql
    docker exec -ti cft_app php /var/www/html/vendor/bin/doctrine-module orm:schema-tool:update --force
}

function runcron() {
    docker exec -ti cft_app php /var/www/html/vendor/bin/cli phactor:cron 
}

function composer() {
    jq -s ".[0] * .[1]" composer.json composer.local.json > composer.dev.json
    COMPOSER=composer.dev.json php composer.phar "$@"
    rm composer.dev.json
    [ -e "composer.dev.lock" ] && rm composer.dev.lock
}

function env() {
  case "$1" in
    create)
      create
      exit 0
      ;;

    destroy)
      destroy
      exit 0
      ;;

    up)
      up
      exit 0
      ;;

    down)
      down
      exit 0
      ;;

    *)
      echo "Usage: cft.sh env {create|destroy|up|down}"
      exit 1
      ;;
  esac
}

function db() {
  case "$1" in
  reset)
    dbreset
    exit 0
    ;;

  migrate)
    dbmigrate
    exit 0
    ;;

  diff)
    dbdiff
    exit 0
    ;;

  *)
    echo "Usage: cft.sh db {reset|migrate|diff}"
    exit 1
    ;;
  esac
}

case "$1" in
install)
  install
  exit 0
  ;;

env)
  shift
  env "$@"
  exit 0
  ;;

db)
  shift
  db "$@"
  exit 0
  ;;

runcron)
  runcron
  exit 0
  ;;

composer)
  shift
  composer "$@"
  exit 0
  ;;

*)
  echo "Usage: cft.sh {install|env|db|runcron|composer}"
  exit 1
  ;;

esac
