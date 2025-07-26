#!/bin/bash
# =============================================================================
# Script Name: deploy.sh
# Description: This script deploys the application to OpenShift and verifies the setup.
# Author: Noriaki Mushino
# Last Modified: 2025-07-25
# Version: 1.13#
# =============================================================================

NAMESPACE="awseventbridge-demo"
OPENMETADATASPACE="openmetadata"
DOMAIN_NAME=$(oc get ingresses.config.openshift.io cluster -o jsonpath='{.spec.domain}' | cut -d'.' -f2-)
DOMAIN_TOKEN=$(oc whoami -t)
ENV_FILE="source.env"

# 色を変数に格納
RED="\033[31m"
GREEN="\033[32m"
BLUE="\033[34m"
YELLOW="\033[33m"
RESET="\033[0m"

# OpenShift にログインしているか確認
if ! oc whoami &>/dev/null; then
    echo -e "${RED}OpenShift にログインしていません。まず 'oc login' を実行してください。${RESET}" >&2
    exit 1
fi
echo "OpenShift にログイン済み: $(oc whoami)"

# OpenShift にログインしているか確認
echo -e "${YELLOW}Domain Name: $DOMAIN_NAME${RESET}"
echo -e "${YELLOW}Domain Token: $DOMAIN_TOKEN${RESET}"
echo -e "-------------------------------------------"
read -p "指定されたドメインで間違いないですか？(yes/no): " DOMAIN_CONFREM
if [ "$DOMAIN_CONFREM" != "yes" ]; then
    echo -e "${RED}処理を中断します。${RESET}"
    exit 1
fi

deploy() {

    echo "デプロイ開始..."

    oc new-project "$NAMESPACE"
    # 既存Appの削除
    oc delete all -l app=reactiveweb -n "$NAMESPACE"
    oc delete all -l app=postgressynccamel -n "$NAMESPACE"
    oc delete all -l app=eventbridgesynccamel -n "$NAMESPACE"
    oc delete all -l app=eventbridgeui -n "$NAMESPACE"
    
    # Configmap/secret の追加
    oc apply -f provisioning/openshift/awseventbridge-configmap.yaml
    oc apply -f provisioning/openshift/awseventbridge-secrets.yaml

    # Postgres/kafka のセットアップ
    oc apply -f provisioning/openshift/postgres.yaml
    oc apply -f provisioning/openshift/kafka.yaml
    oc apply -f provisioning/openshift/kafdrop.yaml

    # reactiveweb Quarkus App
    oc new-app ubi8/openjdk-21~https://github.com/nmushino/sample-kafka-to-aws.git \
        --name=reactiveweb \
        --context-dir=reactive-postgres-web \
        --allow-missing-images \
        --strategy=source \
        -n "$NAMESPACE"
    oc apply -f provisioning/openshift/reactiveweb-deployment.yaml -n "$NAMESPACE"
    oc expose deployment reactiveweb --port=8080 --name=reactiveweb -n "$NAMESPACE"
    oc expose svc reactiveweb --name=reactiveweb -n "$NAMESPACE"

    # postgressynccamel Camel App
    oc new-app ubi8/openjdk-21~https://github.com/nmushino/sample-kafka-to-aws.git \
        --name=postgressynccamel \
        --context-dir=postgres-sync-camel \
        --allow-missing-images \
        --strategy=source \
        -n "$NAMESPACE"
    oc apply -f provisioning/openshift/postgressynccamel-development.yaml -n "$NAMESPACE"

    # eventbridgesynccamel Camel App
    oc new-app ubi8/openjdk-21~https://github.com/nmushino/sample-kafka-to-aws.git \
        --name=eventbridgesynccamel \
        --context-dir=eventbridge-kafka-camel \
        --allow-missing-images \
        --strategy=source \
        -n "$NAMESPACE"
    oc apply -f provisioning/openshift/eventbridgesynccamel-development.yaml -n "$NAMESPACE"
    oc expose deployment eventbridgesynccamel --port=8080 --name=eventbridgesynccamel -n "$NAMESPACE"
    oc expose svc eventbridgesynccamel --name=eventbridgesynccamel -n "$NAMESPACE"
    oc patch route eventbridgesynccamel -n "$NAMESPACE" -p '{"spec":{"tls":{"termination":"edge"}}}'

    # eventbridgeui App
    # oc new-app ubi8/nodejs-20~https://github.com/nmushino/sample-kafka-to-aws.git \
    #     --name=eventbridgeui \
    #     --context-dir=eventbridge-ui \
    #     --allow-missing-images \
    #     --strategy=source \
    #     -n "$NAMESPACE"
    # oc expose deployment eventbridgeui --port=8080 --name=eventbridgeui -n "$NAMESPACE"
    # oc expose svc eventbridgeui --name=eventbridgeui -n "$NAMESPACE"
    cd eventbridge-ui
    tar -czf eventbridgeui.tar.gz .
    oc start-build eventbridgeui --from-archive=eventbridgeui.tar.gz -n "$NAMESPACE"
    oc expose deployment eventbridgeui --port=8080 --name=eventbridgeui -n "$NAMESPACE"
    oc expose svc eventbridgeui --name=eventbridgeui -n "$NAMESPACE"

}

cleanup() {
    echo "クリーンナップ開始..."

    oc delete subscription amq-streams --all -n "$NAMESPACE" --ignore-not-found=true
    oc delete subscription crunchy-postgres-operator --all -n "$NAMESPACE" --ignore-not-found=true
    oc delete all --all -n "$NAMESPACE" --ignore-not-found=true --force --grace-period=0

    read -p "本当にプロジェクトを削除してもよろしいですか？(yes/no): " DELETE_CONFREM
    if [ "$DELETE_CONFREM" == "yes" ]; then
        # KafkaTopic リソースを強制削除
        for topic in $(oc get kafkatopics.kafka.strimzi.io -n "$NAMESPACE" -o name); do
            oc patch $topic -n "$NAMESPACE" --type=merge -p '{"metadata":{"finalizers":[]}}' 
        done
        oc delete project "$NAMESPACE" --force --grace-period=0
    fi
}

case "$1" in
    deploy)
        deploy
        ;;
    cleanup)
        cleanup
        ;;
    *)
        echo -e "${RED}無効なコマンドです: $1${RESET}"
        echo -e "${RED}使用方法: $0 {deploy|cleanup}${RESET}"
        exit 1
        ;;
esac