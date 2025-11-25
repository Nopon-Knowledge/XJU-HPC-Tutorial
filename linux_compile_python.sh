#!/usr/bin/env bash
set -euo pipefail

# ===== 可改参数 =====
PYVER=3.13.9                            # 改为你要安装的目录名
SRCDIR="Python-$PYVER"                  # 官方解包目录名,不用管
BASE="$HOME/library/python"             # 改为源码包目录，只要写到源码包所在目录即可！不用将源码包文件也写进去！（不以 / 结尾）
PREFIX="$BASE/$PYVER"                   # 安装到这里，不用管
WORK="$BASE/src"                        # 解包与编译目录，不用管
LOGDIR="$BASE/build-logs"               # 日志目录，不用管
JOBS="${JOBS:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || nproc 2>/dev/null || echo 1)}"

mkdir -p "$WORK" "$PREFIX" "$LOGDIR"
LOG="$LOGDIR/build-$PYVER-$(date +%Y%m%d%H%M%S).log"

# 1) 选压缩包：优先 .tgz；没有再用 .tar.xz
TARBALL=""
if [ -f "$BASE/Python-$PYVER.tgz" ]; then
  TARBALL="$BASE/Python-$PYVER.tgz"
elif [ -f "$BASE/Python-$PYVER.tar.xz" ]; then
  TARBALL="$BASE/Python-$PYVER.tar.xz"
fi
if [ -z "$TARBALL" ]; then
  echo "[ERR] 没找到压缩包：$BASE/Python-$PYVER.tgz 或 $BASE/Python-$PYVER.tar.xz"
  exit 2
fi
echo "[INFO] Using tarball: $TARBALL" | tee -a "$LOG"

# 2) 解包（不用管道探测；错了就明确报）
echo "[INFO] Extract -> $WORK" | tee -a "$LOG"
rm -rf "$WORK/$SRCDIR"
case "$TARBALL" in
  *.tgz|*.tar.gz)
    tar -xzf "$TARBALL" -C "$WORK"
    ;;
  *.tar.xz)
    command -v xz >/dev/null 2>&1 || { echo "[ERR] 没有 xz，请改用 .tgz 包"; exit 3; }
    TMPTAR="$WORK/$SRCDIR.tar"
    rm -f "$TMPTAR"
    xz -dc "$TARBALL" > "$TMPTAR"
    tar -xf "$TMPTAR" -C "$WORK"
    rm -f "$TMPTAR"
    ;;
  *)
    echo "[ERR] 未知压缩格式：$TARBALL" ; exit 4;;
esac

# 3) 进入源码目录（用固定名校验）
if [ ! -d "$WORK/$SRCDIR" ]; then
  echo "[ERR] 解包后未找到目录：$WORK/$SRCDIR"
  echo "       当前 WORK 下有这些："
  ls -la "$WORK"
  exit 5
fi

# 4) 配置 / 构建 / 安装 —— 整段统一重定向到 tee
(
  set -e
  cd "$WORK/$SRCDIR"
  echo "[INFO] Configure..."
  ./configure \
    --prefix="$PREFIX" \
    --with-ensurepip=install
  # 如需开启 PGO/LTO 优化：把上一行末尾加上反斜杠 \ ，并取消下一行注释
  #   --enable-optimizations

  echo "[INFO] Build with $JOBS jobs..."
  make -j"$JOBS"

  echo "[INFO] Altinstall..."
  make altinstall
) 2>&1 | tee -a "$LOG"

# 5) 校验
if [ -x "$PREFIX/bin/python3.13" ]; then
  "$PREFIX/bin/python3.13" -V     | tee -a "$LOG"
  "$PREFIX/bin/pip3.13" --version | tee -a "$LOG"
  echo "[OK] Installed into $PREFIX"
  echo "export PATH=\"$PREFIX/bin:\$PATH\""
else
  echo "[ERR] $PREFIX/bin/python3.13 不存在" | tee -a "$LOG"
  CFGLOG="$WORK/$SRCDIR/config.log"
  [ -f "$CFGLOG" ] && { echo "---- tail config.log ----" | tee -a "$LOG"; tail -n 60 "$CFGLOG" | tee -a "$LOG"; }
  echo "---- tail build log ----"; tail -n 60 "$LOG"
  exit 6
fi
