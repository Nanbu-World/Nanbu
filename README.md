# Nanbu（nanbu）

> 一个基于 Arch Linux 的现代、滚动更新、开箱即用的 Linux 发行版。

[![Status](https://img.shields.io/badge/status-alpha-orange)](https://github.com/nanbu-linux/nanbu/releases)
[![Base](https://img.shields.io/badge/base-Arch%20Linux-1793D1?logo=archlinux)](https://archlinux.org/)
[![License](https://img.shields.io/badge/license-GPL--3.0-blue)](./LICENSE)
[![Build ISO](https://github.com/nanbu-linux/nanbu/actions/workflows/build.yml/badge.svg)](https://github.com/nanbu-linux/nanbu/actions)

---

## 简介

`Nanbu` 是一个基于 **Arch Linux** 的独立 Linux 发行版，继承 Arch 的简洁、滚动更新、PKGBUILD 与 AUR 生态，同时提供：

- 预配置桌面环境
- 更友好的安装体验
- 中文与常用软件开箱即用
- 精选驱动、内核与硬件支持
- 自研配置工具与软件仓库

> 当前处于早期开发阶段，配置、包名、ISO 名称和功能可能随时变化。

---

## 特性

- **滚动更新**：跟随 Arch Linux 仓库滚动更新。
- **多种桌面**：计划支持 KDE Plasma、GNOME、Hyprland、XFCE 等。
- **图形安装器**：集成 Calamares，提供简单直观的安装流程。
- **中文优化**：预装中文字体、输入法、时区与镜像配置。
- **AUR 支持**：内置 `paru` / `yay` 等 AUR 助手。
- **自研工具**：
  - `nanbu-welcome`：欢迎与初始配置工具
  - `nanbu-mirror`：镜像站测速与切换
  - `nanbu-update`：系统更新封装
- **可定制 ISO**：基于 `archiso`，方便二次开发与构建。
- **自建仓库**：提供 `nanbu` 专属软件仓库。

---

## 项目状态

当前状态：**Alpha / 开发中**

- [x] 基础 archiso 配置
- [x] 可启动 Live ISO
- [ ] Calamares 安装器完整集成
- [ ] 自建软件仓库
- [ ] Secure Boot 支持
- [ ] 官方镜像站
- [ ] 自动构建与发布流程

---

## 截图

> 待补充。

```text
docs/screenshots/desktop.png
docs/screenshots/installer.png
```

---

## 下载

| 版本 | 架构 | 桌面 | 下载 | SHA256 |
| --- | --- | --- | --- | --- |
| 0.1.0-alpha | x86_64 | KDE Plasma | [下载](https://github.com/nanbu-linux/nanbu/releases/download/v0.1.0-alpha/nanbu-0.1.0-alpha-x86_64.iso) | `<sha256>` |

校验 ISO：

```bash
sha256sum nanbu-0.1.0-alpha-x86_64.iso
```

---

## 快速开始

### 系统要求

- x86_64 处理器
- 至少 4 GB 内存，推荐 8 GB
- 至少 20 GB 磁盘空间
- UEFI 或 Legacy BIOS

### 制作启动盘

Linux：

```bash
sudo dd if=nanbu-0.1.0-alpha-x86_64.iso of=/dev/sdX bs=4M status=progress oflag=sync
```

Windows：

推荐使用 [Rufus](https://rufus.ie/) 或 [Ventoy](https://www.ventoy.net/)。

### 安装

1. 从 U 盘启动。
2. 进入 Live 环境。
3. 启动安装器：

```bash
sudo calamares
```

4. 按提示完成分区、用户、桌面环境和软件选择。
5. 安装完成后重启并移除 U 盘。

---

## 从源码构建 ISO

### 环境要求

- Arch Linux 或兼容环境
- `base-devel`
- `archiso`
- 至少 20 GB 可用磁盘
- 需要 root 权限运行 `mkarchiso`

### 安装依赖

```bash
sudo pacman -S --needed base-devel git archiso qemu-full
```

### 获取源码

```bash
git clone https://github.com/nanbu-linux/nanbu.git
cd nanbu
```

### 构建 ISO

```bash
sudo ./build.sh
```

或直接使用 `mkarchiso`：

```bash
sudo mkarchiso -v -w work -o out archiso
```

构建完成后，ISO 位于：

```text
out/nanbu-*.iso
```

### 本地测试

```bash
qemu-system-x86_64 \
  -enable-kvm \
  -m 4096 \
  -cdrom out/nanbu-*.iso \
  -boot d
```

如果没有 KVM，可移除 `-enable-kvm`，但速度会较慢。

---

## 项目结构

```text
.
├── archiso/                 # archiso profile
│   ├── airootfs/            # Live 系统根文件覆盖
│   ├── efiboot/             # UEFI 启动配置
│   ├── syslinux/            # BIOS 启动配置
│   ├── grub/                # GRUB 配置
│   ├── packages.x86_64      # Live 环境软件包列表
│   ├── pacman.conf          # pacman 配置
│   └── profiledef.sh        # ISO 元信息
├── calamares/               # 安装器配置与品牌资源
├── packages/                # 自研软件包 PKGBUILD
├── scripts/                 # 构建、发布、辅助脚本
├── build.sh                 # ISO 构建入口
├── LICENSE
└── README.md
```

---

## 自定义指南

### ISO 信息

编辑 `archiso/profiledef.sh`：

```bash
iso_name="nanbu"
iso_label="NANBU_$(date +%Y%m)"
iso_publisher="Nanbu <https://nanbu.example.com>"
iso_application="Nanbu Live/Install ISO"
iso_version="$(date +%Y.%m.%d)"
install_dir="arch"
```

### 软件包列表

编辑 `archiso/packages.x86_64`，加入 Live 环境和安装目标需要的包：

```text
base
linux
linux-firmware
networkmanager
sudo
vim
git
calamares
```

### Live 系统覆盖文件

将文件放入 `archiso/airootfs/`，会覆盖到 Live 系统中。例如：

```text
archiso/airootfs/etc/skel/.config/
archiso/airootfs/etc/NetworkManager/conf.d/
archiso/airootfs/root/
```

### 安装器配置

`calamares/` 中通常包含：

```text
calamares/
├── branding/
├── modules/
├── settings.conf
└── welcome.conf
```

你可以在这里修改品牌、分区方案、用户创建、包选择等。

### 自研软件包

将 PKGBUILD 放入 `packages/`，例如：

```text
packages/nanbu-welcome/PKGBUILD
packages/nanbu-mirror/PKGBUILD
```

构建：

```bash
cd packages/nanbu-welcome
makepkg -si
```

---

## 自建软件仓库

构建软件包后，生成仓库数据库：

```bash
cd repo/x86_64
repo-add nanbu.db.tar.zst *.pkg.tar.zst
```

在 `/etc/pacman.conf` 中添加：

```ini
[nanbu]
SigLevel = Required DatabaseOptional
Server = https://repo.example.com/nanbu/$arch
```

生产环境建议启用包签名，不要长期使用 `TrustAll`。

---

## 开发指南

### 分支策略

- `main`：稳定分支
- `dev`：开发分支
- `feat/*`：新功能
- `fix/*`：修复问题

### 提交规范

建议使用 Conventional Commits：

```text
feat: 添加 Calamares 中文配置
fix: 修复 Live 环境网络服务未启动
docs: 更新构建说明
```

### 本地测试清单

提交 PR 前请确认：

- [ ] ISO 可以成功构建
- [ ] Live 环境可以启动
- [ ] 网络可用
- [ ] 安装器可以完成安装
- [ ] 安装后系统可以正常启动
- [ ] 中文显示与输入法正常

---

## 贡献

欢迎提交 Issue 和 Pull Request。

1. Fork 本仓库
2. 创建分支：`git checkout -b feat/your-feature`
3. 提交修改：`git commit -m "feat: ..."`
4. 推送分支：`git push origin feat/your-feature`
5. 发起 Pull Request

请尽量附上：

- 问题描述
- 复现步骤
- 日志或截图
- 测试环境

---

## 常见问题

### Nanbu 和 Arch Linux 有什么区别？

`Nanbu` 基于 Arch Linux，但提供预配置桌面、安装器、中文优化、自研工具和自建仓库。它仍是独立项目，不是 Arch Linux 官方发行版。

### 可以访问 Arch 官方仓库和 AUR 吗？

可以。系统默认使用 Arch 官方仓库，并支持 AUR。

### 更新方式是什么？

```bash
sudo pacman -Syu
```

或使用封装工具：

```bash
nanbu-update
```

### 支持 Secure Boot 吗？

目前：开发中。

### 可以用于生产环境吗？

当前处于 Alpha 阶段，不建议用于关键生产环境。请先备份数据。

---

## 路线图

- [ ] 发布首个可安装 ISO
- [ ] 完成 Calamares 品牌与中文配置
- [ ] 建立自建仓库
- [ ] 支持 Secure Boot
- [ ] 提供多桌面版本
- [ ] 建立镜像站
- [ ] 自动构建与发布

---

## 社区与支持

- 文档：https://nanbu.example.com/docs
- 论坛：<论坛地址>
- Matrix：<Matrix 地址>
- Discord：<Discord 地址>
- 问题反馈：https://github.com/nanbu-linux/nanbu/issues
- 安全漏洞：security@nanbu.example.com

---

## 许可证

除非另有说明，本项目源代码采用 **GPL-3.0** 许可证。

各软件包、图标、品牌资源和第三方组件遵循其各自许可证。

---

## 致谢

感谢以下项目与社区：

- [Arch Linux](https://archlinux.org/)
- [archiso](https://gitlab.archlinux.org/archlinux/archiso)
- [Calamares](https://calamares.io/)
- [AUR](https://aur.archlinux.org/)
- 所有上游开发者与贡献者

---

## 免责声明

`Nanbu` 是独立项目，与 Arch Linux、archiso、Calamares 等项目无官方附属关系。

“Arch Linux” 是其所有者的商标。本项目仅说明其基于 Arch Linux 构建，不暗示任何官方认可或关联。