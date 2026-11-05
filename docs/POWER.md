# 电源与合盖行为

本机采用 Intel **Modern Standby** 供电模型（ACPI 中可见 `PEPD`/`INT33A1`）。macOS 的传统睡眠路径与该模型不兼容，进入 S3 会挂死。因此本项目采用 **keep-awake + 自然熄屏** 的方案，实现「合盖熄屏保持运行、开盖即恢复」。

---

## 行为（已实测验证）

| 操作 | 表现 |
|---|---|
| 合上盖子 | 屏幕自然熄灭（背光 3→2→0）；系统保持运行；SSH / 后台任务不中断 |
| 打开盖子 | 屏幕 **1 秒内**自动恢复（背光 0→3），回到桌面 |
| 长时间合盖（1.5 分钟+） | 开盖同样正常恢复 |
| 系统睡眠 | 禁用（`disablesleep=1`），避免进入深睡 |

---

## 实现：两个 launchd 服务

### 1) com.local.keepawake — 由 launchd 直接托管 caffeinate

`services/com.local.keepawake.plist` 让 launchd 常驻运行 `/usr/bin/caffeinate -ims`（阻止系统睡眠）。由 launchd 的 `KeepAlive` 保证绝不退出（比在脚本里 nohup 更可靠）。

### 2) com.local.nosleep — 仅保活 disablesleep

`services/nosleep.sh` 每 5 秒检查并确保 `disablesleep=1`。

> ⚠️ **关键：不要用 `pmset displaysleepnow` 主动关屏。** 本机核显（WEX）在合盖再开盖时，若显示曾被主动关闭，会触发 eDP 的 `DBUF power up timeout` → `FB0 is not enabled` → 黑屏无法恢复。让 macOS 自然管理显示电源即可正常恢复。

---

## 安装

```bash
# 1. 部署脚本
sudo mkdir -p /usr/local/bin
sudo cp services/nosleep.sh /usr/local/bin/nosleep.sh
sudo chmod 755 /usr/local/bin/nosleep.sh

# 2. 部署两个 launchd 服务
sudo cp services/com.local.keepawake.plist /Library/LaunchDaemons/
sudo cp services/com.local.nosleep.plist   /Library/LaunchDaemons/
sudo chown root:wheel /Library/LaunchDaemons/com.local.*.plist
sudo chmod 644 /Library/LaunchDaemons/com.local.*.plist

# 3. 加载
sudo launchctl bootstrap system /Library/LaunchDaemons/com.local.keepawake.plist
sudo launchctl bootstrap system /Library/LaunchDaemons/com.local.nosleep.plist

# 4. 直接设置（服务也会自动保活）
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

---

## 功耗参考（合盖熄屏状态）

约 3 W（CPU 核心 C6 深睡、GPU 空闲；剩余为 SoC 平台基础供电）。
