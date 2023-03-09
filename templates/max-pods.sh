#!/bin/bash

set -o pipefail
set -o nounset
set -o errexit

eval "$(jq -r '@sh "INSTANCE_TYPE=\(.instance_type) VERSION=\(.cni_version) REGION=\(.region)"')"
SCRIPT_DIR=$(dirname "$0")
PODS_MAX=$(AWS_DEFAULT_REGION=$REGION ./$SCRIPT_DIR/max-pods-calculator.sh --instance-type $INSTANCE_TYPE --cni-version $VERSION  --cni-custom-networking-enabled --cni-prefix-delegation-enabled)
jq -n --arg max "$PODS_MAX" '{"max":$max}'