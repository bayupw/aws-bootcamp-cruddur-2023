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
    echo "Usage: ./delete-iam-user.sh -u|--username <username> [-g|--group <group>] [-p|--profile <profile>] [-r|--region <region>]"
    exit 0
    ;;
    *)    # unknown option
    echo "Unknown option: $1"
    echo "Usage: ./delete-iam-user.sh -u|--username <username> [-g|--group <group>] [-p|--profile <profile>] [-r|--region <region>]"
    exit 1
    ;;
esac
done

# Check if username is provided
if [ -z "$USERNAME" ]; then
    echo "Error: No username provided."
    echo "Usage: ./delete-iam-user.sh -u|--username <username> [-g|--group <group>] [-p|--profile <profile>] [-r|--region <region>]"
    exit 1
fi

ACCESS_KEY_ID=$(aws iam list-access-keys --user-name $USERNAME --profile $PROFILE $REGION --query "AccessKeyMetadata[0].AccessKeyId" --output text)

echo "Deleting access key $ACCESS_KEY_ID ..."
aws iam delete-access-key --user-name $USERNAME --access-key-id $ACCESS_KEY_ID --profile $PROFILE $REGION

if [ -n "$GROUP" ]; then
    echo "Removing user $USERNAME from group $GROUP ..."
    aws iam remove-user-from-group --user-name $USERNAME --group-name $GROUP --profile $PROFILE $REGION
fi

echo "Deleting IAM user $USERNAME ..."
aws iam delete-user --user-name $USERNAME --profile $PROFILE $REGION