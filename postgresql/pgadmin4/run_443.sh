#!/usr/local/bin/env sh

#Run a TLS secured container using a shared config/storage directory in /private/var/lib/pgadmin on the host:

docker pull dpage/pgadmin4
docker run -p 443:443 \
    -v "/private/var/lib/pgadmin:/var/lib/pgadmin" \
    -v "/path/to/certificate.cert:/certs/server.cert" \
    -v "/path/to/certificate.key:/certs/server.key" \
    -e "PGADMIN_DEFAULT_EMAIL=rlaneyjr@gmail.com" \
    -e "PGADMIN_DEFAULT_PASSWORD=ralrox22" \
    -e "PGADMIN_ENABLE_TLS=True" \
    -d dpage/pgadmin4

