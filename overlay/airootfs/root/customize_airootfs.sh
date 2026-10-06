#!/usr/bin/env bash
# Nanbu Linux —— airootfs 定制（mkarchiso 在 chroot 里运行本脚本）
# 这里做的所有改动，都会随 unpackfs 一起进入「被安装的系统」。
set -euo pipefail

# ---------- 区域 / 键盘 / 时区 ----------
sed -i 's/^#\(en_US.UTF-8\|zh_CN.UTF-8\)/\1/' /etc/locale.gen
locale-gen
echo 'LANG=en_US.UTF-8' > /etc/locale.conf
echo 'KEYMAP=us' > /etc/vconsole.conf
ln -sf /usr/share/zoneinfo/UTC /etc/localtime
hwclock --systohc || true

# ---------- 主机名 ----------
echo 'nanbu' > /etc/hostname

# ---------- 用户 ----------
# live：live 图形会话自动登录用
if ! id -u live &>/dev/null; then
  useradd -m -G wheel -s /bin/bash live
  passwd -d live
fi

# nanbu：发行版默认用户（会进入被安装的系统）
if ! id -u nanbu &>/dev/null; then
  useradd -m \
    -G wheel,audio,video,storage,optical,network,input,kvm \
    -s /bin/bash nanbu
  echo 'nanbu:nanbu' | chpasswd      # ← 默认密码，对外分发前务必改掉
fi

# ---------- sudo ----------
echo '%wheel ALL=(ALL:ALL) ALL' > /etc/sudoers.d/10-wheel
chmod 440 /etc/sudoers.d/10-wheel   # sudoers 要求 0440，否则 sudo 会告警/拒绝

# ---------- root：锁定，靠 sudo 提权 ----------
passwd -l root || true

# ---------- 服务 ----------
systemctl enable NetworkManager.service
systemctl enable lightdm.service
systemctl enable bluez.service 2>/dev/null || true
systemctl enable sshd.service 2>/dev/null || true   # VM 里远程管理方便（可选）
systemctl enable fstrim.timer 2>/dev/null || true

# ---------- live 会话：LightDM 自动登录 + Openbox 自动拉起安装器 ----------
mkdir -p /etc/lightdm
cat > /etc/lightdm/lightdm.conf <<'EOF'
[Seat:*]
autologin-user=live
autologin-session=openbox
greeter-session=lightdm-gtk-greeter
user-session=openbox
user-timeout=0
EOF

mkdir -p /etc/xdg/openbox
cat > /etc/xdg/openbox/autostart <<'EOF'
# live 桌面直接启动安装器（调试改用: calamares -d）
calamares &
EOF

# ---------- 一次性安装引导（救援环境下可用） ----------
cat > /root/.automated_script.sh <<'EOF'
#!/usr/bin/env bash
# 救援环境里手动进入 chroot 的辅助脚本
script_cmdline() {
  local param
  for param in $(</proc/cmdline); do
    case "${param}" in
      script=*) echo "${param#*=}"; return 0 ;;
    esac
  done
}
automated_script() {
  local script rt
  script="$(script_cmdline)"
  if [[ -n "$script" && -x "/root/$script" ]]; then
    "/root/$script"
  fi
}
if [[ -z "$(tty)" ]]; then
  rt=$(mktemp -t roottmp.XXXX)
  automated_script 2>"$rt"
  cat "$rt"
fi
EOF

echo ">> Nanbu Linux 根文件系统定制完成"