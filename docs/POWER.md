# 电源与合盖行为

本机采用 Intel **Modern Standby** 供电模型（ACPI 中可见 `PEPD`/`INT33A1`）。macOS 的传统睡眠路径与该模型的进入动作不兼容，因此本项目采用 **keep-awake + 合盖熄屏** 的方案，保证合盖时系统保持运行、开盖即时恢复。

---

## 行为

| 操作 | 表现 |
|---|---|
| 合上盖子 | 屏幕熄灭；系统保持运行；SSH / 后台任务不中断 |
| 打开盖子 | 屏幕立即点亮，回到原桌面，无需等待 |
| 系统睡眠 | 禁用（`disablesleep=1`），避免进入深睡 |

这是本机在 macOS 下最稳定的合盖体验：等同「关屏待机」，不进入会中断会话的深睡状态。

---

## 实现

### 1. 电源设置

```bash
sudo pmset -a disablesleep 1
sudo pmset -a sleep 0
sudo pmset -a hibernatemode 0 standby 0 powernap 0
```

| 项 | 作用 |
|---|---|
| `disablesleep 1` | 禁止系统进入睡眠 |
| `sleep 0` | 空闲不自动睡眠 |
| `hibernatemode 0` / `standby 0` / `powernap 0` | 关闭休眠与暗唤醒 |

### 2. 合盖守护服务

`services/nosleep.sh` 轮询 `AppleClamshellState`：
- 合盖（`Yes`）→ `pmset displaysleepnow` 关屏
- 开盖（`No`）→ `caffeinate -u` 点亮显示
- 同时常驻 `caffeinate -ims` 与 `disablesleep=1`，保证会话不中断

#### 安装

```bash
sudo mkdir -p /usr/local/bin
sudo cp services/nosleep.sh /usr/local/bin/nosleep.sh
sudo chmod 755 /usr/local/bin/nosleep.sh
sudo cp services/com.local.nosleep.plist /Library/LaunchDaemons/
sudo launchctl bootstrap system /Library/LaunchDaemons/com.local.nosleep.plist
```

#### 查看状态 / 日志

```bash
sudo launchctl print system/com.local.nosleep | grep -E 'state|pid'
tail -f /var/log/nosleep.log
```

#### 卸载

```bash
sudo launchctl bootout system /Library/LaunchDaemons/com.local.nosleep.plist
sudo rm /Library/LaunchDaemons/com.local.nosleep.plist /usr/local/bin/nosleep.sh
sudo pmset -a disablesleep 0
```

---

## 功耗参考（合盖关屏状态实测）

| 指标 | 数值 |
|---|---|
| Package 功耗 | 约 3 W |
| CPU C-state | 空闲 90%+（核心 C6 深睡） |
| GPU | 空闲（C-state 100%） |

合盖关屏后 CPU/GPU 均进入空闲态，功耗主要由 SoC 平台基础供电构成。

---

## 说明

- 若需临时恢复系统默认睡眠策略：`sudo pmset -a disablesleep 0`。
- 合盖守护与系统「合盖睡眠」互斥；启用本服务后合盖不触发系统睡眠。
