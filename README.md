# Dynabook G83/HU · macOS Tahoe Hackintosh

**13.3" 商务本运行 macOS Tahoe (26)。**

面向 **Dynabook G83/HU（TOSHIBA PORTEGE X30L-J）** 的 OpenCore EFI 与定制 WhateverXe 核显驱动。

![macOS](https://img.shields.io/badge/macOS-Tahoe%2026-000000?logo=apple&logoColor=white)
![OpenCore](https://img.shields.io/badge/OpenCore-1.0.x-4B5563)
![GPU](https://img.shields.io/badge/Iris%20Xe-Metal%202-0A84FF)
![License](https://img.shields.io/badge/License-MIT-green)

> i5-1145G7 · Iris Xe (TGL 9A49 / 80EU) · 16 GB · 1920×1080
> 验证系统：**macOS Tahoe 26.7.2 (25G332)**

---

## ⚡ 快速开始

**只需三步，把 `EFI/` 放进 U 盘就能装。**

1. 到 **[Releases](https://github.com/Kansamu216/dynabook-g83-macos-tahoe/releases)** 下载 `G83-EFI-full.tgz`（完整可启动 EFI，含全部 kext）。
2. 解压，把得到的 `EFI/` 文件夹整个拷到 **FAT32 U 盘的 EFI 分区根目录**（U 盘需 GUID 分区表）。
3. 开机按 `F7`/`F12` 选 U 盘启动，进入 OpenCore 安装 macOS。

> ⚠️ 首次使用请用 [GenSMBIOS](https://github.com/corpnewt/GenSMBIOS) 生成**自己的三码**填入 `PlatformInfo → Generic`（仓库内 config 的序列号已置空）。详见 [安装文档](docs/INSTALL.md)。

---

## ✨ 功能状态

| 功能 | 状态 | 功能 | 状态 |
|---|---|---|---|
| 系统安装 / 启动 | ✅ | 电池电量 | ✅ |
| **核显加速 (Metal 2 / GL / 视频硬解)** | ✅ | NVMe 硬盘 | ✅ 原生 |
| 内置屏 1920×1080 | ✅ | USB 端口（定制映射） | ✅ |
| 亮度调节（键 + 滑块） | ✅ | 合盖防睡死（保持运行） | ✅ |
| 音频（扬声器 / 耳机） | ✅ | **HDMI 视频输出** | ⚠️ 无信号 |
| 键盘 / 触控板（多点手势） | ✅ | **雷电协议**（外接显卡/扩展坞） | ⚠️ 不可用 |
| Wi-Fi（Intel） | ✅ | 摄像头画面 | ⚠️ 硬件限制 |
| 蓝牙 | ✅ | 真睡眠 S3 | ⚠️ 固件不支持 |
| 有线网络 | ✅ | | |

> ✅ 可用 · ⚠️ 受限（详见 [已知限制](#-已知限制)）

---

## 🖥 硬件

| 部件 | 型号 |
|---|---|
| 机型 | Dynabook G83/HU（= TOSHIBA PORTEGE X30L-J） |
| CPU | Intel Core i5-1145G7（Tiger Lake-U，4C/8T） |
| 核显 | Intel Iris Xe Graphics（`0x9A49`，80 EU） |
| 内存 | 16 GB |
| 屏幕 | 13.3" 1920×1080 (eDP) |
| 无线 | Intel Wi-Fi + 蓝牙（AirportItlwm / IntelBluetoothFirmware） |
| 有线 | Intel Ethernet（IntelMausi） |
| 音频 | Realtek HDA（AppleALC layout-id 11） |
| 触控板 | ELAN I²C-HID（VoodooI2C） |
| 接口 | 2×Thunderbolt 4 / USB-C、USB-A、HDMI、3.5mm |
| 存储 | NVMe（原生） |

---

## 📦 仓库结构

```
.
├── EFI/OC/                 # 配置与 ACPI（kext 见 Releases 完整包）
│   ├── ACPI/               # 定制 SSDT（11 个）
│   └── config.plist        # 主配置（序列号已脱敏）
├── docs/
│   ├── INSTALL.md          # 安装步骤
│   ├── CONFIG.md           # OpenCore 配置详解
│   ├── KEXTS.md            # kext 清单与作用
│   ├── GRAPHICS.md         # 核显加速 (WhateverXe) 实现
│   ├── POWER.md            # 电源与合盖（防睡死）
│   ├── TROUBLESHOOTING.md  # 常见问题速查
│   └── AI-OPERATIONS.md    # AI / 维护者运维手册
├── services/               # 防睡死服务（launchd）
│   ├── nosleep.sh
│   ├── com.local.keepawake.plist
│   └── com.local.nosleep.plist
├── tools/README.md         # 完整 EFI 获取 / 校验工具
└── README.md
```

> 完整可启动 EFI（含全部 Kexts / Drivers / Resources）体积较大，随 **[Releases](releases)** 发布，不入 git。

---

## 🎯 技术要点

### 核显加速 — WhateverXe
通过 [WhateverXe](https://github.com/b00t0x/WhateverXe)（基于 WhateverGreen 的 Tiger Lake 分支）实现 Metal 2 硬件加速与视频硬解。WEX 运行时 hook 苹果原生 `AppleIntelTGLGraphics` 驱动，因此**与 macOS 版本绑定**——系统大版本更新后需更新或重编译 WEX。详见 [GRAPHICS.md](docs/GRAPHICS.md)。

### 电源 — 防睡死
本机为 Intel Modern Standby 供电模型，传统 S3 睡眠不兼容，进入即挂死。项目提供轻量服务**禁止系统睡眠**，避免合盖/闲置时睡死。详见 [POWER.md](docs/POWER.md)。

---

## ⚠️ 已知限制

| 限制 | 说明 |
|---|---|
| **HDMI 输出无信号** | 系统能识别外接显示器 EDID，但画面不输出（WEX TGL 端口通路限制） |
| **雷电协议不可用** | TGL 集成雷电无 macOS 驱动；USB-C 口可作普通 USB / 充电 |
| **USB-C 扩展坞会导致显示冻结** | 带视频的 USB-C 扩展坞触发 DP Alt Mode，可能卡死内屏（需重启）。**避免使用** |
| **真睡眠 S3 不工作** | 固件 Modern Standby 下 S3 进入挂死；用禁止睡眠（防睡死）替代 |
| **摄像头画面异常** | USB UVC 设备可识别但输出受限 |

---

## 🙏 致谢

- [OpenCorePkg](https://github.com/acidanthera/OpenCorePkg) · [Lilu](https://github.com/acidanthera/Lilu) · [VirtualSMC](https://github.com/acidanthera/VirtualSMC)
- [WhateverXe](https://github.com/b00t0x/WhateverXe) — Tiger Lake 核显加速
- [AirportItlwm](https://github.com/OpenIntelWireless/itlwm) · [VoodooI2C](https://github.com/VoodooI2C/VoodooI2C) · [VoodooPS2](https://github.com/acidanthera/VoodooPS2) · [AppleALC](https://github.com/acidanthera/AppleALC)
- 同底盘参考：[yxb2018/Toshiba-G83-EFI](https://github.com/yxb2018/Toshiba-G83-EFI)

## 📄 许可

配置文件与脚本：**MIT**。各 kext 遵循其上游许可，版权归原作者所有。
