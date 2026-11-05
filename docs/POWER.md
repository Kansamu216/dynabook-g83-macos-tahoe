# 电源与合盖行为

> [← 返回 README](../README.md) · [安装](INSTALL.md) · [配置](CONFIG.md) · [排错](TROUBLESHOOTING.md)

本机采用 Intel **Modern Standby** 供电模型（ACPI 中可见 `PEPD`/`INT33A1`）。macOS 的传统睡眠路径与该模型不兼容，**进入 S3 深度睡眠会挂死**（黑屏、唤不醒、需强制断电）。

因此本项目采用**禁止睡眠**方案：让系统保持运行不进入 S3，从而避免睡死。

---

## 方案（纯防睡死，已实测有效）

| 项 | 作用 |
|---|---|
| `pmset -a disablesleep 1` | 禁止系统睡眠（核心） |
| `com.local.keepawake`（launchd 托管 `caffeinate -ims`） | 阻止 idle/磁盘/系统睡眠，launchd KeepAlive 保证常驻 |
| `com.local.nosleep`（launchd 托管 `nosleep.sh`） | 每 5 秒检查并保活 `disablesleep=1` |

> ⚠️ **重要：不要用 `pmset displaysleepnow` 主动关屏。** 本机核显在合盖再开盖时，若显示曾被主动关闭，会触发 eDP `DBUF power up timeout` → `FB0 is not enabled` → 黑屏无法恢复。本方案**不发送任何显示命令**，让 macOS 自然管理显示电源。

---

## 预期效果

- 合盖/闲置时**系统不进入睡眠、不睡死**（保持运行，SSH/后台任务不中断）
- 屏幕是否熄灭由 macOS 自然处理；合盖后通常会自动熄屏
- **代价**：合盖不会真正省电/休眠（因为没睡），这是本机固件限制下的取舍

---

## 安装

```bash
# 1. 脚本
sudo mkdir -p /usr/local/bin
sudo cp services/nosleep.sh /usr/local/bin/nosleep.sh
sudo chmod 755 /usr/local/bin/nosleep.sh

# 2. 两个 launchd 服务
sudo cp services/com.local.keepawake.plist /Library/LaunchDaemons/
sudo cp services/com.local.nosleep.plist   /Library/LaunchDaemons/
sudo chown root:wheel /Library/LaunchDaemons/com.local.*.plist
sudo chmod 644 /Library/LaunchDaemons/com.local.*.plist

# 3. 加载
sudo launchctl bootstrap system /Library/LaunchDaemons/com.local.keepawake.plist
sudo launchctl bootstrap system /Library/LaunchDaemons/com.local.nosleep.plist

# 4. 立即生效
sudo pmset -a disablesleep 1 sleep 0 hibernatemode 0 standby 0 powernap 0
```

---

## 状态检查

```bash
sudo launchctl print system/com.local.keepawake | grep -E 'state|pid'   # 应 running
sudo launchctl print system/com.local.nosleep   | grep -E 'state|pid'   # 应 running
pgrep -fl 'caffeinate -ims'                                             # 应有进程
pmset -g | grep SleepDisabled                                          # 应为 1
```

---

## 卸载

```bash
sudo launchctl bootout system /Library/LaunchDaemons/com.local.keepawake.plist
sudo launchctl bootout system /Library/LaunchDaemons/com.local.nosleep.plist
sudo rm /Library/LaunchDaemons/com.local.keepawake.plist /Library/LaunchDaemons/com.local.nosleep.plist
sudo rm /usr/local/bin/nosleep.sh
sudo pmset -a disablesleep 0
```
