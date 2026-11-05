# Kext 清单

本 EFI 加载的内核扩展及作用。`启用状态` 与 `config.plist → Kernel → Add` 一致。

---

## 核心依赖

| Kext | 版本 | 启用 | 作用 |
|---|---|---|---|
| Lilu | 1.7.2 | ✅ | 内核补丁框架，所有插件的前置 |
| VirtualSMC | 1.3.8 | ✅ | SMC 模拟（温度/传感器基础） |

---

## 显卡

| Kext | 版本 | 启用 | 作用 |
|---|---|---|---|
| **WhateverXe** | 0.7.0 | ✅ | **Tiger Lake 核显加速主驱动**（详见 GRAPHICS.md） |
| WhateverGreen | 1.7.2 | ❌ | 通用显卡补丁（本机由 WhateverXe 接管，禁用避免冲突） |
| NootedGreen | 1.0.0 | ❌ | 备用 iGPU 驱动（未使用） |

---

## 音频

| Kext | 版本 | 启用 | 作用 |
|---|---|---|---|
| AppleALC | 1.9.8 | ✅ | 音频编解码（layout 11） |
| SimpleHDA | 1.0.0 | ✅ | HDA 辅助 |

---

## 网络

| Kext | 版本 | 启用 | 作用 |
|---|---|---|---|
| AirportItlwm | 2.4.0 | ✅ | Intel Wi-Fi（原生 Airport 接口） |
| IntelMausi | 1.0.7 | ✅ | Intel 有线网卡 |
| IntelBluetoothFirmware | 2.5.1 | ✅ | Intel 蓝牙固件加载 |
| IntelBTPatcher | 2.5.1 | ✅ | Intel 蓝牙补丁 |
| BlueToolFixup | 2.7.3 | ✅ | 蓝牙协议修正 |

---

## 输入设备

| Kext | 版本 | 启用 | 作用 |
|---|---|---|---|
| VoodooI2C（+Services/GPIO/Input） | 2.9.1 | ✅ | I²C 触控板基础 |
| VoodooI2CHID | 1.0 | ✅ | I²C-HID 触控板（多点手势） |
| VoodooPS2Controller（+Keyboard/Mouse/Trackpad） | 2.3.8 | ✅ | PS2 键盘/触控板 |
| BrightnessKeys | — | ✅ | 键盘亮度快捷键 |

---

## 电池与传感器

| Kext | 版本 | 启用 | 作用 |
|---|---|---|---|
| SMCBatteryManager | 1.3.8 | ✅ | 电池电量 |
| SMCProcessor | 1.3.8 | ✅ | CPU 温度传感器 |
| SMCSuperIO | 1.3.8 | ✅ | 风扇/电压传感器（只读） |
| ECEnabler | 1.0.4 | ✅ | 扩展 EC 读取（电池字段） |
| SMCLightSensor | 1.3.9 | ❌ | 光感（本机不需要） |

---

## USB

| Kext | 版本 | 启用 | 作用 |
|---|---|---|---|
| USBToolBox | — | ✅ | USB 端口定制框架 |
| UTBMap | 1.1 | ✅ | **本机 USB 端口映射图** |
| XHCI-unsupported | 0.9.2 | ✅ | 非原生 XHCI 控制器 |
| UTBDefault | 1.0 | ❌ | 通用端口图（本机用 UTBMap） |

---

## 其它

| Kext | 版本 | 启用 | 作用 |
|---|---|---|---|
| AMFIPass | 1.4.1 | ✅ | AMFI 兼容层 |
| NVMeFix | 1.1.4 | ✅ | NVMe 电源/兼容修复 |
| RestrictEvents | 1.1.7 | ✅ | 屏蔽非必要事件（提升稳定性） |
| NoTouchID | 1.0.3 | ✅ | 屏蔽无指纹的 Touch ID 提示 |
| CpuTopologyRebuild | 2.0.2 | ❌ | CPU 拓扑重建（未使用） |
| PC711Probe | 1.8.1 | ❌ | 特定 NVMe 探测（Tahoe 原生支持，无需） |

---

## 加载顺序（config.plist 中的排列）

Lilu 必须最先；随后图形、音频、网络、输入、传感、USB 等。修改顺序时保持 **Lilu → 其它插件** 的依赖关系。
