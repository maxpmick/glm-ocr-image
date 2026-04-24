FROM vllm/vllm-openai:latest

ARG MODEL_REPO_ID=zai-org/GLM-OCR
ARG MODEL_DIR=/models/glm-ocr

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates git \
    && rm -rf /var/lib/apt/lists/*

RUN python3 -m pip install --no-cache-dir --ignore-installed "blinker>=1.9.0" \
    && python3 -m pip install --no-cache-dir --upgrade \
    "git+https://github.com/huggingface/transformers.git" \
    "glmocr[selfhosted,server]"

RUN mkdir -p "${MODEL_DIR}" \
    && hf download "${MODEL_REPO_ID}" --local-dir "${MODEL_DIR}"

ENV MODEL_ID=${MODEL_DIR}
ENV SERVED_MODEL_NAME=glm-ocr
ENV PORT=8080
ENV GPU_MEMORY_UTILIZATION=0.85
ENV MAX_MODEL_LEN=8192
ENV SPECULATIVE_CONFIG='{"method":"mtp","num_speculative_tokens":3}'

EXPOSE 8080

ENTRYPOINT []

CMD ["sh", "-c", "set -- vllm serve \"${MODEL_ID}\" --served-model-name \"${SERVED_MODEL_NAME}\" --allowed-local-media-path / --host 0.0.0.0 --port \"${PORT}\" --gpu-memory-utilization \"${GPU_MEMORY_UTILIZATION}\" --max-model-len \"${MAX_MODEL_LEN}\"; if [ -n \"${SPECULATIVE_CONFIG}\" ]; then set -- \"$@\" --speculative-config \"${SPECULATIVE_CONFIG}\"; fi; exec \"$@\""]
