# ============================================================
# Nanbu Linux 追加配置 —— 由 build.sh 追加到 releng 的
# airootfs/root/customize_airootfs.sh 之后执行（跑在 chroot 内）。
# releng 已处理：网络(systemd-networkd/iwd)、root 密码、locale、镜像等。
# 这里只做：root 控制台自动登录 + 自动拉起 archinstall。
# ============================================================

# root 自动登录 tty1（若 releng 已配置则幂等无害）
mkdir -p /etc/systemd/system/getty@tty1.service.d
cat > /etc/systemd/system/getty@tty1.service.d/autologin.conf <<'EOF'
[Service]
ExecStart=
ExecStart=-/usr/bin/agetty --autologin root --noclear %I $TERM
EOF

# root 登录后自动启动安装器
cat > /root/.bash_profile <<'EOF'
# Nanbu Linux —— 登录即启动系统安装
if [[ -f /usr/bin/archinstall && ${EUID} -eq 0 ]]; then
  archinstall
fi
EOF

echo ">> Nanbu Linux：已配置 root 自动登录 + 自动启动 archinstall"