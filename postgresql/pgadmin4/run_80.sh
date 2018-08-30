#!/usr/local/bin/env sh

#Run a simple container over port 80:

docker pull dpage/pgadmin4
docker run -p 80:80 \
    -e "PGADMIN_DEFAULT_EMAIL=rlaneyjr@gmail.com" \
    -e "PGADMIN_DEFAULT_PASSWORD=ralrox22" \
    -d dpage/pgadmin4

