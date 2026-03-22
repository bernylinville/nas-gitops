# nas-gitops

家用 NAS GitOps 管理仓库。使用 Ansible + Docker Compose + GitHub Actions 管理
Debian 13 NAS 的主机配置、服务部署和运维自动化。

## 架构

- **配置管理**：Ansible (4 roles: baseline, docker, monitoring, restic)
- **服务编排**：Docker Compose (Caddy 2.11.2 + Uptime Kuma 2.2.1)
- **CI/CD**：GitHub Actions（lint + molecule + deploy-test）+ 手动部署
- **Secrets**：sops + age
- **备份**：Restic（本地，systemd timer）
- **监控**：Uptime Kuma + 告警脚本（SMART / RAID / 磁盘 / 备份）
- **远程接入**：EasyTier（零公网暴露）

## 快速开始

```bash
# 安装依赖
pip install -r requirements-dev.txt
ansible-galaxy collection install -r requirements.yml

# 验证连接
ansible nas -m ping

# dry-run
ansible-playbook -i inventory/prod ansible/playbooks/baseline.yml --check --diff
ansible-playbook -i inventory/prod ansible/playbooks/docker.yml --check --diff
ansible-playbook -i inventory/prod ansible/playbooks/backup.yml --check --diff

# 部署
ansible-playbook -i inventory/prod ansible/playbooks/baseline.yml
ansible-playbook -i inventory/prod ansible/playbooks/docker.yml
ansible-playbook -i inventory/prod ansible/playbooks/backup.yml

# 验证
ansible-playbook -i inventory/prod ansible/playbooks/verify.yml
```

## 项目进度

详见 [开发规划](docs/development-roadmap.md)（Agent SSOT）

- ✅ M0：仓库与安全基础
- ✅ M1：主机基线（baseline + docker + monitoring roles）
- ✅ M2：备份与监控（restic role + 告警脚本 + Uptime Kuma + runbooks）
- ✅ M3：平台入口（Caddy 反代 + deploy/rollback playbook）

## 文档

- [开发规划](docs/development-roadmap.md) — **SSOT**：项目状态、NAS 状态、CI 结构
- [v3.1 方案](nas-gitops-plan-v3.1-2026-03-21.md) — 架构方案
- [CLAUDE.md](CLAUDE.md) — AI 开发硬约束
- [AGENTS.md](AGENTS.md) — 多 Agent 兼容指引
- `docs/runbooks/` — 运维 Runbook（灾难恢复、RAID 换盘、备份恢复）

## 安全原则

- 🔒 零入站公网暴露
- 🔑 Secrets 使用 sops + age 加密
- 🛡️ 所有服务仅 LAN / EasyTier 可达
- 🚫 无防火墙管控（家庭内网环境）
