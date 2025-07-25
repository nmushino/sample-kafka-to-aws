#!/bin/bash
# =============================================================================
# Script Name: postgres.sh
# Description: This script is for connecting to PostgreSQL via Port-Fowad.
# Author: Noriaki Mushino
# Last Modified: 2025-07-25
# Version: 1.0
# =============================================================================

NAMESPACE="awseventbridge-demo"

echo "###################################"
echo "このシェルはメンテナンスシェルです"
echo "###################################"
echo

echo "Postgres Password: $(oc get secret systemdb-pguser-systemadmin -o jsonpath='{.data.password}' -n $NAMESPACE | base64 -d)"
POSTGRES_POD_NAME=$(oc get pods -o jsonpath='{.items[*].metadata.name}' -n $NAMESPACE | tr ' ' '\n' | grep systemdb | head -n 1)
oc port-forward pod/$POSTGRES_POD_NAME 5432:5432 -n $NAMESPACE
