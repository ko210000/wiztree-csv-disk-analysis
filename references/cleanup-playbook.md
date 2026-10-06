# C 盘清理手册（Windows 11 / Git Bash 环境）

已知清理目标、验证过的命令、预检项与禁区。所有路径按用户实际盘符调整。

## 第一梯队：安全（缓存与临时文件，可再生）

| 目标 | 典型位置 | 清理方式 |
|---|---|---|
| Gradle 旧版本缓存 | `~\.gradle\caches\{版本号}\` | 先跑预检 P1 确认在用版本，删除未使用版本目录；`modules-2`、`wrapper` 保留（共享依赖，重下代价大） |
| 模拟器快照 | `~\.android\avd\*.avd\snapshots\` | 直接删 snapshots 目录（预检 P2）；冷启动不影响 AVD。`userdata-qemu.img.qcow2` 是当前用户数据增量，删=恢复出厂，需单独确认 |
| npm 缓存 | `Local\npm-cache` | `npm cache clean --force` |
| pip 缓存 | `Local\pip\cache` | `pip cache purge` |
| uv 缓存 | `Local\uv` | `uv cache clean` |
| Temp | `Local\Temp` | 逐项 `rm -rf`，被占用条目自动跳过；保留 CLI 自身目录（如 CLI/Agent 自身的临时输出目录） |
| updater 安装包残留 | `Local\*-updater`、`Local\@*-updater`（lm-studio、zcode、draw.io 等 Electron 应用） | 整目录删除，只存下载好的安装包，应用需要时会重新下载 |
| Playwright/测试浏览器 | `~\.chromium-browser-snapshots` | 不用测试工具则整删 |

## 第二梯队：按"是否还在用"确认（IDE/工具残留）

| 目标 | 位置 | 说明 |
|---|---|---|
| 已卸载 AI IDE 数据 | `Roaming\TRAE SOLO CN`、`Roaming\Trae CN`、`Roaming\CodeBuddy CN` + `~\.codebuddy*` + `Local\CodeBuddyExtension` | 同类工具只留实际在用的那个；Roaming 与家目录点目录要成对删除 |
| 本地大模型 | `~\.lmstudio`、`Roaming\ollama app.exe`、`~\.ollama`、`Roaming\Comfy Desktop` | 模型目录通常是空的（模型放其他盘），主要占空间的是 backend dll |
| 微信聊天文件 | `Documents\xwechat_files\wxid_*\msg`（文件/附件/视频）+ `cache` | **保留 `db_storage`**（文字聊天记录数据库），只删 msg 与 cache；删后历史消息里的文件打不开 |
| 内嵌浏览器内核 | `Roaming\greencore`、`Roaming\GreenCore7z`（secore 的 Chrome 分发） | 宿主软件会按需重下；删前 `tasklist` 确认未运行 |
| Android Studio 索引 | `Local\Google\AndroidStudio*\index` | 打开项目会重建，首次同步慢几分钟 |

## 第三梯队：系统级（给用户命令自行执行，不代跑）

- **WinSxS**（常年 15~20 GB）：管理员 PowerShell 执行
  `Dism.exe /Online /Cleanup-Image /StartComponentCleanup /ResetBase`，通常回收 3~5 GB
- **pagefile.sys**（10 GB+）：设置→关于→高级系统设置→性能设置→高级→虚拟内存；迁移到其他盘或改固定小值；不建议完全关闭
- 存储感知 / `cleanmgr /sageset:1` 作为补充

## 禁区（无论用户多激进都不要直接删）

- `C:\Windows\Installer` — 删了软件无法卸载/修复；只能靠 patch cleanup
- `WinSxS` 手工删子目录 — 必须走 DISM
- `System Volume Information`、`$Recycle.Bin` 以外的 NTFS 元数据（`$MFT`、`$Extend`）
- `Program Files (x86)\Microsoft` 下 Edge 多版本 — 更新器自动回收
- 正在运行的应用的 Temp 锁文件 — 跳过即可，勿强杀进程

## 预检清单

- **P1 Gradle 在用版本**：`grep -h distributionUrl <各项目的>gradle/wrapper/gradle-wrapper.properties | sort -u`，凡出现在结果里的版本目录保留
- **P2 进程占用**：删除前 `tasklist | grep -iE 'studio|java|qemu|emulator|wechat|weixin|node|ollama'`，命中对应条目则提醒用户先关程序
- **P3 效果验证**：删除前后各跑一次 `df -h /c`，报告差值；对每个已删路径做 `[ -e path ]` 存在性复查

## 报告格式建议

按梯队输出表格：位置 / 大小 / 说明，附"预计可释放 X~Y GB"总量；每梯队末尾给出具体命令或"回复第N梯队全删"式确认入口。
