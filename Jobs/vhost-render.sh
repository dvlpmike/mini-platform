#!/bin/bash
#
# Search and render new virtual hosts

# Exit if error
set -e

# Export variables
export VHOST_NAME=$1
export VHOST_PATH_SITES_AVAIL="/etc/nginx/sites-available/$VHOST_NAME"
export VHOST_PATH_SITES_ENABL="/etc/nginx/sites-enabled/$VHOST_NAME"
export CONTAINERS_LIST_PATH="/tmp"
export CONTAINERS_LIST_FILE_NAME="active-containers.txt"

# Funtions

#######################################
# Check active docker containers.
# Globals:
#   VHOST_NAME
#   VHOST_CONFIG_PATH
# Arguments:
#   None
# Outputs:
#   List names of active docker containers and save it to file.
#######################################
function virtual_hosts::check_active_containers {
    docker ps --format '{{.Names}}' > "$CONTAINERS_LIST_PATH/$CONTAINERS_LIST_FILE_NAME"
}

#######################################
# Add new vhost.
# Globals:
#   VHOST_NAME
#   VHOST_CONFIG_PATH
# Arguments:
#   None
# Outputs:
#   Add vhost to nginx config.
#######################################
function virtual_hosts::add_vhost {
    local CONTAINER_LOCAL_HOST="http://localhost"
    local CONTAINER_LOCAL_PORT=$(docker inspect --format='{{range $p, $conf := .NetworkSettings.Ports}}{{(index $conf 0).HostPort}} {{end}}' $VHOST_NAME)
    local CONTAINER_LOCAL_URL="$CONTAINER_LOCAL_HOST:$CONTAINER_LOCAL_PORT"
    echo "server {
        listen 80;
        listen [::]:80;
        server_name $VHOST_NAME www.$VHOST_NAME;
        location / {
                proxy_pass $CONTAINER_LOCAL_URL;
        }
    }" > $VHOST_PATH_SITES_AVAIL
    ln -s $VHOST_PATH_SITES_AVAIL /etc/nginx/sites-enabled/
    systemctl reload nginx
}

#######################################
# Delete vhost.
# Globals:
#   VHOST_NAME
# Arguments:
#   None
# Outputs:
#   Delete vhost from nginx config.
#######################################
function virtual_hosts::delete_vhost {
    rm -f $VHOST_PATH_SITES_AVAIL
    rm -f $VHOST_PATH_SITES_ENABL
}

#######################################
# Check vhosts.
# Globals:
#   CONTAINERS_LIST_PATH
#   CONTAINERS_LIST_FILE_NAME
# Arguments:
#   None
# Outputs:
#   Check if vhost exists.
#######################################
function virtual_hosts::check_vhosts {
    local LIN=$(cat $CONTAINERS_LIST_PATH/$CONTAINERS_LIST_FILE_NAME)
    local VHOST_CONFIG_PATH2="/etc/nginx/sites-available"
    for i in $LIN
    do
        if [ -f "$VHOST_CONFIG_PATH2/$i" ]; then
            echo "$i jest. nie dodawaj"
        else
            echo "$i brak. dodaj"
            cat > /etc/nginx/sites-available/$VHOST_NAME << EOF
        server {
            listen 80;
            listen [::]:80;
            server_name $NEW_VHOST www.$NEW_VHOST;
            location / {
                 proxy_pass $URL_VHOST;
            }
        }
EOF
        fi
    done
}

#######################################
# Delete certbot certificate.
# Globals:
#   VHOST_NAME
# Arguments:
#   VHOST_NAME
# Outputs:
#   The function takes one argument, check if the certificate exists and remove it.
#######################################
function virtual_hosts::delete_certificate {
  if [[ -z "$VHOST_NAME" ]]; then
    echo "Please provide the domain name as an argument."
    return 1
  fi

  if ! sudo certbot certificates | grep -q "$1"; then
    echo "Certificate for $VHOST_NAME does not exist."
    return 1
  fi

  sudo certbot delete --non-interactive --cert-name "$VHOST_NAME"
  sudo service nginx reload
  echo "Certificate for $VHOST_NAME has been deleted."
  sleep 20
}

#######################################
# Create certbot certificate.
# Globals:
#   VHOST_NAME
# Arguments:
#   VHOST_NAME
# Outputs:
#   The function takes one argument, check if the certificate exists and create it.
#######################################
function virtual_hosts::create_certificate {
  if [[ -z "$VHOST_NAME" ]]; then
    echo "Please provide the domain name as an argument."
    return 1
  fi
  if sudo certbot certificates | grep -q "$1"; then
    echo "Certificate for $VHOST_NAME already exists."
    return 1
  fi

  sudo certbot --nginx --non-interactive -d "$VHOST_NAME"
  sudo service nginx reload
  echo "Certificate for $VHOST_NAME has been created."
}

#######################################
# Check vhost.
# Globals:
#   CONTAINERS_LIST_PATH
#   CONTAINERS_LIST_FILE_NAME
# Arguments:
#   None
# Outputs:
#   Check if vhost exists.
#######################################
function virtual_hosts::check_vhost {
  if [ -f $VHOST_PATH_SITES_AVAIL ] || [ -L $VHOST_PATH_SITES_ENABL ] ; then
    echo "$VHOST_NAME already exists. It will be remove and add as new"
    virtual_hosts::delete_vhost
    echo "$VHOST_PATH_SITES_AVAIL and $VHOST_PATH_SITES_ENABL removed"
    virtual_hosts::add_vhost
  else
    echo "$VHOST_NAME brak. dodaj"
    virtual_hosts::add_vhost
  fi
}

#######################################
# Main function.
# Globals:
#
#
# Arguments:
#
# Outputs:
#
#######################################
function virtual_hosts::main {
    #virtual_hosts::check_active_containers
    virtual_hosts::check_vhost
    virtual_hosts::delete_certificate
    virtual_hosts::create_certificate
}

virtual_hosts::main
