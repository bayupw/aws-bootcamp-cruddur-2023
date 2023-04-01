#! /usr/bin/bash

set -e # stop if it fails at any point

if [ -z "$1" ]; then  # -z checks whether parameter (table name) is supplied
  echo "No TABLE_NAME argument supplied e.g., drop-table.sh cruddur-messages prod"
  exit 1
fi
TABLE_NAME=$1

if [ "$2" = "prod" ]; then
  ENDPOINT_URL=""
else
  ENDPOINT_URL="--endpoint-url=http://localhost:8000"
fi

echo "deleting table: $TABLE_NAME ..."

aws dynamodb delete-table $ENDPOINT_URL \
  --table-name $TABLE_NAME

# https://docs.aws.amazon.com/cli/latest/reference/dynamodb/index.html