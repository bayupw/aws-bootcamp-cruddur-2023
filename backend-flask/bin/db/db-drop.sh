#! /usr/bin/bash

CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="Running db-drop.sh script ..."
printf "${CYAN}== ${LABEL}${NO_COLOR}\n"

# remove cruddur from connection URI
NO_DB_CONNECTION_URL=$(sed 's/\/cruddur//g' <<<"$LOCAL_CONNECTION_URL")

psql $NO_DB_CONNECTION_URL -c "drop database IF EXISTS cruddur;"