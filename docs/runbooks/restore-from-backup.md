# 备份恢复 Runbook

> 适用场景：需要从 Restic 备份中恢复文件或目录

## 前提条件

- Restic 已安装，repo 已初始化
- `/etc/restic/env` 已配置

## 常用操作

### 查看可用快照

```bash
source /etc/restic/env
restic snapshots
```

### 恢复整个快照

```bash
source /etc/restic/env
# 恢复最新快照到临时目录
restic restore latest --target /tmp/restore-test

# 恢复到原始位置 (覆盖)
restic restore latest --target /
```

### 恢复指定路径

```bash
source /etc/restic/env
# 恢复单个文件
restic restore latest --include /etc/docker/daemon.json --target /tmp/restore

# 恢复整个目录
restic restore latest --include /opt/compose --target /tmp/restore
```

### 恢复指定快照

```bash
source /etc/restic/env
# 列出快照
restic snapshots

# 恢复指定 ID 的快照
restic restore abc12345 --target /tmp/restore
```

### 浏览快照内容

```bash
source /etc/restic/env
# 列出最新快照中的文件
restic ls latest

# 搜索特定文件
restic find "docker-compose.yml"
```

### 验证备份完整性

```bash
source /etc/restic/env
restic check
```

## 注意事项

- 恢复到原始路径会**覆盖**现有文件
- 建议先恢复到 `/tmp/restore` 验证后再覆盖
- 大规模恢复可能需要数小时（取决于数据量）
