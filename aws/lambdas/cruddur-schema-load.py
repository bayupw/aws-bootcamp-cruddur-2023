import json
import psycopg2
import os

def lambda_handler(event, context):

    # Create a connection to the database
    conn = psycopg2.connect(os.getenv('PROD_CONNECTION_URL'))

    try:
      with conn.cursor() as cur:
          cur.execute('CREATE EXTENSION IF NOT EXISTS "uuid-ossp";')
          cur.execute('DROP TABLE IF EXISTS public.users;')
          cur.execute('DROP TABLE IF EXISTS public.activities;')
          cur.execute("""
              CREATE TABLE public.users (
                uuid UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
                display_name text NOT NULL,
                handle text NOT NULL,
                email text NOT NULL,
                cognito_user_id text NOT NULL,
                created_at TIMESTAMP default current_timestamp NOT NULL
              );
          """)
          cur.execute("""
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
          """)

      # Commit the transaction
      conn.commit() 

    except (Exception, psycopg2.DatabaseError) as error:
      print(error)

      # Roll back the transaction
      conn.rollback()

    finally:
      if conn is not None:
          cur.close()
          conn.close()
          print('Database connection closed.')
    return event