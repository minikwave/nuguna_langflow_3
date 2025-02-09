FROM python:3.11-slim

WORKDIR /app

# 기본 도구 설치
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# 호환되는 버전으로 설치
RUN pip install --no-cache-dir \
    langflow==0.0.78 \
    langchain==0.0.176 \
    openai==0.27.8 \
    protobuf==3.20.3 \
    python-dotenv>=1.0.0

ENV LANGFLOW_HOST=0.0.0.0
ENV LANGFLOW_PORT=7860

EXPOSE 7860

CMD ["python", "-m", "langflow", "run", "--host", "0.0.0.0", "--port", "7860"] 