# Nanbu Linux

面向**稳定**的 Arch 系发行版构建工程。默认用户 `nanbu`，安装到磁盘的引导器用 **GRUB**，安装过程中可选桌面环境（GNOME / KDE Plasma / Xfce / 最小化）。目标运行环境：Lima VM（宿主是 Ubuntu 也没关系，靠 Lima 提供 Arch 构建环境）。

---

## 目录结构

```
nanbu-linux/
├── build.sh                  # 主构建脚本（在 Arch 内以 root 运行）
├── overlay/                  # 叠放到 archiso releng 配置上的定制增量
│   ├── profiledef.sh         # ISO 元数据 + 引导模式（GRUB/syslinux）
│   ├── pacman.conf           # 构建源（稳定源 + 本地仓库占位）
│   ├── packages.append       # 追加进 ISO 的包（会被安装到最终系统）
│   ├── airootfs/             # 打进 live/安装后系统的根文件系统定制
│   │   ├── root/customize_airootfs.sh   # chroot 阶段：建用户/开服务/自动登录
│   │   ├── etc/…             # locale、hostname、os-release、lightdm、openbox…宿主
│   │   └── usr/local/bin/nanbu-postinstall.sh  # 安装结束后的收尾脚本
│   └── calamares/            # 安装器覆盖：settings、netinstall(桌面选择)、shellprocess
└── lima/build.yaml           # Lima 构建 VM 配置（可选）
```

关键文件说明：

- **`profiledef.sh`** —— `iso_name`、GRUB/syslinux 引导、initramfs 参数等。
- **`packages.append`** —— 稳定取向的包集：`linux-lts`、Xorg + Openbox + LightDM（live 会话）、Calamares、NetworkManager、CJK 字体等。这些包既是 live 环境也是被安装系统的基础。
- **`customize_airootfs.sh`** —— 创建 `nanbu`（`wheel` 组、sudo），开启 NetworkManager / LightDM，live 会话自动登录并自动拉起 Calamares。
- **`nanbu-postinstall.sh`** —— 安装最后执行：把 live 的 lightdm+openbox 交接给用户选中的真实 DM（gdm/sddm/lightdm），给 `nanbu` 开启自动登录，卸载 calamares/openbox 等安装器专用组件，重建 grub 配置。
- **`overlay/calamares/`** —— `settings.conf`（流程）、`netinstall.yaml`（桌面三选一）、`shellprocess.conf`（跑收尾脚本）、branding。

---

## 一键构建（在 Arch 环境里）

构建 **必须** 在 Arch 系统内运行（`mkarchiso` 依赖 Arch 工具链）。你的宿主是 Ubuntu，所以第一步用 Lima 起一个 Arch 虚拟机：

```bash
# 1) 起一个 Arch 构建 VM（Lima 模板，直接可跑）
limactl start --name=nanbu-build template://archlinux

# 2) 把工程挂进去，shell 进 VM
limactl shell nanbu-build
```

或者用仓库里现成的 [lima/build.yaml](lima/build.yaml)（带好了挂载点）。

VM 内，在工程目录下：

```bash
sudo pacman -Sy --noconfirm archiso calamares grub syslinux squashfs-tools
sudo ./build.sh
```

产物在 `out/nanbu-linux-*.iso`。

`build.sh` 做了什么：复制 `releng` 配置 → 追加包列表 → 覆盖 `profiledef.sh`/`pacman.conf`/`customize_airootfs.sh` → 叠加 `airootfs` → 从本机已装的 Calamares 包继承模块与 branding 并叠加定制 → 跑 `mkarchiso`。

---

## 测试 ISO（装进一个磁盘镜像，喂给 Lima）

Lima 默认直接引导内核+initrd，不引导 CD 映像；所以用 QEMU 挂 CD 装到一块空白 qcow2，再把装好的磁盘给 Lima 用：

```bash
# 建一块空盘
qemu-img create -f qcow2 nanbu-root.qcow2 32G

# 挂 ISO 启动，走安装
qemu-system-x86_64 \
  -enable-kvm -m 4G -smp 4 \
  -cdrom out/nanbu-linux-*.iso \
  -drive file=nanbu-root.qcow2,format=qcow2 \
  -boot d
```

安装完成后关机，把 `nanbu-root.qcow2` 交给 Lima（或用同样的 qemu 直接启动验证引导）。

---

## 默认凭据（务必修改后再对外分发）

| 项 | 值 |
|---|---|
| 用户 | `nanbu` |
| 密码 | `nanbu`（在 `customize_airootfs.sh` 里 `echo 'nanbu:nanbu' \| chpasswd`） |
| root | 已锁定（`passwd -l root`），通过 `nanbu` + sudo 提权 |
| sudo | `wheel` 组已启用（`/etc/sudoers.d/10-wheel`） |
| 主机名 | `nanbu` |

---

## 版本差异注意（重要）

- 本工程的 `settings.conf` 按 Calamares 3.3.x 的模块名编写（含 `sources-yaml` 等）。**`build.sh` 会优先从你机器上 `/usr/share/calamares/` 继承模块和 branding**，所以版本不对时不会整个散架；若 `mkarchiso` 后 `calamares` 报某个模块缺失，用下面命令对照改 `overlay/calamares/settings.conf`：
  ```bash
  find /usr/share/calamares/modules -maxdepth 1 -mindepth 1 -printf '%f\n' | sort
  ```
- 桌面选择用 Calamares 的 `netinstall` 模块（复选框）。请在安装界面**勾选且只勾选一个桌面组**；勾多个时 `nanbu-postinstall.sh` 只启用检测到的第一个 DM。
- 装完的自动登录、默认会话名（`plasma`）如需调整，改 `overlay/airootfs/usr/local/bin/nanbu-postinstall.sh`。