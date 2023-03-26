# Week 5 — DynamoDB and Serverless Caching

make sure dynamodb-local container is defined in docker-compose

```yaml
  dynamodb-local:
    user: root
    command: "-jar DynamoDBLocal.jar -sharedDb -dbPath ./data"
    image: "amazon/dynamodb-local:latest"
    container_name: dynamodb-local
    ports:
      - "8000:8000"
    volumes:
      - "./docker/dynamodb:/home/dynamodblocal/data"
    working_dir: /home/dynamodblocal
```

add boto3 to requirements.txt

```sh
cd $THEIA_WORKSPACE_ROOT/backend-flask/
pip install -r requirements.txt
```

create dynamodb scripts leveraging aws cli to do the following:
- dynamodb schema load (schema-load.sh)
- list tables (list-tables.sh)
- drop table (drop-table.sh)

Note: make sure line endings are in LF

db.py
query_value

DynamoDB command reference: https://docs.aws.amazon.com/cli/latest/reference/dynamodb/index.html

```sh
cd $THEIA_WORKSPACE_ROOT/backend-flask/bin/ddb
chmod -R u+x .
```