# WizTree CSV 磁盘清理 Agent Skill

基于 [WizTree](https://www.diskanalyzer.com/) 导出的 CSV 全盘扫描报告，为 AI 编码代理（Qoder CLI 等支持 Agent Skills 的工具）提供一套**人机协作的 Windows C 盘清理工作流**：分析占用 → 生成分级清理报告 → 等待用户逐批确认 → 预检 → 删除 → 验证释放量。

## 为什么

直接让 AI "帮我清理C盘"是危险的。这个 skill 把清理约束成一个带安全边界的流程：

- **先报告后动手**：任何目录未经用户点名确认不会删除
- **删前预检**：检查 Gradle 在用版本（扫 `gradle-wrapper.properties`）、宿主进程是否运行
- **删后验证**：路径存在性复查 + `df -h` 前后差值汇报
- **禁区硬编码**：`Windows\Installer`、手工删 WinSxS、NTFS 元数据、Edge 多版本缓存等一律只解释不执行
- **系统级操作不代跑**：DISM、pagefile 调整只给出命令由用户以管理员身份执行

实测一轮完整协作释放约 41 GB。

## 目录结构

```
.
├── SKILL.md                          # 技能入口：五步工作流与 CSV 解析要点
├── scripts/
│   └── wiztree-analyze.sh            # WizTree CSV 分析器（bash + awk，无依赖）
└── references/
    └── cleanup-playbook.md           # 三梯队清理目标手册、命令、禁区、预检清单
```

## 安装

将本仓库内容复制到 Agent 技能目录即可：

```bash
# 用户级（所有项目可用）
git clone https://github.com/ko210000/wiztree-csv-disk-analysis.git
cp -r wiztree-csv-disk-analysis ~/.qoder-cn/skills/disk-cleanup

# 或项目级
cp -r wiztree-csv-disk-analysis <project>/.qoder/skills/disk-cleanup
```

## 使用

1. 用 WizTree 扫描 C 盘，`文件 → 导出为CSV`（勾选包含文件夹与文件）
2. 对 Agent 说："帮我清理C盘，报告在 `WizTree_xxx.csv`"（或 `/disk-cleanup <csv路径>`）
3. Agent 输出三梯队报告后，按批回复，如："第一梯队全删"、"删 X 和 Y，保留 Z"
4. 每轮删除后 Agent 汇报实际释放空间

## 分析脚本单独使用

`scripts/wiztree-analyze.sh` 不依赖 Agent 也可独立分析 CSV（Git Bash / WSL）：

```bash
# 列出某前缀下的一级子文件夹（按大小降序）
bash scripts/wiztree-analyze.sh WizTree_xxx.csv dirs "C:"

# 列出某前缀下最大的 N 个文件
bash scripts/wiztree-analyze.sh WizTree_xxx.csv files "C:\Users\me\.android" 10
```

已处理的 CSV 解析坑：中文表头变体、路径内逗号（引号包裹）、文件夹汇总行以 `\` 结尾的识别、`awk -v` 传 Windows 路径时反斜杠被转义的问题（脚本改用 `ENVIRON` 传参）。

## 环境要求

- Windows + Git Bash（脚本仅用 bash/awk/sed/coreutils，无第三方依赖）
- WizTree 4.x CSV 导出

## License

MIT
