#!/bin/bash

USER=$1
PAT=$2

if [[ -z $USER || -z $PAT ]]; then
  echo "Usage: pull-gists.sh <githubUsername> <githubPAT>"
  exit 1
fi

GISTS=$(curl -s -u $USER:$PAT \-H 'Accept: application/vnd.github.v3+json' 'https://api.github.com/gists/starred' | jq -rc --arg login $USER '.[] | select(.owner.login == $login and (.created_at | fromdateiso8601) > ("2017-01-01T00:00:00Z" | fromdateiso8601) and .files["README.md"].size > 0) | @base64')

for gist in $GISTS; do
  _jq() {
    echo $gist | base64 -d | jq "$@"
  }

  ID=$(_jq -r '.id')
  NAME=$(_jq -r '.description')
  HTML_URL=$(_jq -r '.html_url')
  RAW_URL=$(_jq -r '.files["README.md"].raw_url')
  POST_DATE=$(_jq -r '.created_at | fromdate | strftime("%Y-%m-%d")')
  FILES=$(_jq -c '[ .files[] | select((.filename | contains("README.md") | not) and (.filename | contains("LICENSE") | not)) | .filename ]')
  
  FILENAME=$(echo $NAME | sed 's/[^[:alnum:]]/-/g')
  POST="site/content/gists/$FILENAME.md"
  

  cat <<EOF > $POST
---
title: $NAME
tags:
  - gist
date: $POST_DATE
gist_url: $HTML_URL
gist_embed_files: $FILES
---
EOF

  echo "Creating post for [$POST_DATE] $NAME ($HTML_URL)"
  curl -s $RAW_URL >> $POST
  
done