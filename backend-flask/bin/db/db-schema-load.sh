#! /usr/bin/bash

CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="Running db-schema-load.sh script ..."
printf "${CYAN}== ${LABEL}${NO_COLOR}\n"

schema_path="../../db/schema.sql"
echo $schema_path

if [ "$1" = "prod" ]; then
  echo "Running in production mode"
  URL=$PROD_CONNECTION_URL
else
  URL=$LOCAL_CONNECTION_URL
fi

psql $URL cruddur < $schema_path
