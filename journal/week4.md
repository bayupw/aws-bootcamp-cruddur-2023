# Week 4 — Postgres and RDS

## Test Postgres DB locally on docker container

Set environment variables and run docker compose up

```sh
cd backend-flask
pip install -r requirements.txt

cd ..
cd frontend-react-js
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

cd ..
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
export CONNECTION_URL="postgresql://postgres:password@127.0.0.1:5432/cruddur"
gp env CONNECTION_URL="postgresql://postgres:password@127.0.0.1:5432/cruddur"
```

Test connection URL using psql `psql $CONNECTION_URL`

### Create .sql scripts

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

### Create .sh bash scripts to interact with postgre sql

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
chmod -R u+x .
```
Run scripts from `backend-flask/bin` directory

### Install postgres Client

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

### Code DB connection pooling

Create new file `db.py` under `backend-flask/lib`

db.py
```py
from psycopg_pool import ConnectionPool
import os

def query_wrap_object(template):
  sql = f"""
  (SELECT COALESCE(row_to_json(object_row),'{{}}'::json) FROM (
  {template}
  ) object_row);
  """
  return sql

def query_wrap_array(template):
  sql = f"""
  (SELECT COALESCE(array_to_json(array_agg(row_to_json(array_row))),'[]'::json) FROM (
  {template}
  ) array_row);
  """
  return sql

connection_url = os.getenv("CONNECTION_URL")
pool = ConnectionPool(connection_url)
```

Import `db.py` into `home_activities.py` and update the code to use the connection pool

```py
from datetime import datetime, timedelta, timezone
from opentelemetry import trace
from lib.db import pool, query_wrap_object, query_wrap_array

tracer = trace.get_tracer("home.activities")

class HomeActivities:
  def run(cognito_user_id=None):
    print("HOME ACTIVITY")
    #logger.info("HomeActivities")
    with tracer.start_as_current_span("home-activites-mock-data"):
      span = trace.get_current_span()
      now = datetime.now(timezone.utc).astimezone()
      span.set_attribute("app.now", now.isoformat())

      sql = query_wrap_array("""
      SELECT
        activities.uuid,
        users.display_name,
        users.handle,
        activities.message,
        activities.replies_count,
        activities.reposts_count,
        activities.likes_count,
        activities.reply_to_activity_uuid,
        activities.expires_at,
        activities.created_at
      FROM public.activities
      LEFT JOIN public.users ON users.uuid = activities.user_uuid
      ORDER BY activities.created_at DESC
      """)
      print(sql)
      with pool.connection() as conn:
        with conn.cursor() as cur:
          cur.execute(sql)
          # this will return a tuple
          # the first field being the data
          json = cur.fetchone()
      return json[0]
```

## Create and test RDS Instance

Create RDS instance via AWS Console or aws CLI or CloudFormation template
https://raw.githubusercontent.com/bayupw/aws-bootcamp-cruddur-2023/main/cruddur-rds-postgres-cfn.yml

```sh
aws rds create-db-instance \
  --db-instance-identifier cruddur-db-instance \
  --db-name cruddur \
  --db-instance-class db.t3.micro \
  --engine postgres \
  --engine-version  14.6 \
  --master-username root \
  --master-user-password <password> \
  --allocated-storage 20 \
  --availability-zone <region><az> \
  --backup-retention-period 0 \
  --port 5432 \
  --no-multi-az \
  --storage-type gp2 \
  --publicly-accessible \
  --storage-encrypted \
  --performance-insights-retention-period 7 \
  --no-deletion-protection
```

Retrieve Gitpod IP using curl to ifconfig.me and store it in env var GITPOD_IP

```sh
export GITPOD_IP=$(curl ifconfig.me)
```

use `echo` to check the GITPOD_IP: 'echo $GITPOD_IP'

set the RDS DatabaseConnectionURI as `PROD_CONNECTION_URL` in env var

```sh
export PROD_CONNECTION_URL="postgresql://username:password@RDSEndpoint:Port/database"
gp env PROD_CONNECTION_URL=="postgresql://username:password@RDSEndpoint:Port/database"
```

Connect to RDS using psql `psql $PROD_CONNECTION_URL` or using the db-connect script using parameter `prod`

```sh
cd backend-flask/bin 
./db-connect.sh prod
```

### Set docker-compose to use RDS

Update the env var `CONNECTION_URL` to the backend-flask application to use RDS

```yml
  backend-flask:
    environment:
      CONNECTION_URL: "${PROD_CONNECTION_URL}"
```

echo $THEIA_WORKSPACE_ROOT