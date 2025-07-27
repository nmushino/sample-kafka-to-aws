#!/bin/bash
# =============================================================================
# Script Name: kafka-delete-topic.sh
# Description: This script is for deleteing to Kafka Topic.
# Author: Noriaki Mushino
# Date Created: 2025-03-26
# Last Modified: 2025-04-17
# Version: 1.0
#
# Prerequisites:
#   - OpenShift CLI (oc) is installed and configured
#   - User is logged into OpenShift
#
# =============================================================================
# 注意: ログイン後、対象ドメインのすべてのTopicを消します。

NAMESPACE="debezium-demo"
KAFKA_POD=$(oc get pod -n "$NAMESPACE" -l strimzi.io/kind=Kafka -o jsonpath='{.items[0].metadata.name}')
BOOTSTRAP_SERVER="debezium-cluster-kafka-bootstrap:9092"
A_PATTERN="^server.system.*"
B_PATTERN="^system.system..*"

echo "###################################"
echo "このシェルはメンテナンスシェルです"
echo "###################################"
echo
echo "###################################"
echo "このシェルは不要なTopicを消します"
echo "###################################"
echo
echo "Target Kafka Pod: $KAFKA_POD"

# Kafka Pod 内でトピックリストを取得し、該当するものだけ削除する
oc exec -n "$NAMESPACE" -it "$KAFKA_POD" -- bash -c "
  /opt/kafka/bin/kafka-topics.sh --bootstrap-server $BOOTSTRAP_SERVER --list | grep -E '$A_PATTERN' | while read topic; do
    echo 'Deleting topic: '\$topic
    /opt/kafka/bin/kafka-topics.sh --bootstrap-server $BOOTSTRAP_SERVER --delete --topic \"\$topic\"
  done
"
oc exec -n "$NAMESPACE" -it "$KAFKA_POD" -- bash -c "
  /opt/kafka/bin/kafka-topics.sh --bootstrap-server $BOOTSTRAP_SERVER --list | grep -E '$B_PATTERN' | while read topic; do
    echo 'Deleting topic: '\$topic
    /opt/kafka/bin/kafka-topics.sh --bootstrap-server $BOOTSTRAP_SERVER --delete --topic \"\$topic\"
  done
"