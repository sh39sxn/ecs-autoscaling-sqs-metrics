# ecs-autoscaling-sqs-metrics
This repo contains scripts and a Dockerfile for auto-scaling of ECS Tasks based on the number of messages available in an SQS queue.

## Getting Started

Instructions how to use this project can be found on my blog [https://allaboutaws.com/how-to-auto-scale-aws-ecs-containers-sqs-queue-metrics](https://allaboutaws.com/how-to-auto-scale-aws-ecs-containers-sqs-queue-metrics)

### Prerequisites

You need the following setup:

```
Docker (tested Docker version 18.03.0-ce, build 0520e24)
```

### Installing


clone this project:

```
git clone https://github.com/sh39sxn/mining-aion-coins.git
```


Build the Docker container (or use the prebuild one at my DockerHub Repo [https://hub.docker.com/r/sh39sxn/ecs-autoscaling-sqs-metrics](https://hub.docker.com/r/sh39sxn/ecs-autoscaling-sqs-metrics)):
```
cd ecs-autoscaling-sqs-metrics
docker build -t ecs-autoscaling-sqs-metrics:latest -f ./Cronjob.Dockerfile .
```

Run the Docker container (adjust the environment variables before):
```
docker run -it -e AWS_DEFAULT_REGION=eu-central-1 -e AWS_ACCESS_KEY_ID=XXX -e AWS_SECRET_ACCESS_KEY=XXX -e AWS_ACCOUNT_ID=XXX -e LATENCY=20 -e PROCESSING_TIME=2 -e SQS_QUEUE_NAME=My-SQS-Queue -e ECS_CLUSTER=My-ECS-Cluster -e ECS_SERVICE=My-ECS-Service -e CW_METRIC=MyBacklogPerTask -e CW_NAMESPACE=ECS-SQS-Scaling -e CW_DIMENSION_NAME=SQS-Queue -e CW_DIMENSION_VALUE=My-SQS-Queue -e MAX_LIMIT_NUMBER_QUEUE_WORKERS=200 ecs-autoscaling-sqs-metrics:latest
```





## Donation
Thank's for any donations if you like this project!

Litecoin address: LdxTMGSUGLWfcULQQ6UWTNcJGGCLysefJ7

Bitcoin address: 1H7GZ2SGQcDiEcbqdimn2C9AM4VGbqrBdx

Ethereum address: 0x2a427da268c081466be59b41e0a7ad556f57e755

## Built With

* [Docker](https://www.docker.com/)

## License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details