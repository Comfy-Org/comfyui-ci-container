---
name: updating-ci-container
description: Updates the ComfyUI CI container's pinned ComfyUI, Playwright, or Node.js versions. Use when preparing and coordinating container releases with ComfyUI_frontend.
---

# Update the CI container

Publish the container before changing ComfyUI_frontend to consume it.

1. Read the current pins in `Dockerfile` and the publishing flow in `.github/workflows/build-and-push.yml`.
2. Verify the requested version against its official release source. For Playwright, confirm that the matching `mcr.microsoft.com/playwright:v<version>-noble` tag exists.
3. Update only the relevant `Dockerfile` pin and factual README references.
4. Run `docker buildx build --check .` and inspect the changed image manifest.
5. Open the container PR against `main`.

After the container PR merges, the main workflow creates a version tag, publishes the image, and opens a ComfyUI_frontend PR. Do not update the frontend image references before that image exists.

For a Playwright update, amend the generated frontend PR so its `@playwright/test` catalog version matches the Playwright version in the container. Playwright requires exact package and browser-image versions.
