# ComfyUI CI container

This image runs ComfyUI frontend Playwright tests without installing the backend and browser dependencies in every CI shard.

## Included software

- Chromium, Firefox, and WebKit from the pinned Playwright image
- Node.js 26 through fnm
- pnpm through Corepack
- zstd for GitHub Actions cache archives
- Python 3.12 and CPU-only PyTorch
- The pinned ComfyUI backend and its Python dependencies at `/ComfyUI`
- `wait-for-it`

## Use the image

Replace `<version>` with a published container version. The container's Playwright version must match the caller's `@playwright/test` version.

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    container:
      image: ghcr.io/comfy-org/comfyui-ci-container:<version>
    strategy:
      matrix:
        shard: [1, 2, 3, 4]
    steps:
      - uses: actions/checkout@v7

      - uses: actions/download-artifact@v8
        with:
          name: frontend-dist
          path: dist

      # Setup - just copy devtools and start server (no clone, no pip install)
      - name: Setup ComfyUI
        run: |
          ln -sf /ComfyUI ./ComfyUI
          cp -r ./tools/devtools/* /ComfyUI/custom_nodes/ComfyUI_devtools/
          cd /ComfyUI
          python3 main.py --cpu --multi-user --front-end-root "$GITHUB_WORKSPACE/dist" &
          wait-for-it --service 127.0.0.1:8188 -t 600

      - name: Install frontend dependencies
        uses: ./.github/actions/setup-frontend

      - name: Run tests
        run: pnpm exec playwright test --shard=${{ matrix.shard }}/4
```

## Build locally

```bash
docker build -t comfyui-test:local .
docker run -it --rm -v "$(pwd):/app" comfyui-test:local bash
docker run --rm comfyui-test:local python3 -c "import torch; print(torch.__version__)"
```
