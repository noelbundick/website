#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

RG=''
LOCATION=''
BASENAME=''
DOMAINNAME=''

show_usage() {
  echo "Usage: deploy-resources.sh --resource-group <rg> --location <location> --base-name <base-name> --domain-name <domain-name>"
}

parse_arguments() {
  PARAMS=""
  while (( $# )); do
    case "$1" in
      -h|--help)
        show_usage
        exit 0
        ;;
      -g|--resource-group)
        RG=$2
        shift 2
        ;;
      -l|--location)
        LOCATION=$2
        shift 2
        ;;
      -n|--base-name)
        BASENAME=$2
        shift 2
        ;;
      -d|--domain-name)
        DOMAINNAME=$2
        shift 2
        ;;
      --)
        shift
        break
        ;;
      -*|--*)
        echo "Unsupported flag $1" >&2
        exit 1
        ;;
      *)
        PARAMS="$PARAMS $1"
        shift
        ;;
    esac
  done
}

validate_arguments() {
  if [[ -z $RG || -z $LOCATION || -z $BASENAME || -z $DOMAINNAME ]]; then
    show_usage
    exit 1
  fi
}

deploy() {
  az group create -n $RG -l $LOCATION
  RG_DEPLOYMENT=$(az group deployment create -g $RG --template-file ./azuredeploy.json --parameters baseName=$BASENAME customHostname=$DOMAINNAME -o json)

  # Extract output vars
  FUNCTION_APP=$(echo $RG_DEPLOYMENT | jq -r .properties.outputs.functionappName.value)
  STORAGE_ACCOUNT=$(echo $RG_DEPLOYMENT | jq -r .properties.outputs.storageName.value)
  WEB_ENDPOINT=$(echo $RG_DEPLOYMENT | jq -r .properties.outputs.webEndpoint.value)
  
  # Upload proxy configuration
  cat proxies.template.json | jq -M ".proxies.wildcard.backendUri = \"$WEB_ENDPOINT{path}\" | ." > proxies.json
  az storage file upload --account-name $STORAGE_ACCOUNT -s $FUNCTION_APP --source proxies.json -p site/wwwroot/proxies.json
}

parse_arguments "$@"
validate_arguments

set -x
deploy