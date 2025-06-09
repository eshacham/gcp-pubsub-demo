# !/bin/bash

export GCP_PROJECT_ID="pubsub-demo-0518"
export PUBSUB_TOPIC_ID="my-topic"
export PUBSUB_SUBSCRIPTION_ID="my-sub"

python ./src/publisher.py

python ./src/subscriber.py
