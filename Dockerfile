FROM vastai/pytorch:2.6.0-cuda-12.6.3-py312

USER root

# Outils système
RUN apt-get update && \
    apt-get install -y \
    git \
    curl \
    wget \
    ffmpeg \
    ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Installation de ComfyUI
WORKDIR /opt/workspace-internal

RUN git clone \
    https://github.com/Comfy-Org/ComfyUI.git

WORKDIR /opt/workspace-internal/ComfyUI

# Dépendances Python
RUN /venv/main/bin/python -m pip install \
    -r requirements.txt

# ComfyUI Manager
RUN git clone \
    https://github.com/ltdrdata/ComfyUI-Manager.git \
    custom_nodes/ComfyUI-Manager

# Noeuds complémentaires
RUN git clone \
    https://github.com/kijai/ComfyUI-KJNodes.git \
    custom_nodes/ComfyUI-KJNodes

RUN git clone \
    https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git \
    custom_nodes/ComfyUI-VideoHelperSuite

# Dépendances des noeuds
RUN for dir in custom_nodes/*; do \
      if [ -f "$dir/requirements.txt" ]; then \
        /venv/main/bin/python -m pip install \
          -r "$dir/requirements.txt"; \
      fi; \
    done

# Stockage des modèles hors workspace
RUN mkdir -p \
    /models/diffusion_models \
    /models/text_encoders \
    /models/vae \
    /models/loras \
    /models/model_patches

# Relier les dossiers de modèles
RUN for folder in diffusion_models text_encoders \
    vae loras model_patches; do \
      rm -rf "models/$folder"; \
      ln -s "/models/$folder" "models/$folder"; \
    done

# Télécharger uniquement les modèles sélectionnés
ARG HF_BASE=https://huggingface.co/Comfy-Org/MiniMax-H3/resolve/main

# MiniMax H3
RUN curl -fL --retry 5 \
    "$HF_BASE/diffusion_models/minimax_h3_ref2va_pruned_int8_convrot.safetensors" \
    -o /models/diffusion_models/minimax_h3_ref2va_pruned_int8_convrot.safetensors

# Encodeur Qwen3-VL
RUN curl -fL --retry 5 \
    "$HF_BASE/text_encoders/qwen3vl_32b_minimax_h3_nvfp4_awq.safetensors" \
    -o /models/text_encoders/qwen3vl_32b_minimax_h3_nvfp4_awq.safetensors

# Video VAE
RUN curl -fL --retry 5 \
    "$HF_BASE/vae/minimax_h3_video_vae_fp16.safetensors" \
    -o /models/vae/minimax_h3_video_vae_fp16.safetensors

# Audio VAE
RUN curl -fL --retry 5 \
    "$HF_BASE/vae/minimax_h3_audio_vae_fp32.safetensors" \
    -o /models/vae/minimax_h3_audio_vae_fp32.safetensors

# ControlNet pour vidéos Blender
RUN curl -fL --retry 5 \
    "$HF_BASE/model_patches/minimax_h3_fun_controlnet_union_2.0_pruned_int8_convrot.safetensors" \
    -o /models/model_patches/minimax_h3_fun_controlnet_union_2.0_pruned_int8_convrot.safetensors

# Turbo LoRA
RUN curl -fL --retry 5 \
    "https://huggingface.co/drbaph/MiniMax-H3-Turbo-Lora-ComfyUI/resolve/main/minimax_h3_turbo_v4_step600_ema_pruned_comfyui.safetensors" \
    -o /models/loras/minimax_h3_turbo_v4_step600_ema_pruned_comfyui.safetensors

# Copier les workflows
RUN mkdir -p user/default/workflows

COPY workflows/ user/default/workflows/

# Script de démarrage
COPY scripts/start.sh /usr/local/bin/blender2video-start.sh

RUN chmod +x /usr/local/bin/blender2video-start.sh

EXPOSE 8188

CMD ["/usr/local/bin/blender2video-start.sh"]
