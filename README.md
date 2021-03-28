# Pipeline worker

Scripts to setup and shutdown self-hosted pipeline workers.

To create a worker run:
```shell
export SUBSCRIPTION="xxxxx"
export WORKER_NAME="pipeline-xxxxx"
export ADMIN_USERNAME="xxxxx"
export ADMIN_PASSWORD="xxxxx"
export PAT_TOKEN="xxxxx"

./run-startup.sh
```

To remove a worker run:
```shell
export SUBSCRIPTION="xxxxx"
export WORKER_NAME="pipeline-xxxxx"
export PAT_TOKEN="xxxxx"

./run-shutdown.sh
```
