#!/bin/bash
# =============================================================================
# Script Name: deploy.sh
# Description: This script deploys the application to OpenShift and verifies the setup.
# Author: Noriaki Mushino
# Date Created: 2025-03-26
# Last Modified: 2025-06-04
# Version: 1.13
#
# Usage:
#   ./deploy.sh setup           - To setup the environment.
#   ./deploy.sh deploy          - To deploy the all application.
#   ./deploy.sh openmetadata    - To deploy the openmetadata application.
#   ./deploy.sh cleanup         - To delete the application.
#
# Prerequisites:
#   - OpenShift CLI (oc) is installed and configured
#   - figlet is installed and configured
#   - User is logged into OpenShift
#   - The Test was conducted on MacOS
#
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

# source.env ファイルのCLUSTER_DOMAIN_NAMEとTOKEN を更新する
sed -i '' "s/^CLUSTER_DOMAIN_NAME=.*$/CLUSTER_DOMAIN_NAME=$DOMAIN_NAME/" $ENV_FILE
sed -i '' "s/^TOKEN=.*$/TOKEN=$DOMAIN_TOKEN/" $ENV_FILE

deploy() {

    echo "デプロイ開始..."

    # 既存Appの削除
    oc delete all -l app=web -n "$NAMESPACE"
    oc delete all -l app=counter -n "$NAMESPACE"
    oc delete all -l app=inventory -n "$NAMESPACE"
    oc delete all -l app=QDCA10Pro -n "$NAMESPACE"
    oc delete all -l app=QDCA10 -n "$NAMESPACE"
    oc delete all -l app=homeoffice-backend -n "$NAMESPACE"
    oc delete all -l app=homeoffice-ui -n "$NAMESPACE"
    oc delete all -l app=customermocker -n "$NAMESPACE"
    
    # Configmap の追加
    oc apply -f openshift/awseventbridge-configmap.yaml

    # awseventbridge Camel App
    oc new-app ubi8/openjdk-21~https://github.com/nmushino/sample-kafka-to-aws.git --name=counter --allow-missing-images --strategy=source -n "$NAMESPACE"
    oc apply -f openshift/awseventbridge-development.yaml -n "$NAMESPACE"
    oc expose deployment web --port=8080 --name=quarkusdroneshop-web -n "$NAMESPACE"
    oc expose svc quarkusdroneshop-web --name=quarkusdroneshop-web -n "$NAMESPACE"

    # Homeoffice UI App
    oc new-app ubi8/nodejs-20~https://github.com/nmushino/quarkusdroneshop-homeoffice-ui.git --name=homeoffice-ui --allow-missing-images --strategy=source -n "$NAMESPACE"
    oc expose deployment homeoffice-ui --port=8080 --name=homeoffice-ui -n "$NAMESPACE"
    oc expose svc homeoffice-ui --name=homeoffice-ui -n "$NAMESPACE"

}

cleanup() {
    echo "クリーンナップ開始..."

    oc delete subscription amq-streams --all -n "$NAMESPACE" --ignore-not-found=true
    oc delete subscription crunchy-postgres-operator --all -n "$NAMESPACE" --ignore-not-found=true
    oc delete operator --all -n openshift-operators --ignore-not-found=true
    oc delete operator --all -n "$NAMESPACE" --ignore-not-found=true
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