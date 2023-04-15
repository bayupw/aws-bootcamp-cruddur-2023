aws ssm delete-parameter --name "DOCKERHUB_USERNAME"
aws ssm delete-parameter --name "DOCKERHUB_PASSWORD"

aws ssm delete-parameter --name " /cruddur/backend-flask/AWS_ACCESS_KEY_ID"
aws ssm delete-parameter --name " /cruddur/backend-flask/AWS_SECRET_ACCESS_KEY"
aws ssm delete-parameter --name " /cruddur/backend-flask/CONNECTION_URL"
aws ssm delete-parameter --name " /cruddur/backend-flask/ROLLBAR_ACCESS_TOKEN"
aws ssm delete-parameter --name " /cruddur/backend-flask/OTEL_EXPORTER_OTLP_HEADERS"