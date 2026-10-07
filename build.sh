#!/usr/bin/env bash
# Nanbu Linux ISO 构建脚本 —— 在 Arch Linux 内以 root 运行。
# 用法: sudo ./build.sh [输出目录]
set -euo pipefail

RELENG=/usr/share/archiso/configs/releng
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${1:-$HERE/out}"
BUILD_DIR=""

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

cleanup() {
  if [[ -n "$BUILD_DIR" && -d "$BUILD_DIR" ]]; then
    rm -rf -- "$BUILD_DIR"
  fi
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

[[ -r /etc/os-release ]] || die "找不到 /etc/os-release，无法确认当前发行版"
. /etc/os-release
[[ ${ID:-} == arch ]] || die "请在官方 Arch Linux 构建虚拟机中运行；当前宿主系统不是 Arch Linux"
[[ $(uname -m) == x86_64 ]] || die "此安装介质只支持 x86_64 构建机和虚拟机"
[[ $EUID -eq 0 ]] || die "请用 root 运行（sudo ./build.sh）"
(($# <= 1)) || die "用法：sudo ./build.sh [输出目录]"

for command in mkarchiso pacman pacman-conf findmnt; do
  command -v "$command" >/dev/null 2>&1 \
    || die "缺少 $command；请先运行 pacman -Syu --needed archiso"
done
[[ -d "$RELENG" ]] || die "找不到 releng 配置：$RELENG（请安装 archiso）"

filesystem="$(findmnt -n -o FSTYPE -T "$HERE")"
case "$filesystem" in
  vboxsf|9p|nfs|nfs4|cifs)
    die "请将项目复制到虚拟机的本地 Linux 文件系统，不要在 $filesystem 共享目录下构建" ;;
esac

missing_packages=()
for package in archiso grub syslinux squashfs-tools edk2-ovmf mtools dosfstools libisoburn; do
  if ! pacman -Q "$package" >/dev/null 2>&1; then
    missing_packages+=("$package")
  fi
done
if ((${#missing_packages[@]})); then
  die "缺少构建依赖：${missing_packages[*]}。请运行 pacman -Syu --needed ${missing_packages[*]}"
fi

for file in packages.append profiledef.sh customize.append.sh; do
  [[ -f "$HERE/overlay/$file" ]] || die "缺少 overlay/$file"
done
[[ -d "$HERE/overlay/airootfs" ]] || die "缺少 overlay/airootfs"

# /tmp 常为小容量 tmpfs；默认用磁盘上的 /var/tmp，避免挤占虚拟机内存。
BUILD_DIR="$(mktemp -d "${TMPDIR:-/var/tmp}/nanbu-archiso.XXXXXX")"
filesystem="$(findmnt -n -o FSTYPE -T "$BUILD_DIR")"
case "$filesystem" in
  vboxsf|9p|nfs|nfs4|cifs) die "临时构建目录也必须位于本地 Linux 文件系统" ;;
esac
PROFILE="$BUILD_DIR/profile"
WORK="$BUILD_DIR/work"
cp -a "$RELENG" "$PROFILE"

PACKAGE_LIST="$PROFILE/packages.x86_64"
[[ -f "$PACKAGE_LIST" ]] || die "releng 配置缺少 packages.x86_64"
printf '\n' >> "$PACKAGE_LIST"
cat "$HERE/overlay/packages.append" >> "$PACKAGE_LIST"
# 只移除精确包名，不影响 linux-firmware 等包；重复项合并。
awk '
  { sub(/#.*/, ""); if (NF == 0) next }
  NF != 1 { print "无效的包清单行：" $0 > "/dev/stderr"; exit 1 }
  $1 != "linux" && !seen[$1]++ { print $1 }
' "$PACKAGE_LIST" > "$BUILD_DIR/packages.x86_64"
mv "$BUILD_DIR/packages.x86_64" "$PACKAGE_LIST"
grep -qx 'linux-lts' "$PACKAGE_LIST" || die "包清单必须包含 linux-lts"
if grep -qx 'linux' "$PACKAGE_LIST"; then
  die "包清单不能包含 generic linux"
fi

PACMAN_CONF="$PROFILE/pacman.conf"
[[ -f "$PACMAN_CONF" ]] || die "releng 配置缺少 pacman.conf"
# pacman-conf 展开 Include，不能只检查主文件中的仓库标题。
repositories="$(pacman-conf --config "$PACMAN_CONF" --repo-list)"
core_enabled=false
extra_enabled=false
while IFS= read -r repository; do
  case "$repository" in
    core) core_enabled=true ;;
    extra) extra_enabled=true ;;
    *) die "仅允许官方 core/extra 稳定仓库，发现：$repository" ;;
  esac
done <<< "$repositories"
[[ $core_enabled == true && $extra_enabled == true ]] \
  || die "pacman.conf 必须启用官方 core 和 extra 仓库"

# 同时覆盖构建和 Live 环境的软件源；mirrorlist 仍由 releng 管理。
cp -a "$HERE/overlay/airootfs/." "$PROFILE/airootfs/"
install -m644 "$PACMAN_CONF" "$PROFILE/airootfs/etc/pacman.conf"

for directory in efiboot grub syslinux; do
  [[ -d "$PROFILE/$directory" ]] || die "releng 缺少 $directory 引导配置"
  mapfile -d '' -t boot_files < <(find "$PROFILE/$directory" -type f \( -name '*.cfg' -o -name '*.conf' \) -print0)
  ((${#boot_files[@]})) || die "$directory 下没有引导配置"
  for boot_file in "${boot_files[@]}"; do
    sed -i -E \
      -e 's#vmlinuz-linux([^[:alnum:]_.-]|$)#vmlinuz-linux-lts\1#g' \
      -e 's#initramfs-linux\.img([^[:alnum:]_.-]|$)#initramfs-linux-lts.img\1#g' \
      -e 's#Arch Linux install medium#Nanbu Linux install medium#g' \
      -e 's#Arch Linux live medium#Nanbu Linux live medium#g' \
      "$boot_file"
  done
  if grep -nE 'vmlinuz-linux([^[:alnum:]_.-]|$)|initramfs-linux\.img([^[:alnum:]_.-]|$)' "${boot_files[@]}"; then
    die "$directory 中仍有 generic kernel 路径"
  fi
  grep -q 'vmlinuz-linux-lts' "${boot_files[@]}" || die "$directory 没有 LTS kernel 路径"
  grep -q 'initramfs-linux-lts\.img' "${boot_files[@]}" || die "$directory 没有 LTS initramfs 路径"
done

# 沿用当前 archiso 的 bootmodes 和 file_permissions，避免固定过期模板。
printf '\n' >> "$PROFILE/profiledef.sh"
cat "$HERE/overlay/profiledef.sh" >> "$PROFILE/profiledef.sh"

# 新版 releng 未必提供此文件；创建有效脚本，已有脚本则保留并追加。
CUST="$PROFILE/airootfs/root/customize_airootfs.sh"
mkdir -p "$(dirname "$CUST")"
if [[ ! -f "$CUST" ]]; then
  printf '#!/usr/bin/env bash\nset -euo pipefail\n' > "$CUST"
fi
printf '\n' >> "$CUST"
cat "$HERE/overlay/customize.append.sh" >> "$CUST"
chmod 755 "$CUST"
bash -n "$CUST"

printf '>> 临时 profile: %s\n' "$PROFILE"
printf '>> Live 内核: linux-lts；软件源: core/extra\n'
printf '>> 开始构建，输出目录: %s\n' "$OUT"
# 在空输出目录构建，不能把上一次遗留的 ISO 当成本次成功产物。
mkarchiso -v -w "$WORK" -o "$BUILD_DIR/out" "$PROFILE"
shopt -s nullglob
isos=("$BUILD_DIR/out"/*.iso)
((${#isos[@]})) || die "mkarchiso 未生成 ISO"
mkdir -p "$OUT"
for iso in "${isos[@]}"; do
  [[ -s "$iso" ]] || die "生成了空 ISO：$iso"
  install -m644 "$iso" "$OUT/$(basename "$iso")"
  printf '>> 完成: %s/%s\n' "$OUT" "$(basename "$iso")"
done
