#!/bin/bash
set -e -o pipefail

if [ -z "$CMK_SITE_ID" ]; then
    echo "ERROR: No site ID given"
    exit 1
fi

trap 'omd stop '"$CMK_SITE_ID"'; exit 0' SIGTERM SIGHUP SIGINT

# Prepare local MTA for sending to smart host
# TODO: Syslog is only added to support postfix. Can we please find a better solution?
if [ ! -z "$MAIL_RELAY_HOST" ]; then
    echo "### PREPARE POSTFIX (Hostname: $HOSTNAME, Relay host: $MAIL_RELAY_HOST)"
    echo "$HOSTNAME" > /etc/mailname
    postconf -e myorigin="$HOSTNAME"
    postconf -e mydestination="$(hostname -a), $(hostname -A), localhost.localdomain, localhost"
    postconf -e relayhost="$MAIL_RELAY_HOST"
    postconf -e mynetworks="127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128"
    postconf -e mailbox_size_limit=0
    postconf -e recipient_delimiter=+
    postconf -e inet_interfaces=all
    postconf -e inet_protocols=all

    echo "### STARTING MAIL SERVICES"
    syslogd
    /etc/init.d/postfix start
fi

# Create the site in case it does not exist
if [ ! -d "/opt/omd/sites/$CMK_SITE_ID" ] ; then
    echo "### CREATING SITE '$CMK_SITE_ID'"
    omd create --no-tmpfs -u 1000 -g 1000 "$CMK_SITE_ID"
    omd config "$CMK_SITE_ID" set APACHE_TCP_ADDR 0.0.0.0
    omd config "$CMK_SITE_ID" set APACHE_TCP_PORT 5000

    if [ "$CMK_LIVESTATUS_TCP" = "on" ]; then
        omd config "$CMK_SITE_ID" set LIVESTATUS_TCP on
    fi

    if [ -n "$CMK_PASSWORD" ]; then
        echo "### SETTING PASSWORD OF 'cmkadmin'"
        htpasswd -b -m "/omd/sites/$CMK_SITE_ID/etc/htpasswd" cmkadmin "$CMK_PASSWORD"
    fi
fi

# In case of an update (see update procedure docs) the container is started
# with the data volume mounted (the site is not re-created). In this
# situation only the site data directory is available and the "system level"
# parts are missing. Check for them here and create them.
## TODO: This should be supported by a omd command (omd init or similar)
if ! getent group "$CMK_SITE_ID" >/dev/null; then
    groupadd -g 1000 "$CMK_SITE_ID"
fi
if ! getent passwd "$CMK_SITE_ID" >/dev/null; then
    useradd -u 1000 -d "/omd/sites/$CMK_SITE_ID" -c "OMD site $CMK_SITE_ID" -g "$CMK_SITE_ID" -G omd -s /bin/bash "$CMK_SITE_ID"
fi
if [ ! -f "/omd/apache/$CMK_SITE_ID.conf" ]; then
    echo "Include /omd/sites/$CMK_SITE_ID/etc/apache/mode.conf" > "/omd/apache/$CMK_SITE_ID.conf"
fi

# When a command is given via "docker run" use it instead of this script
if [ -n "$1" ]; then
    exec "$@"
fi

echo "### STARTING SITE"
omd start "$CMK_SITE_ID"

echo "### STARTING CRON"
cron -f &

echo "### CONTAINER STARTED"
wait
