# 安装步骤

本文面向 **Dynabook G83/HU（i5-1145G7 / Iris Xe 9A49）** 安装 macOS Tahoe 26。

---

## 0. 准备

| 项目 | 要求 |
|---|---|
| U 盘 | ≥ 32 GB，**GUID 分区表**，含 **FAT32 EFI 分区**（≥ 200 MB） |
| 另一台电脑 | Windows / macOS 均可，用于制作安装盘 |
| 网络 | 安装过程需要联网（或用离线安装包） |

---

## 1. BIOS 设置

开机按 `F2` 进入 BIOS，确认：

| 选项 | 值 |
|---|---|
| Secure Boot | **Disabled** |
| Virtualization Technology (VT-x) | **Disabled** |
| Trusted Execution (TXT) | **Disabled** |
| Fast Boot | **Disabled** |
| CSM / Legacy Boot | **Disabled**（仅 UEFI） |

> 本机 BIOS 无 DVMT Pre-Allocated、Above 4G、Resizable BAR 选项，本 EFI 已按无这些选项的情况配置，无需额外调整。

---

## 2. 制作安装 U 盘

### 2a. 制作 macOS 安装器

在一台 Mac 或黑苹果上：

```bash
# 下载 macOS Tahoe 安装器（App Store 或 gibMacOS）
sudo /Applications/Install\ macOS\ Tahoe.app/Contents/Resources/createinstallmedia \
     --volume /Volumes/MyUSB --nointeraction
```

安装完成后 U 盘会有一个名为 `Install macOS Tahoe` 的分区。

### 2b. 挂载 U 盘的 EFI 分区并放入 EFI

```bash
diskutil list                      # 找到 U 盘对应的 diskX
sudo diskutil mount diskXs1        # 挂载该 U 盘的 EFI 分区
```

把本仓库 `EFI/` 文件夹**整个**拷贝到该 EFI 分区根目录：

```
/Volumes/EFI/
└── EFI/
    ├── BOOT/BOOTx64.efi
    └── OC/
        ├── ACPI/
        ├── Kexts/
        ├── config.plist
        └── ...
```

---

## 3. 首次安装

1. 插上 U 盘，开机按 `F7`（或 `F12`）调出启动菜单。
2. 选择 **U 盘（UEFI）**。
3. 进入 OpenCore 启动菜单，选择 **Install macOS Tahoe**。
4. 跟随安装器完成磁盘分区与安装（过程中会重启数次，每次都在 OpenCore 菜单选择对应项）。
5. 安装完成后，首次进入系统做初始设置。

---

## 4. 把 EFI 装到内置硬盘（脱离 U 盘启动）

安装完成、能正常进入系统后，将 EFI 复制到内置 ESP 分区：

```bash
diskutil list                      # 内置盘通常是 disk0，ESP 为 disk0s1
sudo diskutil mount disk0s1
sudo cp -R /Volumes/EFI/EFI /Volumes/EFI_DISK/   # 目标为内置 ESP 根
```

然后在 BIOS 启动顺序里，把 **OpenCore** 调到第一项，即可脱离 U 盘启动。

> 建议保留一份 U 盘 EFI 作为应急启动盘。

---

## 5. 安装后必做

### 5a. 开启合盖近似睡眠（可选但推荐）

```bash
sudo cp services/nosleep.sh /usr/local/bin/nosleep.sh
sudo chmod 755 /usr/local/bin/nosleep.sh
sudo cp services/com.local.nosleep.plist /Library/LaunchDaemons/
sudo launchctl bootstrap system /Library/LaunchDaemons/com.local.nosleep.plist
```

详见 [`POWER.md`](POWER.md)。

### 5b. 验证加速与设备

```bash
# 核显加速
system_profiler SPDisplaysDataType | grep -i metal      # 应显示 Metal 2
# Wi-Fi / 蓝牙 / 音频 / 电池
system_profiler SPNetworkDataType | head
```

---

## 6. 常见安装问题

见 [`TROUBLESHOOTING.md`](TROUBLESHOOTING.md)。
