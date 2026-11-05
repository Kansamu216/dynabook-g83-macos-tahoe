# OpenCore 配置详解

> [← 返回 README](../README.md) · [安装](INSTALL.md) · [Kexts](KEXTS.md) · [核显](GRAPHICS.md) · [电源](POWER.md)


本机使用的 OpenCore 配置要点。适用于 **i5-1145G7 / Tiger Lake-U**。

---

## 版本与环境

| 项 | 值 |
|---|---|
| OpenCore | 1.0.x（RELEASE） |
| 目标系统 | macOS Tahoe 26 |
| SMBIOS | `MacBookPro16,2` |

> SMBIOS 的序列号 / MLB / SystemUUID / ROM 为每台机器唯一，**未包含在本仓库**。首次使用请用 `GenSMBIOS` 生成自己的三码并填入 `PlatformInfo → Generic`。

---

## Boot-args

```
keepsyms=1 watchdog=0 -vi2c-force-polling alcid=11 -allow3d -disablegfxfirmware -wex-no-bcs-tlb amfi_get_out_of_my_way=1
```

| 参数 | 作用 |
|---|---|
| `keepsyms=1` | 保留内核符号（便于排错） |
| `watchdog=0` | 关闭看门狗 |
| `-vi2c-force-polling` | VoodooI2C 强制轮询模式（本机触控板） |
| `alcid=11` | AppleALC 音频布局 = 11 |
| `-allow3d` | 允许 3D 加速 |
| `-disablegfxfirmware` | 关闭 GuC 固件，由主机接管提交（WhateverXe 运行时需要） |
| `-wex-no-bcs-tlb` | 跳过 BCS 相关 TLB/信号量挂钩（提升块拷贝稳定性） |
| `amfi_get_out_of_my_way=1` | 放宽 AMFI 库校验（视频硬解驱动签名需要） |

---

## Kernel → Emulate

| 项 | 值 | 说明 |
|---|---|---|
| Cpuid1Data | `55060A00 00000000 00000000 00000000` | CPUID 伪装为 Comet Lake |
| Cpuid1Mask | `FFFFFFFF 00000000 00000000 00000000` | 仅伪装家族/型号 |

---

## Kernel → Quirks

| 项 | 值 |
|---|---|
| AppleXcpmCfgLock | `true` |
| AppleXcpmExtraMsrs | `true` |
| DisableIoMapper | `true` |
| PowerTimeoutKernelPanic | `true` |
| XhciPortLimit | `true` |

---

## Booter → Quirks

| 项 | 值 |
|---|---|
| AvoidRuntimeDefrag | `true` |
| EnableWriteUnprotector | `true` |
| SetupVirtualMap | `true` |
| SyncRuntimePermissions | `true` |
| EnableSafeModeSlide | `true` |
| ProtectMemoryRegions | `false` |
| RebuildAppleMemoryMap | `false` |
| DevirtualiseMmio | `false` |

---

## ACPI → Quirks

| 项 | 值 |
|---|---|
| ResetLogoStatus | `true` |
| FadtEnableReset | `false` |
| NormalizeHeaders | `false` |
| RebaseRegions | `false` |
| SyncTableIds | `false` |

---

## ACPI → Add（加载的 SSDT）

| 文件 | 启用 | 作用 |
|---|---|---|
| `SSDT-ALS0.aml` | ✅ | 环境光传感器 |
| `SSDT-SBUS.aml` | ✅ | SMBus 设备 |
| `SSDT-PNLF.aml` | ✅ | 背光控制 |
| `SSDT-RTCAWAC.aml` | ✅ | RTC 时钟 |
| `SSDT-USB-Reset.aml` | ✅ | USB 复位 |
| `SSDT-USBX.aml` | ✅ | USB 供电属性 |
| `SSDT-XOSI.aml` | ✅ | 操作系统判定 |
| `SSDT-TPAD.aml` | ✅ | 触控板 |
| `SSDT-GPI0-HID.aml` | ✅ | GPIO 触控板（HID） |
| `SSDT-PLUG-ALT.aml` | ❌ | CPU 电源管理（备用，默认禁用） |
| `SSDT-GPI0.aml` | ❌ | GPIO 备用（默认禁用） |

> `config.plist` 中保留了若干备用 SSDT 条目（Enabled=false），供不同 BIOS/固件组合时启用。

---

## DeviceProperties

| 路径 | 键 | 值 |
|---|---|---|
| `PciRoot(0x0)/Pci(0x1F,0x3)` | `layout-id` | `0B000000`（音频 layout 11） |
| `PciRoot(0x0)/Pci(0x2,0x0)` | `model` | `Intel Iris Xe Graphics` |
| | `hda-gfx` | `onboard-1` |
| | `AAPL,slot-name` | `built-in` |
| | `built-in` | `00` |

> 核显的 `AAPL,ig-platform-id`（`0000499A`）与 `device-id`（`499A0000`）由 WhateverXe 在运行时匹配注入，`DeviceProperties` 中无需手填。详见 [`GRAPHICS.md`](GRAPHICS.md)。

---

## Misc → Security

| 项 | 值 |
|---|---|
| SecureBootModel | `Disabled` |
| Vault | `Optional` |
| DmgLoading | `Any` |

---

## 校验

修改 `config.plist` 后务必用 `ocvalidate` 校验：

```bash
ocvalidate EFI/OC/config.plist
```
