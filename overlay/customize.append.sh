# ============================================================
# Nanbu Linux live 配置 —— 由 build.sh 追加到 releng 的
# customize_airootfs.sh，在构建 chroot 内执行。
# ============================================================

mkdir -p /etc/systemd/system/getty@tty1.service.d /usr/local/bin
cat > /etc/systemd/system/getty@tty1.service.d/autologin.conf <<'EOF'
[Service]
ExecStart=
ExecStart=-/usr/bin/agetty --autologin root --noclear %I $TERM
EOF

cat > /usr/local/bin/nanbu-start-installer <<'EOF'
#!/usr/bin/env bash
if [[ $(tty) == /dev/tty1 && ${EUID} -eq 0 && -x /usr/bin/archinstall ]]; then
  printf '\nNanbu Linux installer (linux-lts recommended).\n'
  printf 'Exit archinstall to return to the live shell. Website: https://www.huafxy.com\n\n'
  # archinstall 依赖 releng 的密钥环初始化完成。
  if ! systemctl start pacman-init.service; then
    printf 'Keyring initialization failed. Retry archinstall after fixing it.\n' >&2
    exit 1
  fi
  /usr/bin/archinstall
  printf '\nBack in the live shell. Run archinstall to retry.\n'
fi
EOF
chmod 755 /usr/local/bin/nanbu-start-installer

# releng 默认登录 shell 是 zsh；保留已有的无障碍和自动化脚本入口。
cat >> /root/.zlogin <<'EOF'

[[ -o interactive ]] && /usr/local/bin/nanbu-start-installer
EOF
cat >> /root/.bash_profile <<'EOF'

[[ $- == *i* ]] && /usr/local/bin/nanbu-start-installer
EOF
