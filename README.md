# Dynabook G83/HU — macOS Tahoe (26) Hackintosh

> OpenCore 1.0.x + WhateverXe 定制的黑苹果 EFI，面向 **Dynabook G83/HU（PORTEGE X30L-J）**。
> Intel Core i5-1145G7 · Iris Xe (TGL 9A49 80EU) · 16 GB · 1080p。

---

## 状态一览

| 功能 | 状态 |
|---|---|
| 系统启动 / 安装 | ✅ 完整可用 |
| 核显加速（Metal 2 / GL / 视频解码） | ✅ 可用（WhateverXe） |
| 内置屏 1080p 显示 | ✅ |
| 亮度调节（键盘 + 系统滑块） | ✅ |
| 音频（内置扬声器 / 耳机） | ✅ AppleALC layout 11 |
| 键盘 / 触控板（多点手势） | ✅ VoodooI2C + VoodooPS2 |
| Wi-Fi（Intel 网卡） | ✅ AirportItlwm |
| 蓝牙 | ✅ IntelBluetoothFirmware |
| 有线网络 | ✅ IntelMausi |
| 电池电量显示 | ✅ SMCBatteryManager + ECEnabler |
| NVMe 硬盘 | ✅ 原生支持 |
| USB 端口（含充电/摄像头） | ✅ 定制端口图 |
| HDMI 视频输出 | ⚠️ 无信号（系统可识别外接显示器 EDID，但画面不输出，见下） |
| Thunderbolt / USB4 协议（外接显卡、雷电扩展坞） | ⚠️ 不可用（TGL 集成雷电无 macOS 驱动，USB-C 口可作普通 USB/充电） |
| 摄像头 | ⚠️ 硬件限制（见下） |
| 合盖 / 休眠 | ⚠️ 见「电源与合盖」 |

> 目标系统：**macOS Tahoe 26.7.x**（在 25G332 上验证）。

---

## 硬件

| 部件 | 型号 |
|---|---|
| 机型 | Dynabook G83/HU（= TOSHIBA PORTEGE X30L-J） |
| CPU | Intel Core i5-1145G7（Tiger Lake-U，4C/8T） |
| 核显 | Intel Iris Xe Graphics（Device ID `0x9A49`，80 EU） |
| 内存 | 16 GB |
| 屏幕 | 13.3" 1920×1080 eDP |
| Wi-Fi | Intel 无线网卡（AirportItlwm 驱动） |
| 有线 | Intel 以太网（IntelMausi） |
| 音频 | Realtek HDA（AppleALC layout 11） |
| 触控板 | ELAN I²C-HID（VoodooI2C） |
| 接口 | 2 × Thunderbolt 4 / USB-C（集成 TGL TB4）、USB-A、HDMI、3.5mm |
| 硬盘 | NVMe（原生） |

---

## 目录结构

```
.
├── EFI/                      # 可直接拷到 U 盘 / ESP 的 OpenCore EFI
│   └── OC/
│       ├── ACPI/             # 定制 SSDT
│       ├── Kexts/            # 全部内核扩展（含定制 WhateverXe）
│       ├── config.plist      # 主配置
│       └── ...
├── docs/
│   ├── INSTALL.md            # 安装步骤
│   ├── CONFIG.md             # OpenCore 配置详解（quirks / boot-args / DeviceProperties）
│   ├── KEXTS.md              # kext 清单与作用
│   ├── GRAPHICS.md           # WhateverXe 核显加速实现
│   ├── POWER.md              # 电源与合盖行为、近似睡眠服务
│   └── TROUBLESHOOTING.md    # 常见问题速查
├── services/
│   └── nosleep.sh            # 合盖近似睡眠守护（launchd）
├── tools/
│   └── ...
└── README.md
```

---

## 快速开始

1. 下载本仓库。
2. 把 `EFI/` 文件夹整个拷贝到 **FAT32 格式 U 盘根目录**（U 盘需 GUID 分区表 + EFI 分区）。
3. 开机按启动菜单键（本机 `F7`/`F12`）选 U 盘。
4. 安装 macOS Tahoe。
5. 详细步骤见 [`docs/INSTALL.md`](docs/INSTALL.md)。

---

## 核显加速说明

显核通过 **WhateverXe**（WhateverGreen 的 Tiger Lake 定制分支）驱动，提供完整的 Metal 2 硬件加速与视频硬解。相关实现细节见 [`docs/GRAPHICS.md`](docs/GRAPHICS.md)。

> 更换为其它机型时，`DeviceProperties` 的 `AAPL,ig-platform-id` 与 `device-id` 需按实际核显调整；本机由 WhateverXe 自动匹配 `0x9A49`。

---

## 电源与合盖

本机 BIOS 采用 Intel Modern Standby 供电模型。为在 macOS 下获得稳定的合盖体验，本项目附带一个轻量守护服务（`services/nosleep.sh`），实现：**合盖熄屏、开盖即亮、系统保持运行不中断**。

详见 [`docs/POWER.md`](docs/POWER.md)。

---

## 致谢与上游

- [OpenCorePkg](https://github.com/acidanthera/OpenCorePkg)
- [Lilu](https://github.com/acidanthera/Lilu) / [VirtualSMC](https://github.com/acidanthera/VirtualSMC) / [WhateverGreen](https://github.com/acidanthera/WhateverGreen)
- [WhateverXe](https://github.com/b00t0x/WhateverXe)（Tiger Lake 加速）
- [AirportItlwm](https://github.com/OpenIntelWireless/itlwm)
- [VoodooI2C](https://github.com/VoodooI2C/VoodooI2C) / [VoodooPS2](https://github.com/acidanthera/VoodooPS2)
- 同底盘参考：[yxb2018/Toshiba-G83-EFI](https://github.com/yxb2018/Toshiba-G83-EFI)

## 许可

配置与脚本部分：MIT。各 kext 遵循其上游许可。
