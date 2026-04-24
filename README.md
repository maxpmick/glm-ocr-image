# GLM-OCR vLLM Image

This image serves GLM-OCR through vLLM's OpenAI-compatible API.

The Docker build downloads `zai-org/GLM-OCR` into `/models/glm-ocr`, so runtime startup does not need to download model weights.

## Local Run

```bash
docker run --rm --gpus all --ipc=host -p 8080:8080 ghcr.io/maxpmick/glm-ocr-image:latest
```

Health check:

```bash
curl http://localhost:8080/health
```

## Azure Container Apps

```bash
bash scripts/deploy-container-apps.sh
```

## Azure ML Managed Online Endpoint

```bash
bash scripts/deploy-azure-ml.sh
```

Both deployment scripts use `ghcr.io/maxpmick/glm-ocr-image:latest` by default. Override with `IMAGE=...` if you want to deploy a SHA-tagged image.
