#!/bin/bash

AWS_ACCOUNT_ID=${1:-123456789}
SQS_QUEUE_NAME=${2:-My-SQS-Queue}
ECS_CLUSTER=${3:-My-ECS-Cluster}
ECS_SERVICE=${4:-My-ECS-Service}
CW_METRIC=${5:-BacklogPerECSTask}
CW_NAMESPACE=${6:-ECS-SQS-Autoscaling}
CW_DIMENSION_NAME=${7:-SQS-Queue}
CW_DIMENSION_VALUE=${8:-My-SQS-Queue}

ApproximateNumberOfMessages=$(aws sqs get-queue-attributes --queue-url https://sqs.$AWS_DEFAULT_REGION.amazonaws.com/$AWS_ACCOUNT_ID/$SQS_QUEUE_NAME --attribute-names All | jq -r '.[] | .ApproximateNumberOfMessages')
echo "ApproximateNumberOfMessages: " $ApproximateNumberOfMessages

NUMBER_TASKS=$(aws ecs list-tasks --cluster $ECS_CLUSTER --service-name $ECS_SERVICE | jq '.taskArns | length')
echo "NUMBER_TASKS: " $NUMBER_TASKS

MyBacklogPerWorker=$((($ApproximateNumberOfMessages / $NUMBER_TASKS) + ($ApproximateNumberOfMessages % $NUMBER_TASKS > 0)))
echo "MyBacklogPerWorker: " $MyBacklogPerWorker

# send average number of current backlogs of the workers as a custom Metric to CloudWatch
aws cloudwatch put-metric-data --metric-name $CW_METRIC --namespace $CW_NAMESPACE \
  --unit None --value $MyBacklogPerWorker --dimensions $CW_DIMENSION_NAME=$CW_DIMENSION_VALUE

