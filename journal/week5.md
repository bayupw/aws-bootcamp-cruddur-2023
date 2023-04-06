# Week 5 — DynamoDB and Serverless Caching

- [DynamoDB Data Modeling](#dynamodb-data-modeling)
- [Implement Conversations](#implement-conversations)
- [Implement Create Message](#implement-create-message)
- [Implement Update Message with DynamoDB Stream](#implement-update-message-with-dynamodb-stream)
- [Create DynamoDB Table and Gateway Endpoint](#create-dynamodb-table-and-gateway-endpoint)
- [All-in-one Week 5 CFN stack](#all-in-one-week-5-cfn-stack)

## DynamoDB Data Modeling

| pk | sk (created_at or last_reply_at) | display_name (aka other_user_display_name) | handle (aka other_user_handle) | message (aka last_message) | user_uuid | message_group_uuid |
| -------- | -------- | -------- | -------- | -------- | -------- | -------- |
| MSG#{message_group_uuid} | MSG#{created_at} | Andrew Brown | andrewbrown | Testing 123 | 90324830-2948230948-23424-30924 | 23523532-6433634643-234234234-23423525 |
| GRP#{my_user_uuid} | GRP#{last_reply_at} | Andrew Bayko | bayko	| Great, I'll go take a look | 2342342-52353252-23523523-23424 | 23523532-6433634643-234234234-23423525 |
| GRP#{my_user_uuid} | GRP#{last_reply_at} | Andrew Brown | andrewbrown| Testing 123 | 90324830-2948230948-23424-30924 | 23523532-6433634643-234234234-23423525 |

## Implement Conversations

To implement conversations, we will need to:
1. Use dynamodb-local container
2. Create scripts using SDK to create dynamodb table and add seed data for sample conversations
3. Update relevant frontend and backend code

Make sure dynamodb-local container is defined in docker-compose and add `AWS_ENDPOINT_URL` on `backend-flask` to use the dynamodb-local

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

  backend-flask:
    environment:
      AWS_ENDPOINT_URL: "http://dynamodb-local:8000"  # for local dynamodb
```

Add boto3 to `requirements.txt` as we will be using this on the scripts

```sh
cd $THEIA_WORKSPACE_ROOT/backend-flask/
pip install -r requirements.txt
```

Create scripts leveraging aws CLI for DynamoDB, python functions for ddb transactions and relevant backend code:
- Dynamodb schema load [schema-load.sh](./backend-flask/bin/ddb/schema-load.sh)
- Data seed [seed.sh](./backend-flask/bin/ddb/seed.sh)
- List tables [list-tables.sh](./backend-flask/bin/ddb/list-tables.sh)
- Drop table <name> [drop-table.sh](./backend-flask/bin/ddb/drop-table.sh)
- List cognito users [list-users.sh](./backend-flask/bin/cognito/list-users.sh)
- Scan ddb [scan.sh](./backend-flask/bin/ddb/scan.sh)
- Update cognito user id in postgre [update-cognito-user-id.sh](./backend-flask/bin/db/update-cognito-user-ids.sh)
- Functions for DynamoDB [ddb.py](./backend-flask/lib/ddb.py)
- Update functions for DB [db.py](./backend-flask/lib/db.py)
- Update message_groups.py [db.py](./backend-flask/lib/db.py)
- Update [messages.py](./backend-flask/services/messages.py)
- Create [get-conversations.sh](./backend-flask/bin/ddb/patterns/get-conversation.sh)
- Create [list-conversations.sh](./backend-flask/bin/ddb/patterns/list-conversations.sh)
- Create [uuid_from_cognito_user_id.sql](./backend-flask/db/sql/users/uuid_from_cognito_user_id.sql)
- [message_groups.py](./backend-flask/services/message_groups.py)
- [notifications_activities.py](./backend-flask/services/notifications_activities.py)
- Update [app.py](./backend-flask/app.py)

Update frontend code:
- [MessageGroupItem.js](./frontend-react-js/src/components/MessageGroupItem.js)
- [MessageForm.js](./frontend-react-js/src/components/MessageForm.js)
- [MessageGroupsPage.js](./frontend-react-js/src/pages/MessageGroupsPage.js)
- [CheckAuth.js](./frontend-react-js/src/lib/CheckAuth.js)
- [HomeFeedPage.js](./frontend-react-js/src/pages/HomeFeedPage.js)
- Update route on [App.js](./frontend-react-js/src/App.js)

Note: make sure line endings are in LF

DynamoDB command reference: https://docs.aws.amazon.com/cli/latest/reference/dynamodb/index.html

```sh
cd $THEIA_WORKSPACE_ROOT/backend-flask/bin/ddb
chmod -R u+x .
```

## Implement Create Message

Create and update relevant code/function:
- [create_message_users.sql](./backend-flask/db/sql/users/create_message_users.sql)
- Update [ddb.py](./backend-flask/lib/ddb.py)
- Update [app.py](./backend-flask/app.py)
- [MessageGroupNewItem.js](./frontend-react-js/src/components/MessageGroupNewItem.js)
- [MessageForm.js](./frontend-react-js/src/components/MessageForm.js)
- [MessageGroupFeed.js](./frontend-react-js/src/components/MessageGroupFeed.js)
- [MessageGroupNewPage.js](./frontend-react-js/src/pages/MessageGroupNewPage.js)

Test a new message


## Implement Update Message with DynamoDB Stream

To implement update message with DynamoDB stream, there are additional cloud infrastructure need to be provisioned:
1. DynamoDB Table
2. Gateway VPC endpoint for DynamoDB
3. Lambda function for message stream trigger to update message groups
4. Relevant IAM policy/role


## Create DynamoDB Table and Gateway Endpoint

Leverage the Dynamodb [schema-load.sh](./backend-flask/bin/ddb/schema-load.sh) script with `prod` argument to execute against DynamoDB: `schema-load.sh prod`
Note: make sure schema has GSI

Turn on [DynamoDB Stream](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Streams.html) with `New image` as the type

Navigate to AWS Console > VPC > Endpoint to create [Gateway endpoint for DynamoDB](https://docs.aws.amazon.com/vpc/latest/privatelink/vpc-endpoints-ddb.html)

CFN template to create both DynamoDB table and Gateway endpoint for DynamoDB: [cruddur-dynamodb-table-endpoint-cfn.yml](../cruddur-dynamodb-table-endpoint-cfn.yml)

Create AWS Lambda function [cruddur-messaging-stream](./aws/lambdas/cruddur-messaging-stream.py) with the following IAM:
- AWSLambdaBasicExecutionRole
- AWSLambdaVPCAccessExecutionRole
- AWSLambdaDynamoDBExecutionRole
- AWSLambdaInvocation-DynamoDB

Add the following policy to the Lambda IAM role [cruddur-message-stream-policy.json](./aws/policies/cruddur-message-stream-policy.json)
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "dynamodb:PutItem",
                "dynamodb:DeleteItem",
                "dynamodb:Query"
            ],
            "Resource": [
                "arn:aws:dynamodb:ca-central-1:387543059434:table/cruddur-messages",
                "arn:aws:dynamodb:ca-central-1:387543059434:table/cruddur-messages/index/message-group-sk-index"
            ]
        }
    ]
  }
```

Under DynamoDB, create a trigger and add the `cruddur-messaging-stream` lambda function

Sample working content of DynamoDB table with the relevant CloudWatch logs as follows

![DynamoDB Table](../_docs/assets/cruddur-sample-dynamodb-tables.png)

![DynamoDB Stream CloudWatch Logs](../_docs/assets/cruddur-sample-dynamodb-cloudwatch.png)


## All-in-one Week 5 CFN stack

CFN template: [cruddur-lambda-schema-load-cfn.yml](../cruddur-cfn-stack.yml)

To create all-in-one stack using the CFN template, you will need:
- A VPC (the default VPC is easier)
- A VPC ID
- 2 Subnet IDs
- AWS Region
- Database username & password
- Route Table ID

The CFN template will create the following AWS resources:
- New Security Group for Lambda
- New Security Group for DB2 and inbound rules allowing Security Group for Lambda to access RDS via TCP 443
- New DB Subnet Group
- New IAM Role for Lambda with Manage Policy AWSLambdaVPCAccessExecutionRole
- New Lambda Function for post-confirmation with VPC and Env Vars configuration
- New Lambda Function for db schema load with VPC and Env Vars configuration
- New Cognito User pool
- New Cognito User pool client
- Assign Lambda Function for post-confirmation to Cognito
- Output relevant values

Store VPC ID, Subnet IDs and Route Table ID in variables
```sh
VpcId=$(aws ec2 describe-vpcs --filters Name=isDefault,Values=true --query "Vpcs[0].VpcId" --output text --region <region>)
SubnetIds=$(aws ec2 describe-subnets --filters Name=vpc-id,Values=${VpcId} --query="[Subnets[0].SubnetId,Subnets[1].SubnetId]" --region <region> --output=text | sed 's/\s\+/,/g; s/.*/"&"/')
RouteTableId=$aws ec2 describe-route-tables --query="RouteTables[0].RouteTableId" --region <region>
```

Run `aws cloudformation create-stack` command using the $VpcId and SubnetIds variable
```sh
aws cloudformation create-stack \
	--stack-name cruddur \
	--region <region> \
	--template-body file://cruddur-cfn-stack.yml \
	--capabilities CAPABILITY_NAMED_IAM \
	--parameters \
	ParameterKey=VpcId,ParameterValue=$VpcId \
	ParameterKey=SubnetIds,ParameterValue=$SubnetIds \
	ParameterKey=AvailabilityZone,ParameterValue=<region><az> \
	ParameterKey=DBMasterUsername,ParameterValue=cruddurroot \
	ParameterKey=DBMasterPassword,ParameterValue=<dbpassword> \
	ParameterKey=RouteTableId,ParameterValue=$RouteTableId
```

After stack is ready, invoke the schema load function from UI or aws cli: `aws lambda invoke --function-name cruddur-schema-load response.json --region <region>`

Start gitpod or local devcontainer
Retrive IP address using `curl ifconfig.me`
Update the stack SGCidrIP with the machine IP or manually update the Security Group

Set env vars based on the cfn output ![cruddur-cfn-stack-output](../_docs/assets/cruddur-cfn-stack-output.png)

```sh
cd $THEIA_WORKSPACE_ROOT/backend-flask
pip install -r requirements.txt

cd $THEIA_WORKSPACE_ROOT/frontend-react-js
npm install

export AWS_ACCESS_KEY_ID="keyid"
export AWS_SECRET_ACCESS_KEY="secretkey"
export AWS_DEFAULT_REGION="region"
export COGNITO_USER_POOLS_ID="UserPoolClientID"
export COGNITO_CLIENT_ID="AWS Cognito Client ID"
export CONNECTION_URL="postgresql://postgres:password@db:5432/cruddur"
export LOCAL_CONNECTION_URL="postgresql://postgres:password@localhost:5432/cruddur"
export PROD_CONNECTION_URL="postgresql://cruddurroot:password@cruddur-db-instance.xyz.<region>.rds.amazonaws.com:5432/cruddur"

gp env AWS_ACCESS_KEY_ID="keyid"
gp env AWS_SECRET_ACCESS_KEY="secretkey"
gp env AWS_DEFAULT_REGION="region"
gp env COGNITO_USER_POOLS_ID="UserPoolClientID"
gp env COGNITO_CLIENT_ID="UserPoolID"
gp env PROD_CONNECTION_URL="postgresql://cruddurroot:password@cruddur-db-instance.xyz.<region>.rds.amazonaws.com:5432/cruddur"
```

run docker compose up
```sh
cd $THEIA_WORKSPACE_ROOT
docker compose -f "docker-compose.yml" up -d --build
```

once completed, delete stack from UI or aws cli `aws cloudformation delete-stack --stack-name cruddur

```sh
aws cloudformation delete-stack \
	--stack-name cruddur \
	--region <region>
```
