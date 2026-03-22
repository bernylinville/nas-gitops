# 服务部署 Runbook

> 适用场景：部署、更新、回滚 Docker Compose 服务

## 前提条件

- M1 baseline + Docker 已部署
- NAS 可通过 SSH 访问

## 首次完整部署

```bash
# 1. dry-run
ansible-playbook -i inventory/prod ansible/playbooks/deploy.yml --check --diff

# 2. 部署所有服务
ansible-playbook -i inventory/prod ansible/playbooks/deploy.yml

# 3. 验证
curl http://192.168.50.10/healthz     # Caddy
curl http://192.168.50.10:3001        # Uptime Kuma (直连)
curl http://192.168.50.10/ai/         # Open WebUI (via Caddy)
```

## 选择性部署

```bash
# 仅部署平台服务 (caddy + uptime-kuma)
ansible-playbook -i inventory/prod ansible/playbooks/deploy.yml --tags platform

# 仅部署应用服务 (open-webui)
ansible-playbook -i inventory/prod ansible/playbooks/deploy.yml --tags apps

# 仅创建网络
ansible-playbook -i inventory/prod ansible/playbooks/deploy.yml --tags network
```

## 更新服务版本

1. 修改对应 `docker-compose.yml` 中的镜像版本号
2. 提交 PR → CI 通过 → merge
3. 重新部署:

```bash
ansible-playbook -i inventory/prod ansible/playbooks/deploy.yml
```

## 回滚服务

```bash
# 回滚单个服务 (从当前 repo 状态重新部署)
ansible-playbook -i inventory/prod ansible/playbooks/rollback.yml \
  -e "rollback_service=open-webui" -e "rollback_type=apps"

# 如需回滚到旧版本:
# 1. 在 repo 中 git checkout 旧 tag
# 2. 重新执行 rollback.yml
```

## 在 NAS 上手动操作

```bash
# 查看服务状态
cd /opt/compose/platform/caddy && docker compose ps
cd /opt/compose/apps/open-webui && docker compose ps

# 查看日志
docker compose logs -f --tail 50

# 重启单个服务
docker compose restart

# 完全重建
docker compose down && docker compose up -d
```

## 服务架构

```
Client (LAN/EasyTier)
       │
       ▼  http://192.168.50.10
    ┌─────────┐
    │  Caddy   │ :80
    └─────────┘
       │
   ┌───┴───┐
   ▼       ▼
 /uptime   /ai
   │       │
   ▼       ▼
 Uptime   Open
 Kuma     WebUI
 :3001    :8080
```
