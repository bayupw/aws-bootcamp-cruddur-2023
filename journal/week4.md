# Week 4 — Postgres and RDS

There are few sections in this journal
- [Install Postgres Client](#install-postgres-client)
- [Test Postgres Locally](#test-postgres-locally)
- [Create SQL Scripts](#create-sql-scripts)
- [Create Bash Scripts](#create-bash-scripts)
- [Create DB python functions](#create-db-python-functions)
- [Create and Test RDS Instance](#create-and-test-rds-instance)
- [Update docker-compose to use RDS](#update-docker-compose-to-use-rds)
- [DB Schema Load to RDS](#db-schema-load-to-rds)
- [Lambda Function for DB Schema Load](#lambda-function-for-db-schema-load)
- [Lambda Function to Update RDS](#lambda-function-to-update-rds)
- [All-in-one Week 4 CFN stack](#all-in-one-week-4-cfn-stack)

![Week 4 Cloud Infrastructure](../_docs/assets/cruddur-week-4-diagram.png)

## Install Postgres Client

Install postgres client https://www.psycopg.org/psycopg3/ locally to test database connectivity and query on the containers

Add the env var `CONNECTION_URL` to the backend-flask application:

```yml
  backend-flask:
    environment:
      CONNECTION_URL: "${CONNECTION_URL}"
```

Add psycopg to backend-flask `requirements.txt`

```
psycopg[binary]
psycopg[pool]
```

Install psycopg 
```
pip install -r requirements.txt
```

## Test Postgres Locally

Set environment variables and run docker compose up

```sh
cd $THEIA_WORKSPACE_ROOT/backend-flask
pip install -r requirements.txt

cd $THEIA_WORKSPACE_ROOT/frontend-react-js
npm install

export AWS_ACCESS_KEY_ID="keyid"
export AWS_SECRET_ACCESS_KEY="secretkey"
export AWS_DEFAULT_REGION="ap-southeast-2"
export COGNITO_USER_POOLS_ID="UserPoolClientID"
export COGNITO_CLIENT_ID="AWS Cognito Client ID"

gp env AWS_ACCESS_KEY_ID="keyid"
gp env AWS_SECRET_ACCESS_KEY="secretkey"
gp env AWS_DEFAULT_REGION="ap-southeast-2"
gp env COGNITO_USER_POOLS_ID="UserPoolClientID"
gp env COGNITO_CLIENT_ID="UserPoolID"

cd $THEIA_WORKSPACE_ROOT
docker compose -f "docker-compose.yml" up -d --build
```

Use psql client to connect to postgres

```
psql -Upostgres --host localhost
```
password is: `password`

psql command reference: https://www.postgresql.org/docs/current/app-psql.html
common psql commands:

```sql
\x on -- expanded display when looking at data
\q -- Quit PSQL
\l -- List all databases
\c database_name -- Connect to a specific database
\dt -- List all tables in the current database
\d table_name -- Describe a specific table
\du -- List all users and their roles
\dn -- List all schemas in the current database
CREATE DATABASE database_name; -- Create a new database
DROP DATABASE database_name; -- Delete a database
CREATE TABLE table_name (column1 datatype1, column2 datatype2, ...); -- Create a new table
DROP TABLE table_name; -- Delete a table
SELECT column1, column2, ... FROM table_name WHERE condition; -- Select data from a table
INSERT INTO table_name (column1, column2, ...) VALUES (value1, value2, ...); -- Insert data into a table
UPDATE table_name SET column1 = value1, column2 = value2, ... WHERE condition; -- Update data in a table
DELETE FROM table_name WHERE condition; -- Delete data from a table
```

Store postgres connection URI on an environment variable and use it to connect with psql

Postgres connection URI format: `postgresql://[userspec@][hostspec][/dbname][?paramspec]`
Reference: https://www.postgresql.org/docs/current/libpq-connect.html#LIBPQ-CONNSTRING

```sh
export LOCAL_CONNECTION_URL="postgresql://postgres:password@127.0.0.1:5432/cruddur"
gp env LOCAL_CONNECTION_URL="postgresql://postgres:password@127.0.0.1:5432/cruddur"
```

Test connection URL using psql `psql $CONNECTION_URL`

## Create SQL Scripts

Create .sql scripts and place it under new directory `db` under `backend-flask/db`
- schema.sql: sql scripts to create schema/tables
- seed.sql: sql scripts to insert sample data

schema.sql
```sql
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
DROP TABLE IF EXISTS public.users;
DROP TABLE IF EXISTS public.activities;

CREATE TABLE public.users (
  uuid UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  display_name text NOT NULL,
  handle text NOT NULL,
  email text NOT NULL,
  cognito_user_id text NOT NULL,
  created_at TIMESTAMP default current_timestamp NOT NULL
);

CREATE TABLE public.activities (
  uuid UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_uuid UUID NOT NULL,
  message text NOT NULL,
  replies_count integer DEFAULT 0,
  reposts_count integer DEFAULT 0,
  likes_count integer DEFAULT 0,
  reply_to_activity_uuid integer,
  expires_at TIMESTAMP,
  created_at TIMESTAMP default current_timestamp NOT NULL
);
```

seed.sql
```sql
INSERT INTO public.users (display_name, handle, email, cognito_user_id)
VALUES
  ('Andrew Brown', 'andrewbrown', 'andrewbrown@exampro.co', 'MOCK'),
  ('Andrew Bayko', 'bayko', 'andrewbayko@exampro.co', 'MOCK');

INSERT INTO public.activities (user_uuid, message, expires_at)
VALUES
  (
    (SELECT uuid from public.users WHERE users.handle = 'andrewbrown' LIMIT 1),
    'This was imported as seed data!',
    current_timestamp + interval '10 day'
  )
```

## Create Bash Scripts

Create scripts and place it under new directory `bin` under `backend-flask/bin`
- db-scripts.sh: scripts to for interactive option
- db-connect.sh: script to connect to cruddur database
- db-sessions.sh: script to check existing sessions
- db-setup.sh: script to setup database (drop db if exist, create new db, load schema, insert sample value)
- db-create.sh: script to create cruddur database
- db-schema-load.sh: script to load schema using schema.sql
- db-seed.sh: script to insert sample value using seed.sql
- db-drop.sh: script to drop cruddur database

db-scripts.sh
```sh
#!/bin/bash

while true; do
    # display the menu
    echo "Please choose an option:"
    
    echo "1. Execute db-connect.sh"
    echo "2. Execute db-sessions.sh"
    
    echo "10. Execute db-setup.sh"
    
    echo "21. Execute db-create.sh"
    echo "22. Execute db-schema-load.sh"
    echo "23. Execute db-seed.sh"

    echo "30. Execute db-drop.sh"
    
    echo "99. Exit"

    # get the user's input
    read choice

    # execute the selected script or exit
    case $choice in
        1) ./db-connect.sh;;
        2) ./db-sessions.sh;;
        10) ./db-setup.sh;;
        21) ./db-create.sh;;
        22) ./db-schema-load.sh;;
        23) ./db-seed.sh;;
        30) ./db-drop.sh;;
        99) exit;;
        *) echo "Invalid choice. Please try again.";;
    esac
done
```

Change permission so the scripts are executable

```sh
cd $THEIA_WORKSPACE_ROOT/backend-flask/bin
chmod -R u+x .
```
Run scripts from `backend-flask/bin` directory

## Create DB python functions

Create SQL related functions in a file [db.py](./backend-flask/lib/db.py) under `backend-flask/lib`
The functions will use libraries from [psycopg](https://www.psycopg.org/psycopg3/docs/index.html)

Create common SQL commands under `backend-flask/db/sql/activities`
- [create.sql](./backend-flask/sql/activities/create.sql)
- [home.sql](./backend-flask/sql/activities/home.sql)
- [object.sql](./backend-flask/sql/activities/object.sql)

## Create and Test RDS Instance

Create RDS instance via AWS Console or aws cli or CloudFormation template

AWS CLI to create RDS
```sh
aws rds create-db-instance \
  --db-instance-identifier cruddur-db-instance \
  --db-name cruddur \
  --db-instance-class db.t3.micro \
  --engine postgres \
  --engine-version  14.6 \
  --master-username cruddurroot \
  --master-user-password <password> \
  --allocated-storage 20 \
  --availability-zone <region><az> \
  --backup-retention-period 0 \
  --port 5432 \
  --no-multi-az \
  --storage-type gp2 \
  --publicly-accessible \
  --performance-insights-retention-period 7 \
  --no-deletion-protection
```

When RDS has Public Access enabled, the RDS ENI will have both private IP and public IP as per the following example
```
RDSNetworkInterface: eni-012345678
Private IP: 172.31.32.x | ip-172.31.32.x.region.compute.internal
Public IP: 52.64.194.x | ec2-52-64-194-x.region.compute.amazonaws.com
Aliases: db-instance-identifier.xyz.region.rds.amazonaws.com
```

By default, the RDS will create a network interface (ENI) in the default security group on default VPC.
Add inbound rules to allow Gitpod to access the RDS.

To retrieve Gitpod IP, use curl to ifconfig.me and store it in env var GITPOD_IP

```sh
export GITPOD_IP=$(curl ifconfig.me)
```

use `echo` to check the IP Address: 'echo $GITPOD_IP'

The inbound rules can then be added via UI or aws cli

Locate the RDS Endpoint on the UI or CLI, format would be like below:
`<password>@<db-instance-id>.<xyz>.<region>.rds.amazonaws.com`

On the Gitpod, set the RDS DatabaseConnectionURI `PROD_CONNECTION_URL` in env var with the following format
`postgresql://cruddurroot:<password>@<rds-endpoint>:<port>/<db-name>`

Sample format:
`postgresql://cruddurroot:password@database-1.abcde.us-east-1.rds.amazonaws.com:5432/cruddur`

```sh
export PROD_CONNECTION_URL="postgresql://cruddurroot:password@database-1.abcde.us-east-1.rds.amazonaws.com:5432/cruddur"
gp env PROD_CONNECTION_URL="postgresql://cruddurroot:password@database-1.abcde.us-east-1.rds.amazonaws.com:5432/cruddur"
```

Connect to RDS using psql `psql $PROD_CONNECTION_URL` or using the db-connect script using parameter `prod`

```sh
cd $THEIA_WORKSPACE_ROOT/backend-flask/bin 
./db-connect.sh prod
```

### Update docker-compose to Use RDS

Update the env var `PROD_CONNECTION_URL` to the backend-flask application to use RDS
Add env var into docker-compose.yml

```yml
  backend-flask:
    environment:
      CONNECTION_URL: "${PROD_CONNECTION_URL}"
```

### DB Schema Load to RDS 

RDS will create a DB but will have no schema loaded.
Use the same `db-schema-load` script with parameter `prod` so it will execute against RDS.
Alternatively, create a Lambda function for this, see [Lambda Function for DB Schema Load](#lambda-function-for-db-schema-load)

```sh
cd $THEIA_WORKSPACE_ROOT/backend-flask/bin 
./db-schema-load.sh prod
```

Connect to the database and check that tables has been created
```sh
cd $THEIA_WORKSPACE_ROOT/backend-flask/bin 
./db-connect.sh prod
\dt
```

#### Lambda Function for DB Schema Load 

DB schema load can also be done via Lambda.
Code location: [cruddur-schema-load.py](./aws/lambdas/cruddur-schema-load.py)

Make sure the Lambda has the following configuration
- python 3.8 engine
- Connected to VPC and the assigned Security Group is allowed to access RDS
- environment variable with the key: PROD_CONNECTION_URL and value of the Database Connection URI in RDS

Invoke the lambda function via UI or aws cli after the function is ready
```sh
aws lambda invoke --function-name <lambda-function-name> response.json --region <region>
```

CloudFormation template to create the function
CFN template: [cruddur-lambda-schema-load-cfn.yml](./cruddur-lambda-schema-load-cfn.yml)

## Lambda Function to update RDS

Create a lambda function with python to update RDS
Code location: [cruddur-post-confirmation.py](./aws/lambdas/cruddur-post-confirmation.py)

Make sure the Lambda has the following configuration
- python 3.8 engine
- Connected to VPC and the assigned Security Group is allowed to access RDS
- environment variable with the key: PROD_CONNECTION_URL and value of the Database Connection URI in RDS

Use this lambda as a post-confirmation lambda trigger on the Cognito User Pool.

Update the following code to allow insert user to the RDS and allow Crud
- [app.py](./backend-flask/app.py)
- [home_activities.py](./backend-flask/services/backend-flask/services/home_activities.py)
- [create_activity.py](./backend-flask/services/home_activities.py)
- [ActivityForm.js](./frontend-react-js/src/components/ActivityForm.js)
- [HomeFeedPage.js](./frontend-react-js/src/pages/HomeFeedPage.js)

## All-in-one Week 4 CFN stack

CFN template: [cruddur-lambda-schema-load-cfn.yml](./cruddur-cfn-stack-cfn.yml)

To create all-in-one stack using the CFN template, you will need:
- A VPC (the default VPC is easier)
- A VPC ID
- 2 Subnet IDs
- region
- Database username & password

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

Store VPC ID and Subnet IDs in variables
```sh
VpcId=$(aws ec2 describe-vpcs --filters Name=isDefault,Values=true --query "Vpcs[0].VpcId" --output text --region <region>)
SubnetIds=$(aws ec2 describe-subnets --filters Name=vpc-id,Values=${VpcId} --query="[Subnets[0].SubnetId,Subnets[1].SubnetId]" --region <region> --output=text | sed 's/\s\+/,/g; s/.*/"&"/')
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
	ParameterKey=DBMasterPassword,ParameterValue=<dbpassword>
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
export AWS_DEFAULT_REGION="ap-southeast-2"
export COGNITO_USER_POOLS_ID="UserPoolClientID"
export COGNITO_CLIENT_ID="AWS Cognito Client ID"

gp env AWS_ACCESS_KEY_ID="keyid"
gp env AWS_SECRET_ACCESS_KEY="secretkey"
gp env AWS_DEFAULT_REGION="ap-southeast-2"
gp env COGNITO_USER_POOLS_ID="UserPoolClientID"
gp env COGNITO_CLIENT_ID="UserPoolID"
```

run docker compose up
```sh
cd $THEIA_WORKSPACE_ROOT
docker compose -f "docker-compose.yml" up -d --build
```

once completed, delete stack from UI or aws cli `aws cloudformation delete-stack --stack-name my-stack

```sh
aws cloudformation delete-stack \
	--stack-name cruddur \
	--region <region>
```