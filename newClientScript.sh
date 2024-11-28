#! /bin/bash

#This script receives information from client, and generates configuration yaml files, which executes by argo-cd in git repository.
#Server must have installed kubeseal to generate secrets for passwords https://github.com/bitnami-labs/sealed-secrets?tab=readme-ov-file#kubeseal

set -e 

if [ $# -lt 2 ]; then
    echo "Script requires: company name as a first argument; elastic file storage ID as a second argument; "
    exit 1
fi

regex="^[[a-zA-Z0-9_-:space:]]+$"

if ! [[ "$1" =~ $regex2 ]]; then
  echo "Invalid: Contains special characters, company name should contain: letters, numbers, underscore, minus sign and space."
  exit 1
fi

export KEYCLOAK_CHART_VERSION=24.1.0
export COMPANY=${1// /_} #replace spaces to dashes for company name

export PRECONFIG_APPLICATION_NAME="keycloak-$COMPANY-preconfig-application"
export APPLICATION_NAME="keycloak-$COMPANY-application"
export NAMESPACE="$COMPANY-ns"

export DEFAULT_STORAGE_CLASS="keycloak-storage-class" #need to be generated, value without namespace for whole system must be uniq
export PERSISTENT_VOLUME_NAME="keycloak-general-pv-$COMPANY"
export USER_VOLUME_PATH="/mnt/data/keycloak/user-4"   #"/mnt/data/keycloak/$COMPANY" #must be uniq for each user, this folder contains themes

export EFS_STORAGECLASS_NAME="efs-sc" #static need to be changed if storageclass is changed
export EFS_PVC_NAME="keycloak-pv-claim"
export EFS_VOLUME_NAME="keycloak-efs-pv-$COMPANY"
export EFS_ID=$2   #"fs-0db109d8bea20374f"
export EFS_USER_PATH="/keycloak/user-3-themes" #this path must be created before provisioning

export ADMIN_USER_NAME="user"
export ADMIN_USER_PASSWORD=$(echo -ne "PaP\$w0R}|{0PeC" | base64)
export POSTGRES_USER_NAME="db_user"
export POSTGRES_USER_PASSWORD=$(echo -ne "9t3tggid47" | base64) #need to generate and store in some place
export POSTGRES_PASSWORD=$(echo -ne "12345pass" | base64) #need to generate and store in some volume
export POSTGRES_SECRET_NAME="keycloak-postgresql-$COMPANY-secret"
export KEYCLOAK_SECRET_NAME="keycloak-app-$COMPANY-secret"

export TLS_ISSUER_NAME="keycloak-staging"
export HOSTNAME="user-1.alphabetagamazeta.site"

export PRECONFIG_VALUES_FILE="preconfig_values_$COMPANY.yaml"

#Generate sealed secret that will be decrypted by "sealed-secret" app on cluster side 
envsubst < secret_template.yaml > secret_$COMPANY.yaml
kubeseal -f secret_$COMPANY.yaml -w sealed_secret_$COMPANY.yaml

export CUSTOM_USER_SEALED_PASSWORD=$(awk '/^    password:/ {print $2}' sealed-secret.yaml)
export POSTGRES_SEALED_PASSWORD=$(awk '/^    postgres-password:/ {print $2}' sealed-secret.yaml)
export ADMIN_SEALED_PASSWORD=$(awk '/^    admin-password:/ {print $2}' sealed-secret.yaml)

#Create yaml files which are configureation of new client.
envsubst < preconfig_values_template.yaml > $PRECONFIG_VALUES_FILE
envsubst < preconfing_app_template.yaml > preconfig_app_$COMPANY.yaml
envsubst < client_app_template.yaml > company_$COMPANY.yaml

#Move generated files to specific folder. 
mv $PRECONFIG_VALUES_FILE./HelmCharts/initial-configuration-keycloak/CompaniesValues
mv preconfig_app_$COMPANY.yaml ./staging/applications
mv company_$COMPANY.yaml ./staging/applications


#Delete secret file, sealed secret file exit in custom helm chart
rm secret_$COMPANY.yaml 
rm sealed_secret_$COMPANY.yaml

#not redy exit 
exit 0


#git pull 
#git add . 
#git commit -m "Added new company $COMPANY"
#git push