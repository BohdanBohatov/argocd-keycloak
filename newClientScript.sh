#! /bin/bash

if [ $# -lt 2 ]; then
    echo "Script requires: company name as a first argument; elastic file storage ID as a second argument; "
    exit 1
fi

if ! [[ "$1" =~ ^[a-zA-Z0-9]+$ ]]; then
  echo "Invalid: Contains other characters."
  exit 1
fi

export COMPANY=${1// /_} #remove spaces from company name

export KEYCLOAK_CHART_VERSION=24.1.0

export APPLICATION_NAME= #need generate with company name and ad date or smth uniq
export NAMESPACE=

export DEFAULT_STORAGE_CLASS="keycloak-user-3-storage" #need to be generated, value without namespace for whole system must be uniq
export PERSISTENT_VOLUME_NAME="keycloak-general-pv-user-3"
export USER_VOLUME_PATH="/mnt/data/keycloak/user-4" #must be uniq for each user, this folder contains

export EFS_STORAGECLASS_NAME="efs-sc" #static need to be changed if storageclass is changed
export EFS_PVC_NAME="keycloak-pv-claim"
export EFS_VOLUME_NAME="keycloak-efs-pv-user-3"
export EFS_ID="fs-0db109d8bea20374f"
export EFS_USER_PATH="/keycloak/user-3-themes"

export ADMIN_USER_NAME="user"
export ADMIN_USER_PASSWORD="PaP\$w0R}|{0PeC" #don't forget to shield symbols test with entering "$"
export POSTGRES_USER_NAME="db_user"
export POSTGRES_USER_PASSWORD="9t3tggid47" #need to generate and store in some place
export POSTGRES_PASSWORD="12345pass" #need to generate and store in some volume

export TLS_ISSUER_NAME="keycloak-staging"
export HOSTNAME="alphabetagamazeta.site"


envsubst < newClientTemplate.yaml > company_$COMPANY.yaml #need add some user name to template
