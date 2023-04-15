#!/bin/bash

# Initialize default values
USERNAME=""
GROUP=""
PROFILE="default"
REGION=""

# Parse command line arguments
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -u|--username)
    USERNAME="$2"
    shift # past argument
    shift # past value
    ;;
    -g|--group)
    GROUP="$2"
    shift # past argument
    shift # past value
    ;;
    -p|--profile)
    PROFILE="$2"
    shift # past argument
    shift # past value
    ;;
    -r|--region)
    REGION="--region $2"
    shift # past argument
    shift # past value
    ;;
    -h|--help)
    echo "Usage: ./create-iam-user.sh -u|--username <username> [-g|--group <group>] [-p|--profile <profile>] [-r|--region <region>]"
    exit 0
    ;;
    *)    # unknown option
    echo "Unknown option: $1"
    echo "Usage: ./create-iam-user.sh -u|--username <username> [-g|--group <group>] [-p|--profile <profile>] [-r|--region <region>]"
    exit 1
    ;;
esac
done

# Check if username is provided
if [ -z "$USERNAME" ]; then
    echo "Error: No username provided."
    echo "Usage: ./create-iam-user.sh -u|--username <username> [-g|--group <group>] [-p|--profile <profile>] [-r|--region <region>]"
    exit 1
fi

# Create IAM user
echo "Creating a new IAM user $USERNAME ..."
aws iam create-user --user-name $USERNAME --profile $PROFILE $REGION

# Add user to group if specified
if [ -n "$GROUP" ]; then
    echo "Adding user $USERNAME to group $GROUP..."
    aws iam add-user-to-group --user-name $USERNAME --group-name $GROUP --profile $PROFILE $REGION
fi

echo "Generating Access Key ..."
SECRET_ACCESS_KEY=$(aws iam create-access-key --user-name $USERNAME --query "AccessKey.SecretAccessKey" --output text --profile $PROFILE $REGION)

ACCESS_KEY_ID=$(aws iam list-access-keys --user-name $USERNAME --query "AccessKeyMetadata[0].AccessKeyId" --output text --profile $PROFILE $REGION)

echo "Access Key ID: $ACCESS_KEY_ID"
echo "Secret Access Key: $SECRET_ACCESS_KEY"
