# Week 4 — Postgres and RDS

## Test Postgres DB locally on docker container

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

Store postgres connection URI on an environment variable and test connection URL

Postgres connection URI format: `postgresql://[userspec@][hostspec][/dbname][?paramspec]`
Reference: https://www.postgresql.org/docs/current/libpq-connect.html#LIBPQ-CONNSTRING

```sh
export CONNECTION_URL="postgresql://postgres:password@127.0.0.1:5432/cruddur"
gp env CONNECTION_URL="postgresql://postgres:password@127.0.0.1:5432/cruddur"

psql $CONNECTION_URL
```




## Create and test RDS Instance

Create RDS instance via AWS COnsole or aws CLI or CloudFormation template
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

`GITPOD_IP=$(curl ifconfig.me)`