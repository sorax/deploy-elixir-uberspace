#!/bin/bash

COPY_FILES=(
  .env
  deploy.sh
  remote.sh
)


function get_config {
  echo ""
  echo "No config present. I need to ask a few things."
  read -p "uberspace user: " UBERSPACE_USER
  read -p "uberspace host: " UBERSPACE_HOST
  echo "===="
  read -p "git-user: " GIT_USER
  read -p "git-repo: " GIT_REPO
  echo "===="
  read -p "domains (comma seperated): " DOMAINS
  read -p "SECRET_KEY_BASE (e.g. mix phx.gen.secret): " SECRET_KEY_BASE
  echo "===="
  read -p "smtp server: " SMTP_SERVER
  read -p "smtp port: " SMTP_PORT
  read -p "smtp username: " SMTP_USERNAME
  read -p "smtp password: " SMTP_PASSWORD
}


function store_config {
  echo "Store config"

  DATABASE_PASSWORD=$(openssl rand -hex 32)

/bin/cat <<EOM >.env
DATABASE_URL=ecto://$UBERSPACE_USER:$DATABASE_PASSWORD@localhost/$GIT_REPO
DATABASE_PASSWORD=$DATABASE_PASSWORD
POOL_SIZE=10

UBERSPACE_HOST=$UBERSPACE_HOST
UBERSPACE_USER=$UBERSPACE_USER

GIT_USER=$GIT_USER
GIT_REPO=$GIT_REPO

DOMAINS=$DOMAINS
SECRET_KEY_BASE=$SECRET_KEY_BASE

SMTP_PASSWORD=$SMTP_PASSWORD
SMTP_PORT=$SMTP_PORT
SMTP_SERVER=$SMTP_SERVER
SMTP_USERNAME=$SMTP_USERNAME

INSTANCE=
PORT_GREEN=4001
PORT_BLUE=4002

MIX_ENV=prod
PHX_SERVER=true

STORAGE_PATH=~/uploads
EOM
}


function copy_files {
  echo "Copy files to server"

  for file in ${COPY_FILES[@]}; do
    scp $file $UBERSPACE_USER@$UBERSPACE_HOST:~/$file
  done
}


function setup_remote {
  echo "Start remote setup"

  ssh -T $UBERSPACE_USER@$UBERSPACE_HOST chmod +x remote.sh
  ssh -T $UBERSPACE_USER@$UBERSPACE_HOST screen -dmS Setup ./remote.sh
}


if [ ! -f ".env" ]; then
  get_config
  store_config
else
  echo "Config exists"
fi
echo "Load config"
source .env
copy_files
setup_remote
echo "Done. Thanks for using this script :-)"
