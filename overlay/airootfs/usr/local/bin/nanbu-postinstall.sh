#!/usr/bin/env bash
# Nanbu Linux —— 安装结束后的收尾脚本（Calamares shellprocess 在目标系统 chroot 内执行）
# 职责：把 live 的 lightdm+openbox 交接给用户实际选中的桌面；开启 nanbu 自动登录；清理安装器组件。
set -euo pipefail

detect_dm() {
  if   [[ -x /usr/bin/gdm ]];     then echo gdm
  elif [[ -x /usr/bin/sddm ]];    then echo sddm
  elif [[ -x /usr/bin/lightdm ]]; then echo lightdm
  else echo none; fi
}

DM="$(detect_dm)"
echo "检测到显示管理器: ${DM}"

# ---- 引导：重建 GRUB 配置（bootloader 模块已装好 grub，这里兜底生成菜单）----
if command -v grub-mkconfig &>/dev/null; then
  grub-mkconfig -o /boot/grub/grub.cfg
fi

# ---- 网络 ----
systemctl enable NetworkManager.service 2>/dev/null || true
systemctl disable systemd-networkd.service systemd-resolved.service 2>/dev/null || true

# ---- 桌面会话交接 ----
# 关掉 live 会话；删掉 openbox 自启，避免开机又弹安装器
systemctl disable lightdm.service 2>/dev/null || true
rm -f /etc/xdg/openbox/autostart

case "$DM" in
  gdm)
    systemctl enable gdm.service
    mkdir -p /etc/gdm
    printf '[daemon]\nAutomaticLoginEnable=true\nAutomaticLogin=nanbu\n' > /etc/gdm/custom.conf
    ;;
  sddm)
    systemctl enable sddm.service
    mkdir -p /etc/sddm.conf.d
    printf '[Autologin]\nSession=plasma\nUser=nanbu\n' > /etc/sddm.conf.d/autologin.conf
    ;;
  lightdm)
    systemctl enable lightdm.service
    mkdir -p /etc/lightdm
    printf '[Seat:*]\nautologin-user=nanbu\ngreeter-session=lightdm-gtk-greeter\n' > /etc/lightdm/lightdm.conf
    ;;
  none)
    echo "未检测到桌面显示管理器，保持控制台登录。"
    ;;
esac

# ---- 清理安装器专用组件 ----
pacman -Rns --noconfirm calamares openbox 2>/dev/null || true
if [[ "$DM" != "lightdm" ]]; then
  pacman -Rns --noconfirm lightdm lightdm-gtk-greeter xterm 2>/dev/null || true
fi

echo ">> Nanbu Linux 安装收尾完成（DM=${DM}）"