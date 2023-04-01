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
- seed (seed.sh)
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

uuid_from_cognito_user_id

create db scripts to update cognito user id
update message_groups.py
update app.py

uuid_from_cognito_user_id.sql

update HomeFeedPage.js

remove

// [TODO] Authenication
import Cookies from 'js-cookie'


update MessageGroupPage.js,MessageGroupsPage.js,MessageForm.js

        headers: {
          Authorization: `Bearer ${localStorage.getItem("access_token")}`
        },

move checkAuth function from HomeFeedPage.js to checkAuth.js

update docker-compose
AWS_ENDPOINT_URL: "http://dynamodb-local:8000"  # for local dynamodb

create postgre table & seed, seed dynamodb-local


aws cognito-idp list-user-pools --max-results 1 --region <region> --output table

aws cognito-idp list-users --user-pool-id <user-pool-id>


list-users.sh
update-cognito-user-ids.sh