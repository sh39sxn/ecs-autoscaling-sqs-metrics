#!/bin/bash

LATENCY=${1:-20} # maximum allowed latency (seconds) for processing a message
PROCESSING_TIME=${2:-2}  # average number of seconds to process an image
ECS_CLUSTER=${3:-My-ECS-Cluster}
ECS_SERVICE=${4:-My-ECS-Service}
CW_METRIC=${5:-BacklogPerECSTask}
CW_NAMESPACE=${6:-ECS-SQS-Autoscaling}
CW_DIMENSION_NAME=${7:-SQS-Queue}
CW_DIMENSION_VALUE=${8:-My-SQS-Queue}
MAX_LIMIT_NUMBER_QUEUE_WORKERS=${9:-200}

ceil() {
  if [[ "$1" =~ ^[0-9]+$ ]]
    then
        echo $1;
        return 1;
  fi                                                                      
  echo "define ceil (x) 
        {if (x<0) {return x/1} \
          else {if (scale(x)==0) {return x} \
            else {return x/1 + 1 }}} ; ceil($1)" | bc
}

backlog_per_worker_allowed=$(($LATENCY / $PROCESSING_TIME)) # number of messages a worker can process within the allowed latency timeframe
echo "backlog_per_worker_allowed: " $backlog_per_worker_allowed

# get backlogs of the worker for the last 10 minutes
export LC_TIME=en_US.utf8
CF_JSON_RESULT=$(aws cloudwatch get-metric-statistics --namespace $CW_NAMESPACE --dimensions Name=$CW_DIMENSION_NAME,Value=$CW_DIMENSION_VALUE --metric-name $CW_METRIC \
 --start-time "$(date -u --date='5 minutes ago')" --end-time "$(date -u)" \
 --period 60 --statistics Average)
echo "CF_JSON_RESULT: " $CF_JSON_RESULT

# sum up the average values of the last 10 minutes
SUM_OF_AVERAGE_CW_VALUES=$(echo $CF_JSON_RESULT | jq '.Datapoints | .[].Average' | awk '{ sum += $1 } END { print sum }')

echo "SUM_OF_AVERAGE_VALUES: " $SUM_OF_AVERAGE_CW_VALUES

# count the number of average values the CW Cli command returned (varies between 4 and 5 values)
NUMBER_OF_CW_VALUES=$(echo $CF_JSON_RESULT | jq '.Datapoints' | jq length)

echo "NUMBER_OF_CW_VALUES: " $NUMBER_OF_CW_VALUES

# calculate average number of backlog for the workers in the last 10 minutes
AVERAGE_BACKLOG_PER_WORKER=$(echo "($SUM_OF_AVERAGE_CW_VALUES / $NUMBER_OF_CW_VALUES)" | bc -l )
echo "AVERAGE_BACKLOG_PER_WORKER: " $AVERAGE_BACKLOG_PER_WORKER

# calculator factor to scale in/out, then ceil up to next integer to be sure the scaling is sufficient
FACTOR_SCALING=$(ceil $(echo "($AVERAGE_BACKLOG_PER_WORKER / $backlog_per_worker_allowed)" | bc -l) )
echo "FACTOR_SCALING: " $FACTOR_SCALING

# get current number of ECS tasks
CURRENT_NUMBER_TASKS=$(aws ecs list-tasks --cluster $ECS_CLUSTER --service-name $ECS_SERVICE | jq '.taskArns | length')
echo "CURRENT_NUMBER_TASKS: " $CURRENT_NUMBER_TASKS

# calculate new number of ECS tasks, print leading 0 (0.43453 instead of .43453)
NEW_NUMBER_TASKS=$( echo "($FACTOR_SCALING * $CURRENT_NUMBER_TASKS)" | bc -l |  awk '{printf "%f", $0}')
echo "NEW_NUMBER_TASKS: " $NEW_NUMBER_TASKS


## we run more than enough workers currently, scale in slowly by 20 %
if [ $FACTOR_SCALING -le "1" ];
then
  NEW_NUMBER_TASKS=$( echo "(0.8 * $CURRENT_NUMBER_TASKS)" | bc -l)
fi;

echo "NEW_NUMBER_TASKS: " $NEW_NUMBER_TASKS

# round number of tasks to int
NEW_NUMBER_TASKS_INT=$( echo "($NEW_NUMBER_TASKS+0.5)/1" | bc )


if [ ! -z $NEW_NUMBER_TASKS_INT ];
    then
        if [ $NEW_NUMBER_TASKS_INT == "0" ];
          then
              NEW_NUMBER_TASKS_INT=1 # run at least one worker
        fi;
        if [ $NEW_NUMBER_TASKS_INT -gt $MAX_LIMIT_NUMBER_QUEUE_WORKERS ];
          then
              NEW_NUMBER_TASKS_INT=$MAX_LIMIT_NUMBER_QUEUE_WORKERS # run not more than the maximum limit of queue workers
        fi;
fi;

echo "NEW_NUMBER_TASKS_INT:" $NEW_NUMBER_TASKS_INT

# update ECS service to the calculated number of ECS tasks
aws ecs update-service --cluster $ECS_CLUSTER --service $ECS_SERVICE --desired-count $NEW_NUMBER_TASKS_INT 1>/dev/null
