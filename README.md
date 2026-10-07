# Nanbu Linux

面向虚拟机安装的 Arch 系发行版安装介质。官网地址目前是暂定值：<https://www.huafxy.com>。
安装器采用官方维护的 **archinstall**；ISO 不预装固定桌面，桌面和目标系统的软件由你在安装时选择。

## 设计目标

- Live ISO 使用官方 `linux-lts` 内核，目标系统也建议选择 `linux-lts`。
- 只使用 Arch 官方稳定仓库 `core` 和 `extra`，不启用 testing、staging、AUR 或第三方仓库。
- 保留官方 releng 的网络、镜像和救援工具配置。
- 使用 BIOS/UEFI 启动配置，适合 VirtualBox、QEMU 等虚拟机。

> Arch Linux 是滚动更新发行版。这里的“稳定”表示使用官方仓库、LTS 内核、完整系统升级和保守的依赖选择，并不表示软件版本长期冻结。每次升级请使用完整的 `pacman -Syu`，不要单独执行 `pacman -Sy`。

## 目录

- `build.sh` — 在 Arch 构建机上生成 ISO；临时 profile 不写回源代码树
- `overlay/packages.append` — 追加进 Live ISO 的官方软件包
- `overlay/profiledef.sh` — ISO 元数据、官网和 BIOS/UEFI 引导模式
- `overlay/customize.append.sh` — root tty 自动登录并启动 archinstall
- `overlay/airootfs/etc/` — Live 环境的 hostname、locale、键盘和 hosts

## 构建环境

真实构建必须在 **Arch Linux** 内执行。Ubuntu 只能作为外层宿主机，不能在本机直接生成 ArchISO；构建脚本会主动拒绝非 Arch 系统。

构建目录必须位于虚拟机的本地 Linux 文件系统。不要直接在 VirtualBox 共享目录、9p 或其他不完整支持符号链接和 root 权限的挂载点运行 `mkarchiso`。

在 Arch 构建虚拟机中执行：

```bash
sudo pacman -Syu
sudo pacman -S --needed archiso archinstall grub syslinux squashfs-tools edk2-ovmf mtools dosfstools libisoburn
```

如果项目通过共享目录挂载在 `/mnt`，先复制到本地磁盘：

```bash
sudo cp -a /mnt/nanbuos /root/nanbu-linux
cd /root/nanbu-linux
```

然后构建：

```bash
sudo ./build.sh
```

ISO 会写入 `./out/`，该目录已加入 `.gitignore`。脚本在 `/var/tmp` 使用独立的临时 profile/work 目录，退出时清理，不会删除或重建项目内的 `profile/`。也可通过 `TMPDIR` 指定有足够空间的本地目录。建议构建 VM 至少提供 4 核 CPU、8 GiB 内存及 40 GiB 磁盘；不要把整个构建工作树放在小容量的 `/tmp` tmpfs 上。

## 安装流程

Live 启动后 root 会自动登录并进入 `archinstall`。根据界面提示完成配置，推荐：

| 项目 | 稳定取向建议 |
| --- | --- |
| Mirrors | 使用官方镜像；按需要选择距离较近的镜像 |
| Disk configuration | 虚拟机可选自动分区；文件系统优先 ext4 |
| Bootloader | GRUB，兼容常见 BIOS/UEFI 虚拟机 |
| Kernel | **`linux-lts`** |
| Network configuration | NetworkManager |
| Profile | 按需选择 GNOME、KDE Plasma、Xfce 或不安装桌面 |
| Additional packages | 只添加确实需要的软件 |
| Timezone | 按所在地区选择，例如 `Asia/Shanghai` |

Live 环境的 hostname 和 root 登录只服务于安装介质，不会强制写入安装目标。用户名、hostname、桌面、磁盘布局和附加软件都由你在 archinstall 中确认。

安装完成首次启动后，先完整更新系统：

```bash
sudo pacman -Syu
```

## 验证构建结果

在 Arch 构建机上可以检查 ISO 内容：

```bash
bsdtar -tf out/*.iso | grep -E 'vmlinuz-linux-lts|initramfs-linux-lts.img|archinstall'
```

再分别用 VirtualBox 或 QEMU 的 BIOS/UEFI 模式启动测试，确认 Live 系统进入 tty 并启动 archinstall；安装到测试磁盘后，用 `uname -r` 确认运行的是 `linux-lts` 内核。
