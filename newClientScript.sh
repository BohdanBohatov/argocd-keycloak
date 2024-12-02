#! /bin/bash

#This script receives information from client, and generates configuration yaml files, which executes by argo-cd in git repository.
#Server must have installed kubeseal to generate secrets for passwords https://github.com/bitnami-labs/sealed-secrets?tab=readme-ov-file#kubeseal

set -e 

if [ $# -lt 1 ]; then
    echo "Script requires: company name as a first argument"
    exit 1
fi

regex="^[[a-zA-Z0-9_-:space:]]+$"

if ! [[ "$1" =~ $regex2 ]]; then
  echo "Invalid: Contains special characters, company name should contain: letters, numbers, underscore, minus sign and space."
  exit 1
fi

export ENV_SIGN="$"
export KEYCLOAK_CHART_VERSION=24.1.0
export COMPANY=${1// /_} #replace spaces to dashes for company name

export PRECONFIG_APPLICATION_NAME="keycloak-$COMPANY-preconfig-application"
export APPLICATION_NAME="keycloak-$COMPANY-application"
export NAMESPACE="$COMPANY-ns"

export DEFAULT_STORAGE_CLASS="keycloak-$COMPANY-storage-class"
export PERSISTENT_VOLUME_NAME="keycloak-general-pv-$COMPANY"
export USER_VOLUME_PATH="/mnt/data/keycloak/$COMPANY" #TODO CREATE backups for this folder. IF user is deleted need clear this folder. 

export EFS_STORAGECLASS_NAME="efs-sc" #static need to be changed if storageclass is changed
export EFS_PVC_NAME="keycloak-pv-claim"
export EFS_VOLUME_NAME="keycloak-efs-pv-$COMPANY"
export EFS_ID="fs-0db109d8bea20374f"
export EFS_USER_PATH="/keycloak/user-3-themes" #this path must be created before provisioning, folder contains themes. TODO backup folders with themes.

AD_USER_PASSWORD=$(pwgen -cnys 10 1)
PS_USR_PASSWORD=$(pwgen -cnys 10 1)
PS_PASSWORD=$(pwgen -cnys 10 1)

export ADMIN_USER_PASSWORD=$(echo -n $AD_USER_PASSWORD| base64)
export POSTGRES_USER_PASSWORD=$(echo -n $PS_USR_PASSWORD | base64)
export POSTGRES_PASSWORD=$(echo -n $PS_PASSWORD | base64)
export ADMIN_USER_NAME="user"
export POSTGRES_USER_NAME="db_user"
export POSTGRES_SECRET_NAME="keycloak-postgresql-$COMPANY-secret"
export KEYCLOAK_SECRET_NAME="keycloak-app-$COMPANY-secret"

export TLS_ISSUER_NAME="keycloak-staging"
export HOSTNAME="$COMPANY.alphabetagamazeta.site"

export PRECONFIG_VALUES_FILE="preconfig_values_$COMPANY.yaml"

#Generate sealed secret that will be decrypted by "sealed-secret" app on cluster side 
envsubst < secret_template.yaml > secret_$COMPANY.yaml
kubeseal -f secret_$COMPANY.yaml -w sealed_secret_$COMPANY.yaml

export CUSTOM_USER_SEALED_PASSWORD=$(awk '/^    password:/ {print $2}' sealed_secret_$COMPANY.yaml)
export POSTGRES_SEALED_PASSWORD=$(awk '/^    postgres-password:/ {print $2}' sealed_secret_$COMPANY.yaml)
export ADMIN_SEALED_PASSWORD=$(awk '/^    admin-password:/ {print $2}' sealed_secret_$COMPANY.yaml)

#Create yaml files which are configureation of new client.
envsubst < preconfig_values_template.yaml > $PRECONFIG_VALUES_FILE
envsubst < preconfing_app_template.yaml > preconfig_$COMPANY\_application.yaml
envsubst < client_app_template.yaml > company_$COMPANY\_application.yaml

#Move generated files to specific folder. 
mv $PRECONFIG_VALUES_FILE ./HelmCharts/initial-configuration-keycloak/CompaniesValues
mv preconfig_$COMPANY\_application.yaml ./staging/applications
mv company_$COMPANY\_application.yaml ./staging/applications


#Delete secret file, sealed secret file exit in custom helm chart
rm secret_$COMPANY.yaml 
rm sealed_secret_$COMPANY.yaml

git pull 
git add . 
git commit -m "Added new company $COMPANY"
git push

echo "Added new company $COMPANY"