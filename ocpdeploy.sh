#!/bin/bash
# =============================================================================
# Script Name: deploy.sh
# Description: This script deploys the application to OpenShift and verifies the setup.
# Author: Noriaki Mushino
# Last Modified: 2025-07-25
# Version: 1.13#
# =============================================================================

NAMESPACE_EB="awseventbridge-demo"
NAMESPACE_DZ="debezium-demo"
NAMESPACE_SM="sample-demo"
REGISTRY="image-registry.openshift-image-registry.svc:5000"
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


    echo "デプロイするプロジェクトを選択してください："
    echo "1) awseventbridge-demo"
    echo "2) debezium-demo & sample-demo"
    read -p "番号を入力してください（1または2）: " SELECTION

    case "$SELECTION" in
        1)
            oc new-project "$NAMESPACE_EB"

            # 既存Appの削除
            oc delete all -l app=reactiveweb -n "$NAMESPACE_EB"
            oc delete all -l app=postgressynccamel -n "$NAMESPACE_EB"
            oc delete all -l app=eventbridgesynccamel -n "$NAMESPACE_EB"
            oc delete all -l app=eventbridgeui -n "$NAMESPACE_EB"
            
            # Configmap/secret の追加
            oc apply -f provisioning/openshift/awseventbridge-configmap.yaml -n "$NAMESPACE_EB"
            oc apply -f provisioning/openshift/awseventbridge-secrets.yaml -n "$NAMESPACE_EB"

            # Postgres/kafka のセットアップ
            oc apply -f provisioning/openshift/postgres1.yaml -n "$NAMESPACE_EB"
            oc apply -f provisioning/openshift/kafka1.yaml -n "$NAMESPACE_EB"
            oc apply -f provisioning/openshift/kafdrop1.yaml -n "$NAMESPACE_EB"

            # reactiveweb Quarkus App
            oc new-app ubi8/openjdk-21~https://github.com/nmushino/sample-kafka-to-aws.git \
                --name=reactiveweb \
                --context-dir=reactive-postgres-web \
                --allow-missing-images \
                --strategy=source \
                -n "$NAMESPACE_EB"
            oc apply -f provisioning/openshift/reactiveweb-deployment.yaml -n "$NAMESPACE_EB"
            oc expose deployment reactiveweb --port=8080 --name=reactiveweb -n "$NAMESPACE_EB"
            oc expose svc reactiveweb --name=reactiveweb -n "$NAMESPACE_EB"

            # postgressynccamel Camel App
            oc new-app ubi8/openjdk-21~https://github.com/nmushino/sample-kafka-to-aws.git \
                --name=postgressynccamel \
                --context-dir=postgres-sync-camel \
                --allow-missing-images \
                --strategy=source \
                -n "$NAMESPACE_EB"
            oc apply -f provisioning/openshift/postgressynccamel-development.yaml -n "$NAMESPACE_EB"

            # eventbridgesynccamel Camel App
            oc new-app ubi8/openjdk-21~https://github.com/nmushino/sample-kafka-to-aws.git \
                --name=eventbridgesynccamel \
                --context-dir=eventbridge-kafka-camel \
                --allow-missing-images \
                --strategy=source \
                -n "$NAMESPACE_EB"
            oc apply -f provisioning/openshift/eventbridgesynccamel-development.yaml -n "$NAMESPACE_EB"
            oc expose deployment eventbridgesynccamel --port=8080 --name=eventbridgesynccamel -n "$NAMESPACE_EB"
            oc expose svc eventbridgesynccamel --name=eventbridgesynccamel -n "$NAMESPACE_EB"
            oc patch route eventbridgesynccamel -n "$NAMESPACE_EB" -p '{"spec":{"tls":{"termination":"edge"}}}'

            # eventbridgeui
            # Secretがあるため回避策
            cd ./eventbridge-ui
            podman buildx build --platform linux/amd64 -t eventbridgeui .
            # Tag ローカルイメージ
            podman tag eventbridgeui "$REGISTRY"/"$NAMESPACE_EB"/eventbridgeui:latest

            # Push to internal OpenShift registry
            podman login -u $(oc whoami) -p $(oc whoami -t) --tls-verify=false "$REGISTRY"
            oc project "$NAMESPACE_EB"
            podman push --tls-verify=false eventbridgeui:latest "$REGISTRY"/"$NAMESPACE_EB"/eventbridgeui:latest
            oc create deployment eventbridgeui --image="$REGISTRY"/"$NAMESPACE_EB"/eventbridgeui:latest
            oc expose deployment eventbridgeui --port=8080 --name=eventbridgeui -n "$NAMESPACE_EB"
            oc expose svc eventbridgeui --name=eventbridgeui -n "$NAMESPACE_EB"
            ;;
        2)
            oc new-project "$NAMESPACE_DZ"
            oc new-project "$NAMESPACE_SM"
            oc delete all -l app=reactivewebupdate -n "$NAMESPACE_DZ"
            oc delete all -l app=kafkasynccamel -n "$NAMESPACE_DZ"
            oc delete all -l app=reactivesample -n "$NAMESPACE_SM"
            
            # Configmap/secret の追加
            oc apply -f provisioning/openshift/debezium-configmap.yaml -n "$NAMESPACE_DZ"
            oc apply -f provisioning/openshift/debezium-secrets.yaml -n "$NAMESPACE_DZ"
            oc apply -f provisioning/openshift/sample-configmap.yaml -n "$NAMESPACE_SM"
            oc apply -f provisioning/openshift/sample-secrets.yaml -n "$NAMESPACE_SM"

            # Debezium Connector の作成(カスタム)
            cd provisioning/podman
            podman build --platform=linux/amd64 -t quay.io/nmushino/kafka-connect-debezium:latest .
            podman push quay.io/nmushino/kafka-connect-debezium:latest
            cd ../..
            
            # Postgres/kafka のセットアップ
            oc apply -f provisioning/openshift/postgres2.yaml -n "$NAMESPACE_DZ"
            oc apply -f provisioning/openshift/kafka2.yaml -n "$NAMESPACE_DZ"
            oc apply -f provisioning/openshift/kafdrop2.yaml -n "$NAMESPACE_DZ"
            oc apply -f provisioning/openshift/postgres3.yaml -n "$NAMESPACE_SM"
            oc apply -f provisioning/openshift/debezium.yaml -n "$NAMESPACE_DZ"

            # reactivewebupdate Quarkus App
            oc new-app ubi8/openjdk-21~https://github.com/nmushino/sample-kafka-to-aws.git \
                --name=reactivewebupdate \
                --context-dir=reactive-postgres-webupdate \
                --allow-missing-images \
                --strategy=source \
                -n "$NAMESPACE_DZ"
            oc apply -f provisioning/openshift/reactivewebupdate-deployment.yaml -n "$NAMESPACE_DZ"
            oc expose deployment reactivewebupdate --port=8080 --name=reactivewebupdate -n "$NAMESPACE_DZ"
            oc expose svc reactivewebupdate --name=reactivewebupdate -n "$NAMESPACE_DZ"
            
            # kafkasynccamel Camel App
            oc new-app ubi8/openjdk-21~https://github.com/nmushino/sample-kafka-to-aws.git \
                --name=kafkasynccamel \
                --context-dir=kafka-sync-camel \
                --allow-missing-images \
                --strategy=source \
                -n "$NAMESPACE_DZ"
            oc apply -f provisioning/openshift/kafkasynccamel-development.yaml -n "$NAMESPACE_DZ"
            
            #  reactivesample Quarkus App
            oc new-app ubi8/openjdk-21~https://github.com/nmushino/sample-kafka-to-aws.git \
                --name=reactivesample \
                --context-dir=reactive-sample-web \
                --allow-missing-images \
                --strategy=source \
                -n "$NAMESPACE_SM"
            oc apply -f provisioning/openshift/reactivesample-deployment.yaml -n "$NAMESPACE_SM"
            oc expose deployment reactivesample --port=8080 --name=reactivesample -n "$NAMESPACE_SM"
            oc expose svc reactivesample --name=reactivesample -n "$NAMESPACE_SM"
            
            ;;
        *)
            echo "無効な選択です。スクリプトを終了します。"
            exit 1
            ;;
    esac
}

cleanup() {
    echo "クリーンナップ開始..."

    echo "削除するプロジェクトを選択してください："
    echo "1) awseventbridge-demo"
    echo "2) debezium-demo & sample-demo"
    read -p "番号を入力してください（1または2）: " SELECTION

    case "$SELECTION" in
        1)
            oc delete subscription amq-streams --all -n "$NAMESPACE_EB" --ignore-not-found=true
            oc delete subscription crunchy-postgres-operator --all -n "$NAMESPACE_EB" --ignore-not-found=true
            oc delete all --all -n "$NAMESPACE_EB" --ignore-not-found=true --force --grace-period=0

            read -p "本当にプロジェクトを削除してもよろしいですか？(yes/no): " DELETE_CONFREM
            if [ "$DELETE_CONFREM" == "yes" ]; then
                oc delete project "$NAMESPACE_EB" --force --grace-period=0
            fi
            ;;
        2)
            oc delete subscription amq-streams --all -n "$NAMESPACE_DZ" --ignore-not-found=true
            oc delete subscription crunchy-postgres-operator --all -n "$NAMESPACE_DZ" --ignore-not-found=true
            oc delete all --all -n "$NAMESPACE_DZ" --ignore-not-found=true --force --grace-period=0
            oc delete subscription amq-streams --all -n "$NAMESPACE_SM" --ignore-not-found=true
            oc delete subscription crunchy-postgres-operator --all -n "$NAMESPACE_SM" --ignore-not-found=true
            oc delete all --all -n "$NAMESPACE_SM" --ignore-not-found=true --force --grace-period=0


            read -p "本当にプロジェクトを削除してもよろしいですか？(yes/no): " DELETE_CONFREM
            if [ "$DELETE_CONFREM" == "yes" ]; then
                oc delete project "$NAMESPACE_DZ" --force --grace-period=0
                oc delete project "$NAMESPACE_SM" --force --grace-period=0
            fi
            ;;
        *)
            echo "無効な選択です。スクリプトを終了します。"
            exit 1
            ;;
    esac

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


# {
#   "name": "debezium-connector",
#   "config": {
#     "connector.class": "io.debezium.connector.postgresql.PostgresConnector",
#     "database.hostname": "systemdb-primary",
#     "database.port": "5432",
#     "database.user": "systemadmin",
#     "database.password": "postgres",
#     "database.dbname": "systemdb",
#     "database.server.name": "server",
#     "plugin.name": "pgoutput",
#     "slot.name": "debezium_slot",
#     "publication.name": "debezium_publication",
#     "tombstones.on.delete": "false",
#     "include.schema.changes": "false",
#     "topic.prefix": "system"
#   }
# }