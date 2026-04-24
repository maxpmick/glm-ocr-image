#!/usr/bin/env bash
set -euo pipefail

RESOURCE_GROUP="${RESOURCE_GROUP:-rg-glm-ocr}"
LOCATION="${LOCATION:-swedencentral}"
ENVIRONMENT_NAME="${ENVIRONMENT_NAME:-cae-glm-ocr}"
APP_NAME="${APP_NAME:-ca-glm-ocr-vllm}"
IMAGE="${IMAGE:-ghcr.io/maxpmick/glm-ocr-image:latest}"
WORKLOAD_PROFILE_NAME="${WORKLOAD_PROFILE_NAME:-NC8as-T4}"
WORKLOAD_PROFILE_TYPE="${WORKLOAD_PROFILE_TYPE:-Consumption-GPU-NC8as-T4}"
MIN_REPLICAS="${MIN_REPLICAS:-1}"
MAX_REPLICAS="${MAX_REPLICAS:-3}"

az group create \
  --name "${RESOURCE_GROUP}" \
  --location "${LOCATION}"

az containerapp env create \
  --name "${ENVIRONMENT_NAME}" \
  --resource-group "${RESOURCE_GROUP}" \
  --location "${LOCATION}"

az containerapp env workload-profile add \
  --name "${ENVIRONMENT_NAME}" \
  --resource-group "${RESOURCE_GROUP}" \
  --workload-profile-name "${WORKLOAD_PROFILE_NAME}" \
  --workload-profile-type "${WORKLOAD_PROFILE_TYPE}"

az containerapp create \
  --name "${APP_NAME}" \
  --resource-group "${RESOURCE_GROUP}" \
  --environment "${ENVIRONMENT_NAME}" \
  --image "${IMAGE}" \
  --target-port 8080 \
  --ingress external \
  --cpu 8.0 \
  --memory 56.0Gi \
  --workload-profile-name "${WORKLOAD_PROFILE_NAME}" \
  --min-replicas "${MIN_REPLICAS}" \
  --max-replicas "${MAX_REPLICAS}" \
  --env-vars \
    SERVED_MODEL_NAME=glm-ocr \
    PORT=8080 \
    GPU_MEMORY_UTILIZATION=0.85 \
    MAX_MODEL_LEN=8192 \
    SPECULATIVE_CONFIG='{"method":"mtp","num_speculative_tokens":3}'

az containerapp show \
  --name "${APP_NAME}" \
  --resource-group "${RESOURCE_GROUP}" \
  --query "properties.configuration.ingress.fqdn" \
  --output tsv
