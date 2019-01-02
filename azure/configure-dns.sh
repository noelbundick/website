#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

HOSTNAME=''
EMAIL=''
KEY=''
TARGET=''
PROXIED=true

show_usage() {
  echo "Usage: configure-dns.sh --hostname <hostname> --email <email> --api-key <api key> --target <target> --proxied <true/false>"
}

parse_arguments() {
  PARAMS=""
  while (( $# )); do
    case "$1" in
      -h|--help)
        show_usage
        exit 0
        ;;
      --hostname)
        HOSTNAME=$2
        shift 2
        ;;
      --email)
        EMAIL=$2
        shift 2
        ;;
      --api-key)
        KEY=$2
        shift 2
        ;;
      --target)
        TARGET=$2
        shift 2
        ;;
      --proxied)
        PROXIED=$2
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
  if [[ -z $HOSTNAME || -z $EMAIL || -z $KEY || -z $TARGET ]]; then
    show_usage
    exit 1
  fi

  DOMAIN=$(echo $HOSTNAME | rev | cut -d '.' -f -2  | rev)
}

cloudflare() {
  curl -s -X GET -H "X-Auth-Email: $EMAIL" -H "X-Auth-Key: $KEY" -H 'Content-Type: application/json' $1
}

cloudflare_update() {
  echo "sending: $3 to $2"
  curl -s -X $1 -H "X-Auth-Email: $EMAIL" -H "X-Auth-Key: $KEY" -H 'Content-Type: application/json' $2 --data $3
}

execute() {
  ZONE=$(cloudflare "https://api.cloudflare.com/client/v4/zones?name=$DOMAIN")
  ZONE_ID=$(echo $ZONE | jq -r '.result[0].id')

  DATA=$(jq -c -n '{type:"CNAME", name:$name, content:$content, proxied:$proxied}' --arg name $HOSTNAME --arg content $TARGET --argjson proxied $PROXIED)

  RECORD=$(cloudflare "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?type=CNAME&name=$HOSTNAME")
  RECORD_ID=$(echo $RECORD | jq -r '.result[0].id')

  if [ $RECORD_ID = "null" ]; then
    cloudflare_update POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" $DATA
  else
    cloudflare_update PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID" $DATA
  fi

  # wait for DNS record to be visible
  set +eo pipefail
  while true; do
    echo "Checking for DNS entry"
    
    dig @1.1.1.1 $HOSTNAME | grep 'ANSWER SECTION'
    if [ $? -eq 0 ]; then
      break
    fi

    sleep 1
  done
  set -eo pipefail
}

parse_arguments "$@"
validate_arguments

execute

