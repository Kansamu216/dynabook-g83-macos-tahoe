# AI / 维护者运维手册

> [← 返回 README](../README.md) · [配置](CONFIG.md) · [电源](POWER.md) · [排错](TROUBLESHOOTING.md)


本文件面向**接手此项目的 AI 助手或维护者**，提供可直接执行的诊断命令、判定逻辑与标准操作流程。所有命令为本机实测可用。

> 约定：`$ ` 开头为 shell 命令（在目标 Mac 上执行）。路径以 OpenCore EFI 挂载点 `/Volumes/EFI/EFI/OC` 为准。

---

## 0. 环境探查（先跑这几条，建立基线）

```bash
sw_vers                                              # macOS 版本
sysctl -n machdep.cpu.brand_string; sysctl -n hw.ncpu
sysctl -n kern.bootargs                              # 当前 boot-args
kmutil showloaded | grep -iE 'lilu|virtualsmc|whateverxe'   # 关键 kext 是否加载
system_profiler SPDisplaysDataType | grep -iE 'Chipset|Metal|Resolution'
pmset -g | grep -iE 'SleepDisabled| sleep '
```

判定基线（正常时应满足）：
- Metal 显示 `Metal 2`
- `kmutil showloaded` 含 `org.b00t0x.WhateverXe`、`as.vit9696.Lilu`、`as.vit9696.VirtualSMC`
- boot-args 含 `-allow3d -disablegfxfirmware -wex-no-bcs-tlb amfi_get_out_of_my_way=1`

---

## 1. 修改 config.plist 的标准流程

```bash
# 1) 挂载内置 ESP
sudo diskutil mount disk0s1

# 2) 修改前备份（务必）
sudo cp /Volumes/EFI/EFI/OC/config.plist \
        /Volumes/EFI/EFI/OC/config.plist.bak-$(date +%H%M%S)

# 3) 修改（用 PlistBuddy 或 plistlib）
/usr/libexec/PlistBuddy -c 'Print :NVRAM:Add:7C436110-AB2A-4BBB-A880-FE41995C9F82:boot-args' /Volumes/EFI/EFI/OC/config.plist

# 4) 校验语法（必须 OK）
plutil -lint /Volumes/EFI/EFI/OC/config.plist

# 5) 有 ocvalidate 则再校验
ocvalidate /Volumes/EFI/EFI/OC/config.plist

# 6) 重启生效
sudo shutdown -r now
```

**boot-args 修改示例**（追加参数）：

```bash
G=7C436110-AB2A-4BBB-A880-FE41995C9F82
CUR=$(/usr/libexec/PlistBuddy -c "Print :NVRAM:Add:$G:boot-args" /Volumes/EFI/EFI/OC/config.plist)
sudo /usr/libexec/PlistBuddy -c "Set :NVRAM:Add:$G:boot-args $CUR <新参数>" /Volumes/EFI/EFI/OC/config.plist
```

---

## 2. 部署 / 更换 kext 的标准流程

```bash
sudo diskutil mount disk0s1
K=/Volumes/EFI/EFI/OC/Kexts/WhateverXe.kext/Contents/MacOS/WhateverXe
sudo cp "$K" /Users/$USER/WEX-backup/WhateverXe-$(date +%H%M%S).bin   # 备份现有
sudo cp <新kext> "$K"
sudo chown root:wheel "$K"; sudo chmod 755 "$K"
shasum -a 256 "$K" | cut -c1-16        # 记下部署版本
sudo shutdown -r now
```

> kext 的 `config.plist → Kernel → Add` 需 `Enabled=true` 才会加载。改 kext 版本不需要改 config，但换文件名/新增 kext 要同步 `Kernel → Add`。

---

## 3. 症状 → 诊断 → 修复 对照表

| 症状 | 诊断命令 | 判定 | 修复 |
|---|---|---|---|
| 开机卡 Apple Logo / 进度条 | — | 配置/quirks 不对 | 见 CONFIG.md 的 Booter/Kernel quirks、Cpuid1Data |
| 无加速、软件渲染 | `system_profiler SPDisplaysDataType \| grep -i metal` | 无 `Metal 2` | 确认 WhateverXe 启用、WhateverGreen/NootedGreen 禁用、`-allow3d -disablegfxfirmware` |
| 全屏视频崩溃 | — | AMFI 拒绝 VA 驱动 | boot-args 加 `amfi_get_out_of_my_way=1` |
| 反复卡死/GPU 重启 | `log show --last 5m \| grep -i 'BCS Ring'` | BCS Ring busy | boot-args 含 `-wex-no-bcs-tlb` |
| 触控板无反应 | `ioreg -l \| grep -c VoodooI2C` | 驱动未加载 | 启用 VoodooI2C/HID，boot-args 含 `-vi2c-force-polling` |
| 部分 USB 口不工作 | `ioreg -lw0 -r -c AppleUSBXHCI` | 端口图未生效 | 启用 USBToolBox+UTBMap，禁用 UTBDefault |
| Wi-Fi 不出现 | `system_profiler SPNetworkDataType` | 无 AirPort | 启用 AirportItlwm、禁用 itlwm |
| 蓝牙不可用 | `system_profiler SPBluetoothDataType` | State 非 On | 启用 IntelBluetoothFirmware+IntelBTPatcher+BlueToolFixup |
| 不显示电量 | `pmset -g batt` | 无电量信息 | 启用 SMCBatteryManager+ECEnabler |
| 合盖黑屏需重启 | `pmset -g \| grep SleepDisabled` | 未装 nosleep 服务 | 安装 services/nosleep.sh（见 POWER.md） |
| 点睡眠挂死 | 见 §4 | 固件 S3 不兼容 | 不要试图修 S3，用 nosleep 方案 |

---

## 4. 电源 / 睡眠（重要：不要试图修真睡眠）

**结论**：本机固件为 Intel Modern Standby 模型，传统 S3 进入会挂死（`Sleep Wake failure in EFI`, `0x1f`），属固件层限制，**不要尝试修复 S3 睡眠**。

保持"近似睡眠"即可：
```bash
pmset -g | grep SleepDisabled           # 应为 1
launchctl print system/com.local.nosleep | grep state   # 应为 running
```

若合盖黑屏：重装 nosleep 服务（`/usr/local/bin` 可能不存在，需 `sudo mkdir -p /usr/local/bin`）。

---

## 5. 系统更新后核显失效？（重中之重）

**原理**：WhateverXe 不是独立显卡驱动，而是**运行时 hook 苹果原生 `AppleIntelTGLGraphics` / `AppleIntelTGLGraphicsFramebuffer` kext 的二进制**（打补丁 + 重定向）。因此：

- **macOS 每次小版本/大版本更新，只要苹果改动了这些原生 kext 的二进制布局/符号/偏移，WEX 的 hook 就可能失配** → 核显加速失效、花屏、或无加速。
- WEX 与 macOS 的适配是**按版本（甚至按 build）绑定的**。参见 WEX README 的兼容表：

  | macOS | 所需 WEX 版本 |
  |---|---|
  | Big Sur | 11.7.11 |
  | Monterey | 12.7.6 |
  | Ventura | 13.7.8 |
  | Sonoma | 14.8.9 |
  | Sequoia | 15.8.x |
  | Tahoe | 26.7 或更新 |

  > "Sequoia 和 Tahoe 接受同 OS 家族内的兼容更新。未来苹果的改动可能需要更新 WEX 或 Graphics。"

- 本机验证于 **Tahoe 26.7.2 (build 25G332)**。

**系统更新后必须做的事**：

1. **升级前**：备份当前可用 EFI（`sudo cp -R /Volumes/EFI/EFI <备份>`），记住当前 WEX 版本。
2. **升级后首次进系统**：若核显加速失效（`system_profiler SPDisplaysDataType | grep -i metal` 无 Metal 2）：
   - 拉取**与当前 macOS 版本匹配**的最新 [WhateverXe](https://github.com/b00t0x/WhateverXe/releases) + [WhateverXe Graphics](https://github.com/b00t0x/WhateverXe-Graphics/releases)。
   - 或**重新编译** WEX 源码（见下）。
3. **重新编译 WEX**（当上游无现成匹配版时）：

   ```bash
   # 依赖：Lilu.kext + MacKernelSDK（放同级目录）
   cd <WhateverXe 源码>
   python3 tools/build.py --release --sdk MacKernelSDK --lilu Lilu.kext
   # 产物 WhateverXe.kext 放入 EFI/OC/Kexts/，重启
   ```

4. **验证**：Metal 2 出现、`ioreg -l -r -c IntelAccelerator | grep Metal` 正常、视频硬解不崩。

**⚠️ 更新前务必留好能启动的旧 EFI / U 盘救援**，否则新系统 + 不匹配的 WEX 可能开不了机。

**判断 hook 是否失配**：`log show --last 5m | grep igfx` 若出现 WEX 的 patch/route 失败、或加速直接消失，多为版本失配。

---

## 6. 已知不可用功能（不要浪费时间尝试）

| 功能 | 原因 |
|---|---|
| 真睡眠 S3 | 固件 Modern Standby，S3 进入挂死 |
| HDMI 输出无信号 | WEX TGL 端口 probe 未覆盖本机 DDI1（系统识别 EDID 但无画面） |
| USB-C 扩展坞致显示冻结 | 带视频的 USB-C 扩展坞触发 DP Alt Mode，端口协商不稳会卡死整个显示管道（内屏冻结，需重启）。**不要插带视频的扩展坞。** |
| 雷电协议（外接显卡/扩展坞） | TGL 集成雷电无 macOS 驱动（USB-C 数据/充电正常） |
| 内置摄像头画面 | USB UVC 设备识别但输出异常（硬件限制） |
| 风扇转速读取/控制 | SMC 无 fan key，EC 硬件控制 |

---

## 6. 回滚与救援

```bash
# 方案1: 用 boot-arg 完全禁用 WEX（核显回退），排查是否 WEX 引起
#   在 boot-args 加 -wexoff

# 方案2: 恢复 config 备份
sudo cp /Volumes/EFI/EFI/OC/config.plist.bak-<时间> /Volumes/EFI/EFI/OC/config.plist

# 方案3: U盘救援（推荐常备）
#   把仓库 Release 的 EFI 解压到 FAT32 U盘 EFI 分区，开机 F7/F12 选 U盘
```

**开不了机时**：插 U 盘 EFI 启动 → 从 U 盘系统里恢复内置盘 config/kext。

---

## 7. 部署后验证清单

- [ ] `plutil -lint config.plist` 通过
- [ ] `kmutil showloaded | grep WhateverXe` 出现
- [ ] `system_profiler SPDisplaysDataType` 显示 Metal 2
- [ ] Wi-Fi/蓝牙/音频/电池/触控板 正常
- [ ] `pmset -g | grep SleepDisabled` = 1，合盖关屏不重启
- [ ] 内屏 1920×1080 正常

---

## 8. 常用诊断命令速查

```bash
# kext 加载
kmutil showloaded | grep -iE 'lilu|virtualsmc|whateverxe|voodoo'

# 显卡 / 加速
ioreg -lw0 -r -c IntelAccelerator | grep -iE 'Metal|IOGL|IOPowerManagement'
system_profiler SPDisplaysDataType

# 显示端口 / 连接
ioreg -lw0 -r -c AppleIntelFramebuffer | grep -E 'connector-type|AppleDisplay'

# 睡眠状态
pmset -g; pmset -g assertions | grep -i prevent

# 内核日志（显示相关）
log show --last 10m --predicate 'senderImagePath CONTAINS "TGLGraphicsFramebuffer"' | tail -30

# SMBIOS 型号
ioreg -lw0 -r -c IOPlatformExpertDevice | grep -i product-name
```
