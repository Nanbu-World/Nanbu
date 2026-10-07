# Nanbu Linux 构建任务交接文档

> 更新时间：2026-10-07  
> 当前仓库：`/home/xiangjian520/project/NanbuOS`  
> 当前分支：`master`  
> 真实 ISO 构建状态：**尚未构建**（当前开发环境是 Ubuntu，不具备 `archiso` 构建环境）

## 1. 任务目标

将本仓库整理为一个面向虚拟机的 Arch 系安装 ISO：

- Live ISO 和安装目标优先使用官方 `linux-lts` 内核；
- 软件包只来自 Arch 官方稳定仓库 `core`、`extra`；
- 不启用 testing、staging、AUR 或第三方仓库；
- 使用官方 `archinstall`，不预装固定桌面环境；
- 能够在 VirtualBox、QEMU 等虚拟机中使用 BIOS/UEFI 启动；
- 官网地址暂定为 <https://www.huafxy.com>；
- 不使用 Lima，Lima 配置已移除。

Arch 本身是滚动更新发行版。本文和项目中的“稳定”指官方稳定仓库、LTS 内核、完整系统升级和保守的构建依赖，并不表示版本长期冻结。

## 2. 当前实现概览

### 构建流程

[build.sh](build.sh) 目前执行以下流程：

1. 只允许 x86_64 的官方 Arch Linux，并要求 root；
2. 检查 `mkarchiso`、`pacman`、`pacman-conf`、`findmnt` 和构建依赖；
3. 拒绝在 `vboxsf`、`9p`、NFS、CIFS 等共享文件系统中构建；
4. 将 `/usr/share/archiso/configs/releng` 复制到 `/var/tmp`（或 `$TMPDIR`）下的临时目录；
5. 在临时 profile 中把 releng 的 `linux` 移除，加入 `linux-lts` 和 overlay 包；
6. 使用 `pacman-conf --repo-list` 检查只启用了 `core`、`extra`；
7. 将 EFI、GRUB、Syslinux 配置中的：
   - `vmlinuz-linux` 替换为 `vmlinuz-linux-lts`；
   - `initramfs-linux.img` 替换为 `initramfs-linux-lts.img`；
8. 追加 Live 环境定制、locale、hostname 和 hosts；
9. 使用 BIOS Syslinux 和 UEFI GRUB 构建 ISO；
10. ISO 先输出到临时目录，确认非空后复制到 `./out/` 或命令行指定的输出目录；
11. 退出时只删除临时构建目录，不删除项目中的 `profile/` 或其他源文件。

### Live 环境

[overlay/customize.append.sh](overlay/customize.append.sh) 当前：

- 配置 tty1 root 自动登录；
- 写入 `/usr/local/bin/nanbu-start-installer`；
- releng 默认 root shell 为 zsh，因此追加 `/root/.zlogin`；
- 同时追加 `/root/.bash_profile` 以兼容 bash；
- tty1 登录后启动 `archinstall`；
- 退出安装器后保留在 Live shell 中。

### 内核和软件包

[overlay/packages.append](overlay/packages.append) 当前加入：

- `linux-lts`；
- `archinstall`；
- `zsh`、`zsh-completions`、`bash-completion`；
- `git`；
- `terminus-font`。

releng 的通用 `linux` 行由 [build.sh](build.sh) 在临时 profile 中精确删除，不修改仓库内的生成 profile。

### ISO 元数据

[overlay/profiledef.sh](overlay/profiledef.sh) 当前设置：

- ISO 名称：`nanbu-linux`；
- publisher：`Nanbu Linux <https://www.huafxy.com>`；
- `arch="x86_64"`；
- `buildmodes=('iso')`；
- `bootmodes=('bios.syslinux' 'uefi.grub')`；
- `install_dir="arch"`。

## 3. 当前工作区状态

本次工作区不是干净状态，接手者不要直接用 `git reset --hard` 或批量恢复全部删除：

### 已恢复并修改的必要源文件

- [README.md](README.md)
- [build.sh](build.sh)
- [overlay/packages.append](overlay/packages.append)
- [overlay/profiledef.sh](overlay/profiledef.sh)
- [overlay/customize.append.sh](overlay/customize.append.sh)
- [overlay/airootfs/etc/hostname](overlay/airootfs/etc/hostname)
- [overlay/airootfs/etc/hosts](overlay/airootfs/etc/hosts)
- [overlay/airootfs/etc/locale.conf](overlay/airootfs/etc/locale.conf)
- [overlay/airootfs/etc/locale.gen](overlay/airootfs/etc/locale.gen)
- [overlay/airootfs/etc/vconsole.conf](overlay/airootfs/etc/vconsole.conf)
- [.gitignore](.gitignore)

### 按用户确认保留的删除

- `lima/build.yaml`：用户明确表示不需要 Lima，已移除；
- `profile/`：这是 HEAD 中提交的 releng 快照，构建脚本不再使用它，保留删除状态；
- 顶层旧 [profiledef.sh](profiledef.sh)：已删除，权威配置为 `overlay/profiledef.sh`；
- `LICENSE`：用户确认只恢复构建所需文件，因此当前仍是删除状态。

如果后续需要发布仓库，应单独确认是否重新加入许可证；不要因为构建失败而恢复整个 `profile/` 树。

## 4. 已完成验证

在 Ubuntu 开发环境中已完成：

```bash
bash -n build.sh overlay/customize.append.sh overlay/profiledef.sh
git diff --check
```

结果：通过。

还验证了：

- `build.sh` 在非 Arch 主机上会提前拒绝；当前输出为“当前宿主系统不是 Arch Linux”；
- 包清单转换会删除精确的 `linux`，保留 `linux-firmware`，并加入 `linux-lts`；
- 启动路径转换会生成 LTS 内核和 initramfs 文件名；
- 旧的 `example.org`、`example.com`、Calamares、Lima 配置引用已从活动源文件移除；
- 本机没有安装 archiso，因此没有执行真实 `mkarchiso`、ISO 启动或安装测试。

## 5. 接手者在 Arch 虚拟机中的操作顺序

### 准备构建机

在 Arch 虚拟机本地磁盘执行：

```bash
sudo pacman -Syu
```

```bash
sudo pacman -S --needed archiso archinstall grub syslinux squashfs-tools edk2-ovmf mtools dosfstools libisoburn
```

如果项目来自 VirtualBox 共享目录，先复制到本地磁盘：

```bash
sudo cp -a /mnt/nanbuos /root/nanbu-linux
```

```bash
cd /root/nanbu-linux
```

### 构建

```bash
sudo ./build.sh
```

也可以指定输出目录：

```bash
sudo ./build.sh /var/tmp/nanbu-output
```

如果 `/var/tmp` 空间不足，可指定本地磁盘目录：

```bash
sudo TMPDIR=/var/lib/nanbu-build ./build.sh
```

### 构建后检查

```bash
ls -lh out/
```

```bash
bsdtar -tf out/*.iso | grep -E 'vmlinuz-linux-lts|initramfs-linux-lts.img|archinstall'
```

确认：

- ISO 文件存在且非空；
- ISO 同时含 `vmlinuz-linux-lts` 和 `initramfs-linux-lts.img`；
- 不存在 generic `vmlinuz-linux` 或 `initramfs-linux.img` 引用；
- ISO 能分别在 VirtualBox/QEMU 的 BIOS 和 UEFI 模式启动。

## 6. 必须完成的端到端测试

1. BIOS 启动 ISO；
2. UEFI 启动 ISO；
3. 确认 root 自动登录 tty1；
4. 确认 `archinstall` 自动启动；
5. 在 archinstall 中选择 `linux-lts`；
6. 使用测试虚拟磁盘完成安装；
7. 首次启动安装结果；
8. 执行 `uname -r`，确认内核版本带 `lts`；
9. 检查安装后 `/etc/pacman.conf` 未启用 testing/AUR；
10. 执行一次完整的 `sudo pacman -Syu`；
11. 测试退出 archinstall 后能回到 Live shell，并且可手工再次执行安装器。

## 7. 接手时优先检查的兼容点

这些事项尚未在真实 Arch 环境中验证：

- 当前构建脚本追加 overlay `profiledef.sh` 到 releng `profiledef.sh` 末尾；需确认当前安装的 archiso 版本支持 `uefi.grub`，并确认继承的 `file_permissions` 没有被不期望地覆盖；
- `pacman-conf --repo-list` 会解析 profile 的 `Include` 文件，需确认 Arch 构建机上的 mirrorlist 可被解析；
- Live 启动时 `/usr/local/bin/nanbu-start-installer` 会尝试启动 `pacman-init.service`，应确认服务在 VirtualBox/QEMU 中已经完成或能正常启动；
- 不要在输出路径位于 `/var/tmp/nanbu-archiso.*` 临时目录内部时运行构建，因为构建结束会清理整个临时树；
- 若 ArchISO 新版本移除 `customize_airootfs.sh` 支持，应把 Live 定制迁移到其推荐的 systemd/overlay 机制，而不是恢复旧的 tracked profile。

如果实际构建失败，首先保存完整日志和 Arch/archiso 版本：

```bash
uname -a
```

```bash
pacman -Q archiso archinstall linux-lts grub syslinux
```

```bash
sudo ./build.sh 2>&1 | tee nanbu-build.log
```

## 8. 不要做的事情

- 不要运行 `pacman -Sy` 单独同步数据库；
- 不要启用 testing、staging、AUR 或未验证的第三方仓库；
- 不要把 releng 复制回仓库的 `profile/`；
- 不要在共享目录中运行 `mkarchiso`；
- 不要只替换包名而忘记同步 EFI、GRUB、Syslinux 的 LTS 路径；
- 不要把固定桌面环境、固定用户或固定安装分区写死到 Live ISO；
- 不要把 Ubuntu 上的静态检查描述为已完成的 ISO 构建测试。
