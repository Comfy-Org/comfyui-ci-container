FROM mcr.microsoft.com/playwright:v1.57.0-noble

# Install pnpm
RUN npm install -g pnpm

# ComfyUI version to cache (update when new version released)
ARG COMFYUI_VERSION=v0.5.1

# Clone ComfyUI at pinned version
RUN git clone --depth 1 --branch ${COMFYUI_VERSION} \
    https://github.com/comfyanonymous/ComfyUI.git /ComfyUI

# Pre-create custom_nodes directory for devtools
RUN mkdir -p /ComfyUI/custom_nodes/ComfyUI_devtools

# Install python and fonts to match GitHub Actions runner
RUN apt-get update && \
    # Install Python
    apt-get install -y python3 curl && \
    # Install fonts to match Ubuntu Desktop/GitHub runner font metrics
    apt-get install -y --no-install-recommends \
        fonts-dejavu-core \
        fonts-noto-core \
        fonts-noto-cjk \
        fonts-ubuntu && \
    # Align with upstream Python image and don't be externally managed:
    # https://github.com/docker-library/python/issues/948
    rm /usr/lib/python3.12/EXTERNALLY-MANAGED && \
    update-alternatives --install /usr/bin/python python /usr/bin/python3 1 && \
    curl -sSL https://bootstrap.pypa.io/get-pip.py -o get-pip.py && \
    python get-pip.py && \
    rm get-pip.py && \
    # Feature-parity with node.js base images.
    apt-get install -y --no-install-recommends git openssh-client gpg && \
    # clean apt cache
    rm -rf /var/lib/apt/lists/*

# Set ownership for app directory
RUN mkdir -p /app && chown -R pwuser:pwuser /app /ComfyUI

# Switch to non-root user
USER pwuser

# Set up user-installed packages paths before pip install
ENV PATH="/home/pwuser/.local/bin:${PATH}"
ENV PYTHONPATH="/home/pwuser/.local/lib/python3.12/site-packages:${PYTHONPATH}"

# Install Python dependencies as pwuser (all cached in image)
RUN pip3 install --user --upgrade pip && \
    pip3 install --user torch torchvision torchaudio \
      --index-url https://download.pytorch.org/whl/cpu && \
    pip3 install --user -r /ComfyUI/requirements.txt && \
    pip3 install --user wait-for-it

WORKDIR /app
