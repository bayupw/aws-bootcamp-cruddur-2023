aws ssm put-parameter --type "SecureString" --region ap-southeast-2 --profile cruddur --name "DOCKERHUB_USERNAME" --value $DOCKERHUB_USERNAME
aws ssm put-parameter --type "SecureString" --region ap-southeast-2 --profile cruddur --name "DOCKERHUB_PASSWORD" --value $DOCKERHUB_PASSWORD

aws ssm put-parameter --type "SecureString" --region ap-southeast-2 --profile cruddur --name " /cruddur/backend-flask/AWS_ACCESS_KEY_ID" --value $AWS_ACCESS_KEY_ID
aws ssm put-parameter --type "SecureString" --region ap-southeast-2 --profile cruddur --name " /cruddur/backend-flask/AWS_SECRET_ACCESS_KEY" --value $AWS_SECRET_ACCESS_KEY
aws ssm put-parameter --type "SecureString" --region ap-southeast-2 --profile cruddur --name " /cruddur/backend-flask/CONNECTION_URL" --value $CONNECTION_URL
aws ssm put-parameter --type "SecureString" --region ap-southeast-2 --profile cruddur --name " /cruddur/backend-flask/ROLLBAR_ACCESS_TOKEN" --value $ROLLBAR_ACCESS_TOKEN
aws ssm put-parameter --type "SecureString" --region ap-southeast-2 --profile cruddur --name " /cruddur/backend-flask/OTEL_EXPORTER_OTLP_HEADERS" --value "x-honeycomb-team=$HONEYCOMB_API_KEY"