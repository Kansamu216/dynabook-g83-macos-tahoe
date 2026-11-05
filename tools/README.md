# tools

## 完整可启动 EFI 包

仓库的 `EFI/` 目录只包含**配置与 ACPI**（Git 友好、体积小）。包含全部内核扩展（Kexts）的**完整可启动 EFI** 以压缩包形式随 **Releases** 发布：

- 下载最新 Release 中的 `G83-EFI-full.tgz`（或 `EFI-G83-Tahoe.zip`）。
- 解压后得到完整 `EFI/` 文件夹（BOOT + OC，含全部 Kexts / Drivers / Resources）。

### 本地打包（如需自行生成）

在目标 Mac 上，把已配置好的 EFI 打包：

```bash
cd /Volumes/EFI
sudo tar czf G83-EFI-full.tgz \
     --exclude='config.plist.bak*' --exclude='config-*.plist' EFI
```

---

## 制作 / 校验工具

| 工具 | 用途 |
|---|---|
| [OpenCorePkg](https://github.com/acidanthera/OpenCorePkg) | `ocvalidate` 校验 config |
| [GenSMBIOS](https://github.com/corpnewt/GenSMBIOS) | 生成自己的三码 |
| [ProperTree](https://github.com/corpnewt/ProperTree) | 编辑 plist |
| [gibMacOS](https://github.com/corpnewt/gibMacOS) | 下载 macOS 安装器 |

### 校验 config

```bash
ocvalidate EFI/OC/config.plist
```
