#!/usr/bin/env bash
set -euo pipefail

RESOURCE_GROUP="${RESOURCE_GROUP:-rg-glm-ocr}"
LOCATION="${LOCATION:-swedencentral}"
WORKSPACE_NAME="${WORKSPACE_NAME:-mlw-glm-ocr}"
IMAGE="${IMAGE:-ghcr.io/maxpmick/glm-ocr-image:latest}"
ENDPOINT_FILE="${ENDPOINT_FILE:-azureml/endpoint.yml}"
DEPLOYMENT_TEMPLATE="${DEPLOYMENT_TEMPLATE:-azureml/deployment.yml}"
DEPLOYMENT_FILE="$(mktemp)"

cleanup() {
  rm -f "${DEPLOYMENT_FILE}"
}
trap cleanup EXIT

az extension add --name ml --upgrade --yes

az group create \
  --name "${RESOURCE_GROUP}" \
  --location "${LOCATION}"

if ! az ml workspace show \
  --name "${WORKSPACE_NAME}" \
  --resource-group "${RESOURCE_GROUP}" \
  >/dev/null 2>&1; then
  az ml workspace create \
    --name "${WORKSPACE_NAME}" \
    --resource-group "${RESOURCE_GROUP}" \
    --location "${LOCATION}"
fi

export IMAGE

if command -v python3 >/dev/null 2>&1; then
  PYTHON_BIN=python3
else
  PYTHON_BIN=python
fi

"${PYTHON_BIN}" -c '
import os
import pathlib
import sys

template_path = pathlib.Path(sys.argv[1])
output_path = pathlib.Path(sys.argv[2])
content = template_path.read_text()
content = content.replace("${IMAGE}", os.environ["IMAGE"])
output_path.write_text(content)
' "${DEPLOYMENT_TEMPLATE}" "${DEPLOYMENT_FILE}"

az ml online-endpoint create \
  --file "${ENDPOINT_FILE}" \
  --resource-group "${RESOURCE_GROUP}" \
  --workspace-name "${WORKSPACE_NAME}"

az ml online-deployment create \
  --file "${DEPLOYMENT_FILE}" \
  --resource-group "${RESOURCE_GROUP}" \
  --workspace-name "${WORKSPACE_NAME}" \
  --all-traffic

az ml online-endpoint show \
  --name glm-ocr-vllm \
  --resource-group "${RESOURCE_GROUP}" \
  --workspace-name "${WORKSPACE_NAME}" \
  --query scoring_uri \
  --output tsv
