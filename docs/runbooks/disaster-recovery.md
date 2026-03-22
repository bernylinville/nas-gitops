# 灾难恢复 Runbook

> 适用场景：NAS 系统盘故障、需要完全重建

## 前提条件

- 新的 Debian 13 (trixie) 安装
- 网络已配置 (192.168.50.10/24)
- SSH key 已部署
- 数据盘 RAID1 (/dev/md0) 完好

## 恢复步骤

### 1. 引导系统

```bash
# 在新机器上执行
bash scripts/bootstrap.sh
```

### 2. 应用基线配置

```bash
# 从开发机执行
ansible-playbook -i inventory/prod ansible/playbooks/baseline.yml --check --diff
ansible-playbook -i inventory/prod ansible/playbooks/baseline.yml
```

### 3. 安装 Docker

```bash
ansible-playbook -i inventory/prod ansible/playbooks/docker.yml
```

### 4. 恢复备份

```bash
# SSH 到 NAS
source /etc/restic/env
restic snapshots  # 查看可用快照
restic restore latest --target /  # 恢复最新快照
```

### 5. 部署服务

```bash
ansible-playbook -i inventory/prod ansible/playbooks/backup.yml
# 启动 Docker 服务
cd /opt/compose/platform/uptime-kuma && docker compose up -d
```

### 6. 验证

```bash
ansible-playbook -i inventory/prod ansible/playbooks/verify.yml
```

## 预计恢复时间

| 步骤 | 时间 |
|------|------|
| Debian 安装 | ~30 min |
| 基线 + Docker | ~15 min |
| 备份恢复 | ~1-2 hours (取决于数据量) |
| 服务部署 | ~10 min |
| **合计** | **~2-3 hours** |
