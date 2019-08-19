#!/bin/bash

AWS_ACCOUNT_ID=${1:-eu-central-1}
SQS_QUEUE_NAME=${2:-eu-central-1}
ECS_CLUSTER=${3:-eu-central-1}
ECS_SERVICE=${4:-eu-central-1}
CW_METRIC=${5:-eu-central-1}
CW_NAMESPACE=${6:-eu-central-1}
CW_DIMENSION_NAME=${7:-eu-central-1}
CW_DIMENSION_VALUE=${8:-eu-central-1}

ApproximateNumberOfMessages=$(aws sqs get-queue-attributes --queue-url https://sqs.$AWS_DEFAULT_REGION.amazonaws.com/$AWS_ACCOUNT_ID/$SQS_QUEUE_NAME --attribute-names All | jq -r '.[] | .ApproximateNumberOfMessages')
echo "ApproximateNumberOfMessages: " $ApproximateNumberOfMessages

NUMBER_TASKS=$(aws ecs list-tasks --cluster $ECS_CLUSTER --service-name $ECS_SERVICE | jq '.taskArns | length')
echo "NUMBER_TASKS: " $NUMBER_TASKS

MyBacklogPerWorker=$((($ApproximateNumberOfMessages / $NUMBER_TASKS) + ($ApproximateNumberOfMessages % $NUMBER_TASKS > 0)))
echo "MyBacklogPerWorker: " $MyBacklogPerWorker

# send average number of current backlogs of the workers as a custom Metric to CloudWatch
aws cloudwatch put-metric-data --metric-name $CW_METRIC --namespace $CW_NAMESPACE \
  --unit None --value $MyBacklogPerWorker --dimensions $CW_DIMENSION_NAME=$CW_DIMENSION_VALUE

