<# Windows/PowerShell 上为“Linux x86_64 + CPython3.9”准备离线 .whl，并打成 zip #>

# ===== 基本参数（按需修改） ===============================================
$PYVER  = 39            # 3.9 -> 39；若服务器是 3.10 就改 310，3.11 改 311
$CUDA   = 'cu121'       # 'cu118' / 'cu121' / 'cpu'
$STAMP  = Get-Date -Format 'yyyyMMddHHmm'
$BUNDLE = "wheelhouse-py$PYVER-$CUDA-$STAMP"

# ---- 通用依赖（PyPI；manylinux 轮子）。全部锁版本且兼容 Py3.9 -------------
$PKGS_BASE = @(
  # 基础科学计算
  'numpy==1.26.4',
  'scipy==1.10.1',
  'pandas==2.0.3',

  # 可视化 / 记录
  'matplotlib==3.7.5',
  'tensorboard==2.15.2',

  # 常用工具
  'tqdm==4.66.5',
  'pyyaml==6.0.1',
  'opencv-python-headless==4.9.0.80',

  # ---- torch 的纯 Python 依赖（避免 torch 在 Windows 下解析到 Win-only 依赖）----
  'filelock==3.12.4',
  'typing-extensions==4.9.0',
  'sympy==1.12',
  'jinja2==3.1.3',
  'MarkupSafe==2.1.5',
  'fsspec==2024.2.0',
  'pillow==10.2.0',
  'networkx==2.8.8',

  # ---- Py3.9 的 backport 及常见传递依赖（matplotlib 等会用到）
  'importlib-resources==5.13.0',
  'python-dateutil==2.9.0.post0',
  'pytz==2025.2',
  'tzdata==2025.2',
  'kiwisolver==1.4.7',
  'packaging==25.0',
  'pyparsing==3.2.5'
)

# ---- CUDA 运行时组件（按 $CUDA 选择；这里内置 cu121 版本） -------------------
$PKGS_CUDA = @()
switch ($CUDA) {
  'cu121' {
    $PKGS_CUDA = @(
      'nvidia-cuda-runtime-cu12==12.1.105',
      'nvidia-cuda-nvrtc-cu12==12.1.105',
      'nvidia-cuda-cupti-cu12==12.1.105',
      'nvidia-cublas-cu12==12.1.3.1',
      'nvidia-cudnn-cu12==9.1.0.70',
      'nvidia-cusolver-cu12==11.4.5.107',
      'nvidia-cusparse-cu12==12.1.0.106',
      'nvidia-nvtx-cu12==12.1.105'，
      'nvidia-curand-cu12',   # 如需固定版本，可用示例：==10.3.2.106
      'nvidia-nccl-cu12==2.22.3',     # 如需固定版本，可用示例：==2.20.5
      'nvidia-cufft-cu12==11.0.2.54',
      'nvidia-nvjitlink-cu12==12.9.86'
    )
  }
  'cpu'   { $PKGS_CUDA = @() }
  'cu118' {
    Write-Warning "你将使用 cu118，但本脚本未固定 cu11 组件的精确版本。建议继续用 cu121；若必须 cu118，请告诉我，我给你匹配的 nvidia-* 版本集合。"
    $PKGS_CUDA = @()  # 先留空，避免错误装错版本
  }
  default {
    Write-Warning "未知 CUDA 选项：$CUDA。仅内置 cu121/cpu。"
  }
}

# ---- PyTorch 三件套（与 CUDA 对应；以下适配 torch==2.3.1） -------------------
$TORCH_TRIPLE = @(
  'torch==2.3.1',
  'torchvision==0.18.1',
  'torchaudio==2.3.1'
)

# ---- 官方索引（按 CUDA 套餐切换） -----------------------------------------
$TORCH_INDEX = @{
  'cpu'   = 'https://download.pytorch.org/whl/cpu'
  'cu118' = 'https://download.pytorch.org/whl/cu118'
  'cu121' = 'https://download.pytorch.org/whl/cu121'
}[$CUDA]

# ===== 开始 ================================================================
python -m pip install -U pip | Out-Null

New-Item -ItemType Directory $BUNDLE -Force              | Out-Null
New-Item -ItemType Directory "$BUNDLE/wheelhouse" -Force | Out-Null

# 1) 先下通用依赖（含 backport 与 nvidia-* 组件）→ PyPI；manylinux 平台标签
#    关键：--platform manylinux2014_x86_64（PyPI 上常见的 Linux 轮子标签）
$PKGS_ALL = $PKGS_BASE + $PKGS_CUDA
if ($PKGS_ALL.Count -gt 0) {
  $ARGS_COMMON = @(
    '-m','pip','download',
    '-d',"$BUNDLE/wheelhouse",
    '--only-binary',':all:',
    '--platform','manylinux2014_x86_64',
    '--python-version',"$PYVER",
    '--implementation','cp',
    '--abi',"cp$PYVER"
  ) + $PKGS_ALL
  & python @ARGS_COMMON
}

# 2) 再下 torch 三件套（官方 CUDA/CPU 索引；linux_x86_64；且 --no-deps）
#    避免在 Windows 上解析到 mkl(Windows) 等依赖；依赖我们已在 $PKGS_ALL 里补齐。
$ARGS_TORCH = @(
  '-m','pip','download',
  '-d',"$BUNDLE/wheelhouse",
  '--only-binary',':all:',
  '--platform','linux_x86_64',
  '--python-version',"$PYVER",
  '--implementation','cp',
  '--abi',"cp$PYVER",
  '--no-deps',
  '--index-url',"$TORCH_INDEX",
  '--extra-index-url','https://pypi.org/simple'
) + $TORCH_TRIPLE
& python @ARGS_TORCH

# 3) 打包
Compress-Archive -Path $BUNDLE -DestinationPath "$BUNDLE.zip" -Force

# 4) 摘要
$N = (Get-ChildItem "$BUNDLE/wheelhouse" -Filter *.whl | Measure-Object).Count
Write-Host "✅ 完成：$BUNDLE.zip（收集 $N 个 .whl）"
Write-Host "上传 $BUNDLE.zip 到服务器后，解压并用 --no-index --find-links 离线安装。"
