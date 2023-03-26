#! /usr/bin/bash
set -e # stop if it fails at any point

if [ "$1" = "prod" ]; then
  ENDPOINT_URL=""
else
  ENDPOINT_URL="--endpoint-url=http://localhost:8000"
fi

echo "Listing tables ..."

aws dynamodb list-tables $ENDPOINT_URL \
  --query TableNames \
  --output table

aws dynamodb list-tables $ENDPOINT_URL \
  --query TableNames[0].ListTables \
  --output table
  