#!/bin/bash

set -ex

if [ ! -d /mnt/puzzletime_rails_root ]; then
    echo "/mnt/puzzletime_rails_root missing, going to stop. See README.md."
fi

if [ ! -d /mnt/puzzletime_postgres_files ]; then
    echo "/mnt/puzzletime_postgres_files missing, going to stop. See README.md."
fi

# This is a workaround against the stopped apache
# runing into a pid-lock-error on startup.
docker-compose rm -f rails

echo "Starting containers"
docker-compose up -d

echo "Linking ruby code to app container"
docker exec -it puzzletime_rails_1 bash -c '
      cd /opt/app-root/ &&
      mv src image-src &&
      ln -s local-src/ src &&
      mkdir -p src/bundle &&
      cd src/bundle &&
      ln -fs ../../image-src/bundle/ruby &&
      mkdir -p ../.bundle &&
      cd ../.bundle &&
      ln -fs ../../image-src/.bundle/config &&
      cd .. &&
      mkdir -p tmp &&
      touch tmp/restart.txt '
