# Nanbu Linux

面向稳定的 Arch 系发行版。安装器采用官方维护的 **archinstall**（Calamares 已从 Arch 官方仓库移除，故弃用）。

## 目录

- `build.sh` — 一键构建脚本（追加式，不在共享目录下构建）
- `overlay/packages.append` — 追加进 live ISO 的包
- `overlay/profiledef.sh` — ISO 元数据 / 引导模式
- `overlay/customize.append.sh` — 追加进 releng 的 `customize_airootfs.sh`（root 自动登录 + 自动启动安装器）
- `overlay/airootfs/etc/` — live 环境的 locale/hostname 等
- `lima/build.yaml` — Lima VM 参考配置

## 构建环境

构建必须在 **Arch Linux 虚拟机** 内执行。Ubuntu 是外层宿主系统，不能直接运行 `archiso`；请在 VirtualBox 中启动 Arch Linux 虚拟机，并把项目复制到虚拟机的本地磁盘后再构建。脚本会检查当前系统，不会在 Ubuntu 上继续执行。

## 构建（必须在 Arch VM 的本地磁盘，VBox 共享目录不行）

```bash
# 以下命令在 VirtualBox 内的 Arch Linux 虚拟机中执行
sudo pacman -Syu --needed archiso archinstall

# 若项目通过共享目录挂载在 /mnt，先复制到虚拟机本地磁盘
sudo cp -a /mnt/nanbuos /root/nanbu-linux
cd /root/nanbu-linux

# 构建
sudo ./build.sh
# ISO 输出到 ./out/
```

## 安装流程（archinstall 引导模式）

live 启动后 root 自动登录并直接进入 `archinstall`，按提示填写：

| 步骤 | 选择 |
| --- | --- |
| Mirrors / 镜像 | 保持默认（releng 已带 reflector） |
| Locales | 键盘 `us`，locale `en_US.UTF-8`（中文可加 `zh_CN.UTF-8`） |
| Disk configuration | 选磁盘 → 让 archinstall 自动分区（ext4/btrfs 任选，稳定取向 ext4） |
| Bootloader | **GRUB** |
| Swap | 按需 |
| Hostname | `nanbu` |
| Root password | 自定 |
| **User account** | 用户名 `nanbu` |
| **Profile → Type: Desktop** | 选桌面包（GNOME / KDE Plasma / Xfce…） |
| Audio | 随 DE 提示（PipeWire） |
| **Kernels** | 选 `linux-lts`（稳定取向） |
| Network configuration | **NetworkManager** |
| Additional packages | 按需（如 `firefox`） |
| Timezone | Asia/Shanghai |
| 完成 | 写入磁盘 → 重启 |

> 说明：archinstall 用 `pacstrap` 全新安装，live 里预置的 hostname/user 只影响 live 环境，
> 不会带进安装好的系统——用户名/hostname/DE 都在上表交互式设置。

## 稳定取向约定

- 用官方稳定仓库，不启用 testing / 社区黑名单外的边缘源。
- 内核选 `linux-lts`。
- 不预装 `xf86-video-vmware`（已移除，xorg 自带 modesetting）。