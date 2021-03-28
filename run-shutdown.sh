#!/usr/bin/env bash
set -Eeuo pipefail

if [[ "$WORKER_NAME" != "pipeline-"* ]] ;
then
  printf "'%s' is not a valid worker name (must match 'pipeline-*')." "$WORKER_NAME"
  exit 1
fi

printf "Deregistering agent %s\n" "$WORKER_NAME"

vmId=$(
  az deployment group show \
    --name "$WORKER_NAME" \
    --resource-group "$WORKER_NAME" \
    --subscription "$SUBSCRIPTION" \
    --query "properties.outputs.vmId.value" \
    --output tsv
)

# shellcheck disable=SC2016
envsubst '${PAT_TOKEN}' <  shutdown.sh > shutdown-replaced.sh
script_content=$(cat shutdown-replaced.sh | gzip -9 | base64 -w 0)

az vm extension set \
  --publisher "Microsoft.Azure.Extensions" \
  --name "CustomScript" \
  --version "2.0" \
  --ids "$vmId" \
  --protected-settings "{\"script\":\"$script_content\"}"

printf "Deleting deployment %s\n" "$WORKER_NAME"

az group delete \
  --name "$WORKER_NAME" \
  --subscription "$SUBSCRIPTION" \
  --yes
