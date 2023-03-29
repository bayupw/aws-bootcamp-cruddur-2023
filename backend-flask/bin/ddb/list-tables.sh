#! /usr/bin/bash
set -e # stop if it fails at any point

if [ "$1" = "prod" ]; then
  ENDPOINT_URL=""
else
  ENDPOINT_URL="--endpoint-url=http://localhost:8000"
fi

echo -e "Listing tables ...\r"

echo -e "\ntable output:"
aws dynamodb list-tables $ENDPOINT_URL \
  --query TableNames \
  --output table

echo -e "\ntext output:"
aws dynamodb list-tables $ENDPOINT_URL \
  --query TableNames \
  --output text