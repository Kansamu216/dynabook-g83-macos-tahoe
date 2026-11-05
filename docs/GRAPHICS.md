# 核显加速：WhateverXe

> [← 返回 README](../README.md) · [配置](CONFIG.md) · [Kexts](KEXTS.md) · [电源](POWER.md)


本机核显（Intel Iris Xe, Tiger Lake 9A49）通过 **WhateverXe (WEX)** 驱动实现完整的 Metal 2 硬件加速。

---

## 组成

WhateverXe 是 Lilu 插件，由两部分配合工作：

| 组件 | 说明 |
|---|---|
| `WhateverXe.kext` | 内核补丁插件（本仓库 `EFI/OC/Kexts/` 内） |
| `AppleIntelTGLCompat.kext` | 图形兼容层（对应用户态 Graphics 包，随 WEX 一同提供） |

> WEX 上游：[b00t0x/WhateverXe](https://github.com/b00t0x/WhateverXe) + [WhateverXe Graphics](https://github.com/b00t0x/WhateverXe-Graphics)。

---

## 本机适配

WEX 需要与核显的物理配置（EU 数、GT 分 bank）匹配。本机 i5-1145G7 / 80EU / 9A49 的适配方式：

- 编译时套用 **6-bank patch**，使 WEX 正确识别 80 EU、GT2 的六个 bank 布局。
- 运行时由 WEX 自动匹配 `device-id 0x9A49`，向 IGPU 注入：
  - `device-id` = `0x9A49`
  - `AAPL,ig-platform-id` = `0x9A49`（`0000499A`）

因此 `config.plist → DeviceProperties` 中**无需手填** `AAPL,ig-platform-id`，避免与 WEX 自动匹配冲突。

---

## 关键 boot-args

```
-allow3d -disablegfxfirmware -wex-no-bcs-tlb amfi_get_out_of_my_way=1
```

| 参数 | 作用 |
|---|---|
| `-allow3d` | 开启 3D 加速 |
| `-disablegfxfirmware` | 关闭 GuC 固件，改由主机接管命令提交（WEX 运行时必需） |
| `-wex-no-bcs-tlb` | 跳过 BCS 引擎相关 TLB/信号量挂钩，提升块拷贝路径稳定性 |
| `amfi_get_out_of_my_way=1` | 放宽 AMFI 库校验，使视频硬解子驱动可被加载 |

---

## 配套：视频硬解

视频硬件解码由 `AppleIntelTGLGraphicsVADriver` 提供。为使该子驱动在开启 AMFI 库校验的系统上可正常加载，需要 `amfi_get_out_of_my_way=1`（见上）。

---

## 验证加速是否生效

```bash
# 1) Metal 支持
system_profiler SPDisplaysDataType | grep -i "Metal"

# 2) 显示驱动 bundle
ioreg -lw0 -r -c IntelAccelerator | grep -E 'IOGLBundleName|MetalPluginName'
# 期望：
#   IOGLBundleName      = AppleIntelTGLGraphicsGLDriver
#   MetalPluginName     = AppleIntelTGLGraphicsMTLDriver

# 3) 视频硬解
system_profiler SPDisplaysDataType | grep -i "VRAM"
```

若以上均正常，说明核显加速链路完整（OpenGL / Metal / 视频解码）。

---

## 自编译 WhateverXe（可选）

如需自行编译适配版本：

1. 克隆 [WhateverXe](https://github.com/b00t0x/WhateverXe) 与 [Lilu](https://github.com/acidanthera/Lilu)、[MacKernelSDK](https://github.com/acidanthera/MacKernelSDK)。
2. 合入本机所需的 bank 适配 patch。
3. 使用仓库自带的 `tools/build.py` 构建：

```bash
python3 tools/build.py --release --sdk MacKernelSDK --lilu Lilu.kext
```

4. 产物 `WhateverXe.kext` 放入 `EFI/OC/Kexts/`。

---

## 显示参数（本机实测）

| 项 | 值 |
|---|---|
| 分辨率 | 1920 × 1080 |
| 刷新率 | 60 Hz |
| 色深 | 30-bit (ARGB2101010) |
| VRAM（动态） | 1536 MB |
| Metal | Metal 2 |

---

## 外接显示（HDMI / USB-C）

> ⚠️ **实测状态：HDMI 输出无信号。**
> 插入 HDMI 显示器后，系统能够识别外接显示器（读取到 EDID、显示 2560×1600@60Hz、Online=Yes），但在物理屏幕上没有画面输出。即握手成功、像素流未输出。这是本机 WEX HDMI 通路的已知限制。

- **HDMI**：系统可识别外接显示器但无画面。暂不可用于实际输出。
- **多屏**：当前仅内置屏可正常显示。
- 若后续更换 WEX 版本或调整 HDMI 通路，可重新验证。

> 内屏（1920×1080）显示、亮度、Metal 加速均正常，不受此影响。
