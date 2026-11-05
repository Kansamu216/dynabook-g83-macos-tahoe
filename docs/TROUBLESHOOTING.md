# 常见问题速查

> [← 返回 README](../README.md) · [安装](INSTALL.md) · [配置](CONFIG.md) · [电源](POWER.md)


---

## 启动

**卡在 Apple Logo / 进度条不动**
- 检查 `Kernel → Emulate` 的 `Cpuid1Data` 是否已填（见 CONFIG.md）。
- 确认 `Booter → Quirks` 与 CONFIG.md 一致。

**OC 菜单不出现，直接进原系统**
- BIOS 启动顺序把 U 盘 / OpenCore 调到第一。
- Secure Boot 必须 Disabled。

---

## 显示 / 核显

**进入系统后无加速、只有软件渲染**
- 确认 `Kexts/WhateverXe.kext` 已启用，`WhateverGreen.kext` / `NootedGreen.kext` 已禁用。
- 确认 boot-args 含 `-allow3d -disablegfxfirmware`。
- 验证：`system_profiler SPDisplaysDataType | grep -i metal` 应显示 Metal 2。

**花屏 / 黑屏**
- 确认显示配置与 GRAPHICS.md 一致（1920×1080 / 60Hz / 30-bit）。

---

## 视频

**全屏播放视频退出 / 卡顿**
- 确认 boot-args 含 `amfi_get_out_of_my_way=1`（视频硬解子驱动加载需要）。

---

## 输入

**触控板无反应 / 无手势**
- 确认 `VoodooI2C` 及 `VoodooI2CHID` 启用。
- 确认 boot-args 含 `-vi2c-force-polling`。

**键盘亮度键无效**
- 确认 `BrightnessKeys.kext` 启用。

---

## 网络

**Wi-Fi 不出现**
- 确认 `AirportItlwm.kext` 启用、`itlwm.kext` 禁用。
- 确认 `AirportItlwm` 版本与 macOS 版本匹配（Tahoe 26 用对应版本）。

**蓝牙不可用**
- 确认 `IntelBluetoothFirmware` + `IntelBTPatcher` + `BlueToolFixup` 三者均启用。

---

## 电池

**不显示电量 / 显示异常**
- 确认 `SMCBatteryManager` + `ECEnabler` 启用。

---

## USB

**部分 USB 口不工作 / 充电口异常**
- 确认 `USBToolBox` + `UTBMap` 启用（本机端口图），`UTBDefault` 禁用。
- `XHCI-unsupported.kext` 启用。

---

## 电源 / 合盖

**合盖后黑屏、开盖不恢复**
- 确认已安装 `com.local.keepawake` + `com.local.nosleep` 两个服务（见 POWER.md）。
- 确认 `pmset -g | grep SleepDisabled` 为 `1`、`pgrep -f 'caffeinate -ims'` 有进程。
- ⚠️ **不要用 `pmset displaysleepnow` 主动关屏**——本机核显在合盖再开盖时会因主动关屏触发 `DBUF power up timeout` → `FB0 is not enabled` → 黑屏无法恢复。让 macOS 自然管理显示电源即可（实测开盖 1 秒内恢复）。

---

## 外接显示 / 雷电 / USB-C

**⚠️ 插入带视频的 USB-C 扩展坞会导致显示冻结（重要）**
- 现象：插入带 HDMI/视频输出的 USB-C 扩展坞后，**即使不接 HDMI 线**，USB-C 口也会触发 DP Alt Mode 端口协商，可能导致整个显示管道卡死（内屏冻结、`WindowServer [Watchdog]: display stuck`）。系统内核仍存活（SSH 可连），但画面冻结，需重启恢复。
- 原因：本机 USB-C(TC) 端口的 DP Alt Mode 端口协商在 WEX 下不稳定，会拖累内屏显示管道。
- **建议**：不要使用带视频功能的 USB-C 扩展坞；如需扩展口，优先用机器自带 USB-A 口，或使用不触发 DP Alt Mode 的纯数据扩展坞（仍不保证）。

**雷电扩展坞 / 外接显卡 / 雷电显示器不工作**
- 本机 Thunderbolt 4 控制器集成于 Tiger Lake CPU，macOS 无对应驱动，雷电协议功能不可用。
- 雷电口的 **USB-C 数据/充电** 正常（走 XHCI）。

**HDMI 无输出（系统识别到显示器但屏幕无信号）**
- 本机 HDMI 通路当前无画面输出：`system_profiler SPDisplaysDataType` 可能列出外接 Monitor（2560×1600，Online），但物理屏幕不显示。
- 这是本机 WEX HDMI 通路的已知限制，暂不可用。内屏显示正常。
- 当前本机无可靠的外接视频输出方案（HDMI 无信号、雷电协议无驱动、USB-C 扩展坞会冻结显示）。

---

## 摄像头

**摄像头画面异常**
- 内置摄像头为 USB UVC 设备，可被系统识别，但画面输出受硬件限制。
- 建议使用外接 USB 摄像头。

---

## 通用排查

```bash
# OpenCore 版本
nvram 4D1FDA02-38C7-4A6A-9CC6-4BCCA8B30102:opencore-version

# 已加载 kext
kmutil showloaded | grep -iE 'lilu|virtualsmc|whateverxe'

# 显卡状态
ioreg -lw0 -r -c IntelAccelerator | head
```

- 修改 `config.plist` 后用 `ocvalidate` 校验。
- 参考 OpenCore 官方文档与 Dortania 指南。
