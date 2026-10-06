---
name: disk-cleanup
description: 基于 WizTree CSV 扫描报告分析 Windows C 盘空间占用，生成人机协作的分级清理方案并安全执行删除。当用户提到 C 盘满了、磁盘空间不足、清理硬盘、WizTree 报告、或要求分析 Windows 目录占用时使用。触发词：磁盘清理、C盘空间、WizTree、空间占用、硬盘满了。
argument-hint: <WizTree导出的CSV路径，可选>
---

# Windows C 盘清理（人机协作）

## Overview

解析 WizTree 4.x 导出的 CSV 全盘报告，按目录钻取找出空间大头，产出"三梯队"清理建议；仅在用户逐批确认后执行删除，并验证实际释放量。核心原则：**先报告后动手，删前做预检，删后必验证，禁区不碰**。

## 流程

### 1. 取得报告

若用户未给路径，在 `Documents` 等常见位置找最新的 `WizTree_*.csv`；找不到则指导用户：WizTree 扫描 C 盘 → 文件 → 导出为 CSV（需包含文件夹与文件）。

CSV 格式（注意有中文表头变体）：每行 `"完整路径",大小字节,占用字节,修改时间,属性,文件数,子项数`。文件夹汇总行路径以 `\` 结尾，文件行不以 `\` 结尾。解析要点（脚本已内置，勿手写重蹈覆辙）：
- 关闭 `FS` 自动分割，用 `match($0, /^"([^"]*)"/)` 取路径；大小字段起点是 `RSTART+RLENGTH+1`（多一位少一位都会导致数值错 10 倍）
- **不要**用 `awk -v var=值` 传 Windows 路径（反斜杠被转义吞掉），改用环境变量 `ENVIRON["VAR"]`
- 汇总前先看根行 `C:\` 的总量做交叉校验，数量级对不上说明解析错了

### 2. 分析（只读）

用捆绑脚本自顶向下钻取，每层挑大头继续：

```bash
bash scripts/wiztree-analyze.sh <csv> dirs "C:"
bash scripts/wiztree-analyze.sh <csv> dirs "C:\Users\<user>\AppData"
bash scripts/wiztree-analyze.sh <csv> files "C:\Users\<user>\.android" 10
```

重点钻取路径：`C:\Users\<user>`（含点目录 `.gradle\.android\.lmstudio` 等）、`AppData\Local`、`AppData\Roaming`、`Windows`、`Program Files*`、`ProgramData`。同时看根目录单文件（`pagefile.sys`、`hiberfil.sys`）。

### 3. 生成分级报告并等待确认

按 `references/cleanup-playbook.md` 把发现归类为三梯队，输出：空间去向 Top 表 + 每梯队预计回收量。**报告完就停**，等用户点名（如"第一梯队全删"、指定目录清单）。不要未经确认删除任何东西。

### 4. 执行删除（预检 → 删 → 验证）

对每个已确认条目：

1. **预检**（见 playbook P1-P2）：Gradle 用 `gradle-wrapper.properties` 反查在用版本；模拟器/IDE/微信数据先 `tasklist` 确认宿主进程未运行；"看是否还在用"类条目若用户已点名则不再追问
2. **删除**：`rm -rf`；Temp 逐项删、锁文件跳过；Android 模拟器优先删 `snapshots`，`userdata-qcow2` 需单独确认；微信只删 `msg`+`cache` 保 `db_storage`
3. **验证**（P3）：对每个路径做存在性复查，`df -h /c` 前后差值写入汇报

### 5. 收尾

汇报本轮释放量与累计释放量，列出剩余候选（含第三梯队需用户以管理员身份自行执行的 DISM/pagefile 命令），不主动继续。

## 安全红线

- 未获用户点名确认的目录一律不删；用户说"继续删除"仅覆盖上一轮明确列出的剩余候选
- 禁区清单（`Windows\Installer`、手工 WinSxS、NTFS 元数据、Edge 多版本缓存）在任何情况下不执行，只解释原因
- 系统级操作（DISM、pagefile、注册表）只给命令让用户自行执行，不代跑

## Resources

- `scripts/wiztree-analyze.sh` — WizTree CSV 分析：`dirs <前缀>` 列子文件夹大小，`files <前缀> [N]` 列最大文件
- `references/cleanup-playbook.md` — 三梯队已知目标清单、命令、禁区、预检清单（生成报告前必读）
