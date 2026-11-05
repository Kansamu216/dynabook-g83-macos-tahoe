# Changelog

本项目遵循语义化版本记录。

## [v1.0] — 2026-11-05

首个公开版本。

### 初始发布
- **OpenCore EFI**：面向 Dynabook G83/HU（i5-1145G7 / Iris Xe 9A49），验证于 macOS Tahoe 26.7.2 (25G332)。
- **核显加速**：集成 WhateverXe 定制版，Tiger Lake 80EU，Metal 2 / GL / 视频硬解。
- **全套驱动**：Wi-Fi / 蓝牙 / 音频 / 触控板 / 电池 / NVMe / USB 定制端口图。
- **11 个定制 SSDT**：ACPI 适配。

### 电源
- 合盖近似睡眠方案（launchd 双服务）：合盖熄屏、开盖 1 秒内恢复、系统保持运行。
  - `com.local.keepawake`：launchd 托管 caffeinate 防止系统睡眠。
  - `com.local.nosleep`：保活 `disablesleep=1`。
  - 不使用 `displaysleepnow` 主动关屏（避免 eDP DBUF 电源问题导致黑屏）。

### 文档
- 安装 / 配置 / kext / 核显 / 电源 / 排错 / AI 运维手册 共 7 份文档。

### 已知限制
- HDMI 输出无信号、雷电协议不可用、USB-C 视频扩展坞会冻结显示、S3 真睡不支持、摄像头画面受限。
