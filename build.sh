#!/usr/bin/env bash
# Nanbu Linux ISO 构建脚本 —— 在 Arch 系统内以 root 运行。
# 用法: sudo ./build.sh [输出目录]
set -euo pipefail

RELENG=/usr/share/archiso/configs/releng
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${1:-$HERE/out}"
WORK=/tmp/nanbu-archiso-work

die() { echo "ERROR: $*" >&2; exit 1; }

[[ $EUID -eq 0 ]] || die "请用 root 运行（sudo ./build.sh）"

# archiso 只能在 Arch 系统中运行；Ubuntu 需要先进入 Arch 虚拟机。
[[ -r /etc/os-release ]] || die "找不到 /etc/os-release，无法确认当前发行版"
. /etc/os-release
case " ${ID:-} ${ID_LIKE:-} " in
  *" arch "*) ;;
  *) die "当前系统不是 Arch Linux。请在 VirtualBox 的 Arch Linux 虚拟机内运行此脚本；Ubuntu 仅用于承载该虚拟机" ;;
esac

# 检测共享目录 (vboxsf/9p/nfs)：不支持符号链接，也记不对 root 所有权
_linktest="$HERE/.nanbu-linktest"; rm -f "$_linktest"
if ! ln -s /etc/os-release "$_linktest" 2>/dev/null; then
  rm -f "$_linktest"
  die "目录 $HERE 的文件系统不支持符号链接（典型：VBox 共享目录 vboxsf）。请复制到本地磁盘再构建：\n\
    sudo cp -a \"$HERE\" /root/nanbu-linux\n\
    cd /root/nanbu-linux && sudo ./build.sh"
fi
rm -f "$_linktest"

[[ -d "$RELENG" ]] || die "找不到 archiso 的 releng 配置：$RELENG（先 pacman -S archiso）"

# --- 依赖（缺了就装）---
pacman -Sy --noconfirm --needed \
  archiso archinstall grub syslinux squashfs-tools \
  edk2-ovmf mtools dosfstools libisoburn 2>/dev/null || true
for c in mkarchiso pacman; do
  command -v "$c" >/dev/null 2>&1 || die "缺少命令 '$c'（请先装对应包）"
done

# --- 1. 以 releng 为底座 ---
rm -rf "$HERE/profile" "$WORK" 2>/dev/null || true
cp -a "$RELENG" "$HERE/profile"

# --- 2. 追加包列表（不替换，保留 releng 基础包 + 网络 + 内核） ---
cat "$HERE/overlay/packages.append" >> "$HERE/profile/packages.x86_64"

# 兼容旧版 archiso releng 配置：这些包已不在官方仓库中。
# 放在所有包列表追加完成后执行，避免旧包从 overlay 或旧 releng 再次混入。
PACKAGE_LIST="$HERE/profile/packages.x86_64"
sed -i -E \
  '/^[[:space:]]*(xf86-video-vmware|calamares)([[:space:]]|#|$)/d' \
  "$PACKAGE_LIST"

if grep -nE '^[[:space:]]*(xf86-video-vmware|calamares)([[:space:]]|#|$)' "$PACKAGE_LIST"; then
  die "包列表仍包含已移除的包，请检查 $PACKAGE_LIST"
fi

# --- 3. 覆盖 ISO 元数据 / 引导模式 ---
install -m644 "$HERE/overlay/profiledef.sh" "$HERE/profile/profiledef.sh"

# --- 4. 追加（而非替换）releng 的 customize_airootfs.sh，保留其网络/镜像配置 ---
CUST="$HERE/profile/airootfs/root/customize_airootfs.sh"
printf '\n### Nanbu Linux 追加配置 ###\n' >> "$CUST"
cat "$HERE/overlay/customize.append.sh" >> "$CUST"

# --- 5. 叠加 airootfs 定制（locale/hostname 等） ---
cp -a "$HERE/overlay/airootfs/." "$HERE/profile/airootfs/"

# --- 6. 构建 ---
echo ">> 构建脚本目录: $HERE"
echo ">> 使用包清单: $PACKAGE_LIST"
echo ">> 开始构建，输出目录: $OUT"
mkdir -p "$OUT"
mkarchiso -v -w "$WORK" -o "$OUT" "$HERE/profile"
echo ">> 完成: $(ls -1 "$OUT"/*.iso 2>/dev/null || true)"