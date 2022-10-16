#!/bin/bash

export $(grep -v '^#' .env | xargs)

# Set versions
uberspace tools version use erlang 24
uberspace tools version use postgresql 13

# Setup postgres
echo "#hostname:port:database:username:password (min 64 characters)" >> .pgpass
echo "*:*:*:$(whoami):$DATABASE_PASSWORD" >> .pgpass
chmod 0600 ~/.pgpass

echo "$DATABASE_PASSWORD" >> pgpass.temp
initdb --pwfile ~/pgpass.temp --auth=scram-sha-256 -E UTF8 -D ~/opt/postgresql/data/
rm ~/pgpass.temp

cp ~/opt/postgresql/data/postgresql.conf ~/opt/postgresql/data/postgresql.conf.bak

echo "export PGPASSFILE=$HOME/.pgpass" >> ~/.bash_profile
source ~/.bash_profile

echo "export PGHOST=localhost" >> ~/.bashrc
echo "export PGPORT=5432" >> ~/.bashrc
source ~/.bashrc

sed -i "/#unix_socket_directories =.*/a unix_socket_directories = '/home/$(whoami)/tmp'" ~/opt/postgresql/data/postgresql.conf

# Setup service for postgres
/bin/cat <<EOM >etc/services.d/postgresql.ini
[program:postgresql]
command=postgres -D %(ENV_HOME)s/opt/postgresql/data/
autostart=true
autorestart=true
startsecs=15
EOM

# Add services for elixir app
ENVIRONMENTS=(green blue)
for environment in ${ENVIRONMENTS[@]}; do
  if [ "$environment" = "green" ]; then
    PORT=$PORT_GREEN
  else
    PORT=$PORT_BLUE
  fi

/bin/cat <<EOM >etc/services.d/elixir-$environment.ini
[program:elixir-$environment]
command=%(ENV_HOME)s/$environment/bin/$GIT_REPO start
autostart=false
autorestart=true
startsecs=60
environment =
  DATABASE_URL="ecto://$USER:$DATABASE_PASSWORD@localhost/$GIT_REPO",
  POOL_SIZE="$POOL_SIZE",
  DOMAINS="$DOMAINS",
  SECRET_KEY_BASE="$SECRET_KEY_BASE",
  SMTP_PASSWORD="$SMTP_PASSWORD",
  SMTP_PORT="$SMTP_PORT",
  SMTP_SERVER="$SMTP_SERVER",
  SMTP_USERNAME="$SMTP_USERNAME",
  PORT="$PORT",
  MIX_ENV="prod",
  PHX_SERVER="true",
  STORAGE_PATH="$STORAGE_PATH",
  RELEASE_NODE="$environment"
EOM
done

# Autostart services
supervisorctl reread
supervisorctl update

# Install mix
mix local.hex --force
mix local.rebar --force

# Clone project
git clone https://github.com/$GIT_USER/$GIT_REPO.git

# Add web domains
IFS="," read -a domain_list <<< $DOMAINS
for domain in ${domain_list[@]}; do
  uberspace web domain add $domain
  uberspace web domain add www.$domain
done

# Create database
createdb --encoding=UTF8 --owner=$UBERSPACE_USER $GIT_REPO

# First deploy
chmod +x deploy.sh
./deploy.sh
