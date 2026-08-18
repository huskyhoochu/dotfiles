# OpenRouter 전용 미디어 노드 — Seedream(이미지) · Seedance(비디오)
#
# build.sh 가 /opt/comfyui/custom_nodes/openrouter_media/ 로 배포한다.
#
# 존재 이유: OpenRouter 의 이미지·비디오 생성은 챗 완성이 아니라 전용 엔드포인트
# (POST /api/v1/images, POST /api/v1/videos + 폴링)를 쓴다. 커뮤니티 노드
# (ComfyUI-Openrouter_node)는 챗 완성 전용이라 ByteDance Seedream/Seedance 를
# 못 부른다 (2026-08-18 실측 — /api/v1/models 목록에 이미지·비디오 모델이 없다).
#
# API 키는 systemd 유닛의 EnvironmentFile(/etc/comfyui.env)이 주입하는 LLM_KEY 를
# 재사용한다. 의존성은 ComfyUI 보장분(torch·numpy·PIL)과 표준 라이브러리뿐이다.

import base64
import io as _io
import json
import os
import time
import urllib.error
import urllib.request

import numpy as np
import torch
from PIL import Image

API_BASE = "https://openrouter.ai/api/v1"

# 모델 목록은 2026-08-18 의 /api/v1/images/models · /api/v1/videos/models 실측이다.
# 새 모델은 model_override 로 바로 쓸 수 있고, 목록 갱신은 이 파일 수정으로 한다.
IMAGE_MODELS = [
    "bytedance-seed/seedream-5-0-pro",   # 2026-08-12
    "bytedance-seed/seedream-5-0-lite",  # 2026-08-13
    "bytedance-seed/seedream-4.5",
]
VIDEO_MODELS = [
    "bytedance/seedance-2.5",            # 최신 — 최대 30초. 4초 720p $0.92 실측 (초당 약 $0.23)
    "bytedance/seedance-2.0",
    "bytedance/seedance-2.0-fast",
    "bytedance/seedance-2.0-mini",       # 최저가 — 시험용으로 이것부터
]
ASPECT_RATIOS = ["1:1", "16:9", "9:16", "4:3", "3:4", "3:2", "2:3"]


def _key():
    key = os.environ.get("LLM_KEY") or os.environ.get("OPENROUTER_API_KEY")
    if not key:
        raise RuntimeError("LLM_KEY not set — see /etc/comfyui.env (env.example)")
    return key


def _request(method, url, payload=None, auth=True):
    headers = {"Content-Type": "application/json"} if payload is not None else {}
    if auth:
        headers["Authorization"] = "Bearer " + _key()
    data = json.dumps(payload).encode() if payload is not None else None
    req = urllib.request.Request(url, data, headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=300) as r:
            return r.read()
    except urllib.error.HTTPError as e:
        raise RuntimeError(f"OpenRouter {e.code}: {e.read().decode(errors='replace')[:500]}")


class OpenRouterSeedreamImage:
    """POST /api/v1/images — 동기, base64 응답."""

    CATEGORY = "OpenRouter"
    RETURN_TYPES = ("IMAGE",)
    FUNCTION = "generate"

    @classmethod
    def INPUT_TYPES(cls):
        return {
            "required": {
                "prompt": ("STRING", {"multiline": True, "default": ""}),
                "model": (IMAGE_MODELS,),
                # seedream 5.0 제공자는 1K 를 거부한다 (2026-08-18 실측: "Accepted: 2K, 4K")
                "resolution": (["2K", "4K"], {"default": "2K"}),
                "aspect_ratio": (ASPECT_RATIOS, {"default": "1:1"}),
                "seed": ("INT", {"default": 0, "min": 0, "max": 2**31 - 1}),
            },
            "optional": {
                # 목록에 없는 신모델을 즉시 쓰기 위한 통로 (예: 차기 seedream)
                "model_override": ("STRING", {"default": ""}),
            },
        }

    def generate(self, prompt, model, resolution, aspect_ratio, seed, model_override=""):
        payload = {
            "model": model_override or model,
            "prompt": prompt,
            "resolution": resolution,
            "aspect_ratio": aspect_ratio,
        }
        if seed:
            payload["seed"] = seed
        body = json.loads(_request("POST", API_BASE + "/images", payload))
        images = []
        for d in body["data"]:
            im = Image.open(_io.BytesIO(base64.b64decode(d["b64_json"]))).convert("RGB")
            images.append(torch.from_numpy(np.asarray(im).astype(np.float32) / 255.0))
        if not images:
            raise RuntimeError(f"no image in response: {str(body)[:300]}")
        return (torch.stack(images),)


class OpenRouterSeedanceVideo:
    """POST /api/v1/videos — 잡 제출 → 폴링 → URL 다운로드."""

    CATEGORY = "OpenRouter"
    RETURN_TYPES = ("VIDEO",)
    FUNCTION = "generate"

    @classmethod
    def INPUT_TYPES(cls):
        return {
            "required": {
                "prompt": ("STRING", {"multiline": True, "default": ""}),
                "model": (VIDEO_MODELS,),
                "duration": ("INT", {"default": 5, "min": 2, "max": 30, "tooltip": "초 단위. 30초는 seedance-2.5 만"}),
                "resolution": (["720p", "1080p"], {"default": "720p"}),
                "aspect_ratio": (ASPECT_RATIOS, {"default": "16:9"}),
                "seed": ("INT", {"default": 0, "min": 0, "max": 2**31 - 1}),
                "poll_timeout": ("INT", {"default": 900, "min": 60, "max": 3600, "tooltip": "생성 대기 상한(초)"}),
            },
            "optional": {
                "model_override": ("STRING", {"default": ""}),
            },
        }

    def generate(self, prompt, model, duration, resolution, aspect_ratio, seed,
                 poll_timeout, model_override=""):
        payload = {
            "model": model_override or model,
            "prompt": prompt,
            "duration": duration,
            "resolution": resolution,
            "aspect_ratio": aspect_ratio,
        }
        if seed:
            payload["seed"] = seed
        sub = json.loads(_request("POST", API_BASE + "/videos", payload))
        job_id = sub["id"]

        deadline = time.time() + poll_timeout
        status = sub.get("status", "pending")
        st = sub
        while time.time() < deadline and status not in ("completed", "failed"):
            time.sleep(10)
            st = json.loads(_request("GET", f"{API_BASE}/videos/{job_id}"))
            status = st.get("status")
        if status == "failed":
            raise RuntimeError(f"video job failed: {str(st)[:500]}")
        if status != "completed":
            raise RuntimeError(f"video job timed out after {poll_timeout}s (id={job_id})")

        # unsigned_urls 는 이름과 달리 인증이 필요하다 (2026-08-18 실측: 무인증은
        # 401 "No cookie auth credentials found"). 항상 Bearer 를 붙인다.
        urls = st.get("unsigned_urls") or [f"{API_BASE}/videos/{job_id}/content?index=0"]
        data = _request("GET", urls[0])

        import folder_paths
        out_path = os.path.join(folder_paths.get_output_directory(), f"seedance_{job_id}.mp4")
        with open(out_path, "wb") as f:
            f.write(data)

        try:
            from comfy_api.latest import InputImpl
            video_from_file = InputImpl.VideoFromFile
        except (ImportError, AttributeError):
            from comfy_api.input_impl import VideoFromFile as video_from_file
        return (video_from_file(out_path),)


NODE_CLASS_MAPPINGS = {
    "OpenRouterSeedreamImage": OpenRouterSeedreamImage,
    "OpenRouterSeedanceVideo": OpenRouterSeedanceVideo,
}
NODE_DISPLAY_NAME_MAPPINGS = {
    "OpenRouterSeedreamImage": "Seedream Image (OpenRouter)",
    "OpenRouterSeedanceVideo": "Seedance Video (OpenRouter)",
}
