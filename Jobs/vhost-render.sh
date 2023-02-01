#!/bin/bash
#
# Manage virtual hosts
#
# Exit if error
set -e

# Export variables
export VHOST_NAME=$1
export VHOST_NGINX_AVAIL_PATH="/etc/nginx/sites-available/$VHOST_NAME"
export VHOST_NGINX_ENABL_PATH="/etc/nginx/sites-enabled/$VHOST_NAME"

# FUNCTIONS

#######################################
# Add new vhost.
# Globals:
#   VHOST_NAME
#   VHOST_NGINX_AVAIL_PATH
#   VHOST_NGINX_ENABL_PATH
# Arguments:
#   VHOST_NAME
# Outputs:
#   Add vhost to nginx config.
#######################################
function virtual_hosts::add_vhost {
    local CONTAINER_LOCAL_HOST="http://localhost"
    local CONTAINER_LOCAL_PORT=$(docker inspect --format='{{range $p, $conf := .NetworkSettings.Ports}}{{(index $conf 0).HostPort}} {{end}}' $VHOST_NAME)
    local CONTAINER_LOCAL_URL="$CONTAINER_LOCAL_HOST:$CONTAINER_LOCAL_PORT"
    cat > $VHOST_NGINX_AVAIL_PATH << EOF
        server {
            listen 80;
            listen [::]:80;
            server_name $NEW_VHOST www.$NEW_VHOST;
            location / {
                 proxy_pass $URL_VHOST;
            }
        }
EOF
    ln -s $VHOST_NGINX_AVAIL_PATH $VHOST_NGINX_ENABL_PATH
    systemctl reload nginx
}

#######################################
# Delete vhost.
# Globals:
#   VHOST_NGINX_AVAIL_PATH
#   VHOST_NGINX_ENABL_PATH
# Outputs:
#   Delete vhost from nginx config.
#######################################
function virtual_hosts::delete_vhost {
    rm $VHOST_NGINX_AVAIL_PATH
    rm $VHOST_NGINX_ENABL_PATH
}

#######################################
# Check vhost.
# Globals:
#   VHOST_NAME
#   VHOST_NGINX_AVAIL_PATH
#   VHOST_NGINX_ENABL_PATH
# Arguments:
#   VHOST_NAME
# Outputs:
#   Check if vhost exists.
#######################################
function virtual_hosts::check_vhost {
    if [ -f "$VHOST_NGINX_AVAIL_PATH" ] && [ -f "$VHOST_NGINX_ENABL_PATH" ] ; then
        echo "$VHOST_NAME exists. Delete and add as a new"
        virtual_hosts::delete_vhost
        virtual_hosts::add_vhost
    else
        echo "$VHOST_NAME not exists. Add"
        virtual_hosts::add_vhost
    fi
}

#######################################
# Main function.
#
# Outputs:
#   Render vhost.
#######################################
function virtual_hosts::main {
    virtual_hosts::check_vhost
}

virtual_hosts::main