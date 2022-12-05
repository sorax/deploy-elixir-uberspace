#!/bin/bash

export $(grep -v '^#' .env | xargs)

if [ "$INSTANCE" = "green" ]; then
  NEW_INSTANCE=blue
  PORT=$PORT_BLUE
else
  NEW_INSTANCE=green
  PORT=$PORT_GREEN
fi

# Stop "new" version (just in case)
supervisorctl stop elixir-$NEW_INSTANCE

cd $GIT_REPO

# Cleanup repo
# git reset --hard
# git clean -df

# Cleanup "old" assets
mix phx.digest.clean --all

# Checkout latest version
git pull --rebase

# Initial setup
mix deps.get --only prod
mix compile

# Compile assets
mix assets.deploy

# Build release
mix release --overwrite --path "../$NEW_INSTANCE"

cd ..

# Run DB migration
$NEW_INSTANCE/bin/$GIT_REPO eval "${GIT_REPO^}.Release.migrate"

# Start new version
supervisorctl start elixir-$NEW_INSTANCE

# Switch port
uberspace web backend set / --http --port $PORT

# Little timeout until the port switch is completed
sleep 5

# Shutdown old version
supervisorctl stop elixir-$INSTANCE

# Update version in .env file
sed -i "/INSTANCE=.*/c\INSTANCE=$NEW_INSTANCE" .env
