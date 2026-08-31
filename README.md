# ComfyUI Test Action

A Docker container image pre-configured for running Playwright E2E tests against ComfyUI.

## What's Included

- Playwright browsers (Chromium, Firefox, WebKit)
- Node.js via fnm — follows the caller's `.nvmrc` (Node 25 pre-installed; override at runtime with `fnm use --install-if-missing`)
- pnpm via Corepack — follows the caller's `packageManager` field
- zstd for GitHub Actions cache archives
- Python 3 + pip
- ComfyUI backend (pinned version) at `/ComfyUI`
- All Python dependencies pre-installed (torch CPU, requirements.txt, wait-for-it)

## Usage

Use this image as a container in your GitHub Actions workflow:

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    container:
      image: ghcr.io/comfy-org/comfyui-ci-container:v1
    strategy:
      matrix:
        shard: [1, 2, 3, 4]
    steps:
      - uses: actions/checkout@v5

      - uses: actions/download-artifact@v4
        with:
          name: frontend-dist
          path: dist

      # Setup - just copy devtools and start server (no clone, no pip install)
      - name: Setup ComfyUI
        run: |
          ln -sf /ComfyUI ./ComfyUI
          cp -r ./tools/devtools/* /ComfyUI/custom_nodes/ComfyUI_devtools/
          cd /ComfyUI && python3 main.py --cpu --multi-user --front-end-root $GITHUB_WORKSPACE/dist &
          wait-for-it --service 127.0.0.1:8188 -t 600

      - name: Install frontend deps
        run: pnpm install

      - name: Run tests
        run: pnpm exec playwright test --shard=${{ matrix.shard }}/4
```

## Image Tags

- `ghcr.io/comfy-org/comfyui-ci-container:latest` - Latest build
- `ghcr.io/comfy-org/comfyui-ci-container:0.0.3` - Stable v0.0.3
- `ghcr.io/comfy-org/comfyui-ci-container:comfyui-v0.5.1` - Specific ComfyUI version

## Time Savings

| Step | Before | After |
|------|--------|-------|
| Clone ComfyUI | ~10s | 0s |
| pip install | ~90s | 0s |
| Setup Playwright | ~30s | 0s |
| **Total saved** | **~130s** | **per shard** |

## Local Development

```bash
# Build the image
docker build -t comfyui-test:local .

# Run interactively
docker run -it --rm -v $(pwd):/app comfyui-test:local bash

# Test ComfyUI is installed
docker run --rm comfyui-test:local python3 -c "import torch; print(torch.__version__)"
```

## Updating ComfyUI Version

1. Update `COMFYUI_VERSION` in Dockerfile
2. Push to trigger rebuild
3. Tag with new version
