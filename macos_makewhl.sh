#!/usr/bin/env bash
# macOS 上为 “Linux x86_64 + CPython3.x” 批量下载 .whl（仅二进制），并打成 ZIP
# 执行方式：bash macos_makewhl.sh OR chmod +x macos_makewhl.sh && ./macos_makewhl.sh
set -euo pipefail

# ===== 基本参数（按需修改） ===============================================
PYVER=39             # 3.9->39；3.10->310；3.11->311
CUDA='cu121'         # 'cu118' / 'cu121' / 'cpu'
STAMP="$(date +%Y%m%d%H%M)"
BUNDLE="wheelhouse-py${PYVER}-${CUDA}-${STAMP}"

# ---- 通用依赖（PyPI；锁版本；兼容 Py3.9） --------------------------------
PKGS_BASE=(
  # 科学计算
  'numpy==1.26.4' 'scipy==1.10.1' 'pandas==2.0.3'
  # 可视化/记录
  'matplotlib==3.7.5' 'tensorboard==2.15.2'
  # 常用工具
  'tqdm==4.66.5' 'pyyaml==6.0.1' 'opencv-python-headless==4.9.0.80'
  # torch 常见纯 Python 依赖
  'filelock==3.12.4' 'typing-extensions==4.9.0' 'sympy==1.12'
  'jinja2==3.1.3' 'MarkupSafe==2.1.5' 'fsspec==2024.2.0'
  'pillow==10.2.0' 'networkx==2.8.8'
  # 传递依赖/backport
  'importlib-resources==5.13.0' 'python-dateutil==2.9.0.post0'
  'pytz==2025.2' 'tzdata==2025.2' 'kiwisolver==1.4.7'
  'packaging==25.0' 'pyparsing==3.2.5'
)

# ---- CUDA 运行时组件：cu121 + cuDNN 9 + FFT/Random 等全补齐 ----------------
PKGS_CUDA=()
case "${CUDA}" in
  cu121)
    PKGS_CUDA=(
      'nvidia-cuda-runtime-cu12==12.1.105'
      'nvidia-cuda-nvrtc-cu12==12.1.105'
      'nvidia-cuda-cupti-cu12==12.1.105'
      'nvidia-cublas-cu12==12.1.3.1'
      'nvidia-curand-cu12==10.3.2.106'
      'nvidia-cusolver-cu12==11.4.5.107'
      'nvidia-cusparse-cu12==12.1.0.106'
      'nvidia-cufft-cu12==11.0.2.54'
      'nvidia-nvtx-cu12==12.1.105'
      'nvidia-nvjitlink-cu12==12.9.86'
      'nvidia-cudnn-cu12==9.1.0.70'
      'nvidia-nccl-cu12==2.22.3'
    )
    ;;
  cu118)
    echo "[WARN] 选择了 cu118；未锁定 cu11 组件版本。如必须 cu118，请另告诉我以匹配版本集合。" >&2
    ;;
  cpu) : ;;  # CPU 套餐无需这些
  *)   echo "[WARN] 未知 CUDA 选项：${CUDA}；仅内置 cu121/cpu。" >&2 ;;
esac

# ---- PyTorch 三件套（与 CUDA 对齐：2.4.1 / 0.19.1 / 2.4.1） ---------------
TORCH_TRIPLE=('torch==2.4.1' 'torchvision==0.19.1' 'torchaudio==2.4.1')
TORCH_INDEX=''
case "${CUDA}" in
  cpu)   TORCH_INDEX='https://download.pytorch.org/whl/cpu' ;;
  cu118) TORCH_INDEX='https://download.pytorch.org/whl/cu118' ;;
  cu121) TORCH_INDEX='https://download.pytorch.org/whl/cu121' ;;
esac

# ===== 开始 ================================================================
python3 -m pip install -U pip >/dev/null
mkdir -p "${BUNDLE}/wheelhouse"

# 1A) 通用依赖（manylinux2014；指定 cp/abi 保证 Py3.9 ABI）
python3 -m pip download \
  -d "${BUNDLE}/wheelhouse" \
  --only-binary=:all: \
  --platform manylinux2014_x86_64 \
  --python-version "${PYVER}" \
  --implementation cp \
  --abi "cp${PYVER}" \
  "${PKGS_BASE[@]}"

# 1B) CUDA 组件（manylinux2014；**不要**加 --abi/--implementation，避免过滤掉 py3-none-manylinux 轮子）
if [ "${#PKGS_CUDA[@]}" -gt 0 ]; then
  python3 -m pip download \
    -d "${BUNDLE}/wheelhouse" \
    --only-binary=:all: \
    --platform manylinux2014_x86_64 \
    "${PKGS_CUDA[@]}"
fi

# 2) PyTorch 三件套（官方索引；linux_x86_64；--no-deps）
python3 -m pip download \
  -d "${BUNDLE}/wheelhouse" \
  --only-binary=:all: \
  --platform linux_x86_64 \
  --python-version "${PYVER}" \
  --implementation cp \
  --abi "cp${PYVER}" \
  --no-deps \
  --index-url "${TORCH_INDEX}" \
  --extra-index-url "https://pypi.org/simple" \
  "${TORCH_TRIPLE[@]}"

# 3) 打包（zip）
zip -rq "${BUNDLE}.zip" "${BUNDLE}"

# 4) 摘要
WHL_COUNT=$(find "${BUNDLE}/wheelhouse" -type f -name '*.whl' | wc -l | tr -d ' ')
echo "✅ 完成：${BUNDLE}.zip（收集 ${WHL_COUNT} 个 .whl）"
echo "上传后在服务器解压，用：pip install --no-index --find-links <wheelhouse> ... 进行离线安装。"
