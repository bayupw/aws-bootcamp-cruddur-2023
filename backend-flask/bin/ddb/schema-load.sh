#!/usr/bin/env python3

import boto3
import sys

attrs = {
  'endpoint_url': 'http://localhost:8000'   # dynamodb-local
}

if len(sys.argv) == 2:        # if there are 2 parameters
  if "prod" in sys.argv[1]:   # if the 2nd argument = prod
    attrs = {}                # clear up the attrs

ddb = boto3.client('dynamodb',**attrs)

table_name = 'cruddur-messages'

response = ddb.create_table(
  TableName=table_name,
  AttributeDefinitions=[
    {
      'AttributeName': 'pk',
      'AttributeType': 'S'
    },
    {
      'AttributeName': 'sk',
      'AttributeType': 'S'
    },
  ],
  KeySchema=[
    {
      'AttributeName': 'pk',
      'KeyType': 'HASH'
    },
    {
      'AttributeName': 'sk',
      'KeyType': 'RANGE'
    },
  ],
  #GlobalSecondaryIndexes=[
  #],
  BillingMode='PROVISIONED',    # free tier is provisioned throughput
  ProvisionedThroughput={
      'ReadCapacityUnits': 5,   # required for provisioned throughput
      'WriteCapacityUnits': 5   # required for provisioned throughput
  }
)

print(response)