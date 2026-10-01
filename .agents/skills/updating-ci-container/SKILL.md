---
name: updating-ci-container
description: Updates the ComfyUI CI container's pinned ComfyUI, Playwright, or Node.js versions. Use when preparing and coordinating container releases with ComfyUI_frontend.
---

# Update the CI container

Publish the container before changing ComfyUI_frontend to consume it.

## Update Playwright

Run `gh workflow run update-playwright.yml` to update to the latest stable release. Pass `-f version=1.63.0` to request a specific version. The workflow verifies the Microsoft image, validates the Dockerfile, and opens the container PR.

## Update ComfyUI or Node.js

1. Read the current pins in `Dockerfile` and `.github/workflows/build-and-push.yml`.
2. Verify the requested version against its official release source.
3. Update only the relevant `Dockerfile` pin and factual README references.
4. Run `docker buildx build --check .`.
5. Open the container PR against `main`.

After the container PR merges, the main workflow creates a version tag and publishes the image. After the image is published, run `gh workflow run ci-update-comfyui-container.yaml -R Comfy-Org/ComfyUI_frontend` to open the frontend PR. It uses the newest release by default; pass `-f version=0.0.25` to select a specific published version. The workflow fails if the image is not published yet, so do not run it before the release workflow finishes.

When the container changes Playwright, the frontend PR also updates the Playwright images and the `@playwright/test` catalog version and lockfile to match. Playwright requires exact package and browser-image versions. Push any type or screenshot fixes to that PR; the workflow does not overwrite an existing PR.
