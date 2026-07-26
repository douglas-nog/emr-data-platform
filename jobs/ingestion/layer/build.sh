#!/usr/bin/env bash
#
# Builds the Lambda layer inside the official Lambda runtime image so the
# artifact matches the deployment target (Python 3.11, arm64), regardless of
# the host architecture. Produces layer.zip for Terraform to publish.
#
# Layer zip layout must place packages under python/ — that is where the Lambda
# runtime adds them to sys.path.

set -euo pipefail

LAYER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${LAYER_DIR}/build"
OUTPUT="${LAYER_DIR}/layer.zip"

PYTHON_VERSION="3.11"
PLATFORM="linux/arm64"
IMAGE="public.ecr.aws/lambda/python:${PYTHON_VERSION}"

echo "Cleaning previous build..."
rm -rf "${BUILD_DIR}" "${OUTPUT}"
mkdir -p "${BUILD_DIR}/python"

echo "Installing dependencies in ${IMAGE} (${PLATFORM})..."
docker run --rm --platform "${PLATFORM}" \
  --entrypoint /bin/bash \
  -v "${LAYER_DIR}/requirements.txt:/tmp/requirements.txt:ro" \
  -v "${BUILD_DIR}/python:/tmp/python" \
  "${IMAGE}" \
  -c "pip install --no-cache-dir -r /tmp/requirements.txt -t /tmp/python && \
      find /tmp/python -type d -name '__pycache__' -exec rm -rf {} + 2>/dev/null || true"

echo "Zipping layer..."
cd "${BUILD_DIR}"
zip -qr "${OUTPUT}" python
cd - > /dev/null

rm -rf "${BUILD_DIR}"
echo "Layer built: ${OUTPUT}"