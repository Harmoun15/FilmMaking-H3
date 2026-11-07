#!/bin/bash

set -e

cd /workspace/ComfyUI

exec /venv/main/bin/python main.py \
    --listen 0.0.0.0 \
    --port 8188
