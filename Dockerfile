ARG PYTHON_BASE_IMAGE=python:3.11-slim
FROM ${PYTHON_BASE_IMAGE}

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_DEFAULT_TIMEOUT=180 \
    PIP_RETRIES=8 \
    AML_MEMORY_PROFILE=schema-entity \
    AML_MEMORY_CONFIG=/app/runtime/memory.yml \
    AML_STATE_DIR=/app/state
LABEL org.opencontainers.image.title="AML Memory API - Schema and entity chain" \
      org.opencontainers.image.source="https://github.com/chin-alt/aml-memory-api-schema" \
      org.opencontainers.image.revision="PR #337 dda7ed9c51d1c8510a7430fad7f1de3d9b43ed63 on 55e199fdcc6023515c3fc82c517d6aafc58cb183" \
      ai.agentmemories.memory-profile="schema-entity"

WORKDIR /app
COPY memory /app/agent-memory
COPY adapter /app/adapter
RUN pip install --no-cache-dir 'setuptools>=70,<81' 'pymilvus>=2.4,<2.5' \
       '/app/agent-memory[deploy]' /app/adapter
RUN python /app/adapter/aml_adapter/deploy_config.py --profile "schema-entity" \
       --output /app/runtime/memory.yml \
    && useradd --uid 10001 --create-home appuser \
    && mkdir -p /app/state \
    && chown -R appuser:appuser /app/state /app/runtime
USER appuser
WORKDIR /app/adapter
EXPOSE 8000
STOPSIGNAL SIGTERM
CMD ["python", "-m", "uvicorn", "aml_adapter.app:create_app", "--factory", "--host", "0.0.0.0", "--port", "8000", "--workers", "1", "--no-access-log", "--timeout-graceful-shutdown", "1800"]
