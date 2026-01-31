# Stage 1: Build Python dependencies with uv (Python 3.12 pinned)
FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim AS builder
ENV UV_COMPILE_BYTECODE=1 UV_LINK_MODE=copy UV_PYTHON_DOWNLOADS=0

ARG COMFYUI_VERSION=v0.11.1

# Clone ComfyUI
RUN apt-get update && apt-get install -y git && \
    git clone --depth 1 --branch ${COMFYUI_VERSION} \
    https://github.com/comfy-org/ComfyUI.git /ComfyUI

# Create venv and install all Python dependencies
ENV VIRTUAL_ENV=/opt/venv
RUN uv venv $VIRTUAL_ENV
RUN uv pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu && \
    uv pip install -r /ComfyUI/requirements.txt && \
    uv pip install wait-for-it

# Stage 2: Final image with Playwright
FROM mcr.microsoft.com/playwright:v1.58.1-noble

# Install pnpm
RUN npm install -g pnpm

# Install fonts to match GitHub Actions runner
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      fonts-dejavu-core fonts-noto-core fonts-noto-cjk fonts-ubuntu && \
    rm -rf /var/lib/apt/lists/*

# Copy venv and ComfyUI from builder
COPY --from=builder /opt/venv /opt/venv
COPY --from=builder /ComfyUI /ComfyUI

# Fix venv Python symlinks to point to system Python (builder used /usr/local/bin/python)
RUN ln -sf /usr/bin/python3 /opt/venv/bin/python && \
    ln -sf python /opt/venv/bin/python3 && \
    ln -sf python /opt/venv/bin/python3.12

# Set up Python paths
ENV PATH="/opt/venv/bin:$PATH"
ENV VIRTUAL_ENV="/opt/venv"

# Create devtools directory (for mounting/copying at runtime)
RUN mkdir -p /ComfyUI/custom_nodes/ComfyUI_devtools

# Set ownership for pwuser (from Playwright base image)
RUN mkdir -p /app && chown -R pwuser:pwuser /ComfyUI /opt/venv /app

USER pwuser
WORKDIR /app
