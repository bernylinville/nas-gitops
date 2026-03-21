# nas-gitops

家用 NAS GitOps 管理仓库。使用 Ansible + Docker Compose + GitHub Actions 管理
Debian 13 NAS 的主机配置、服务部署和运维自动化。

## 架构

- **配置管理**：Ansible
- **服务编排**：Docker Compose
- **CI/CD**：GitHub Actions（lint）+ 手动部署
- **Secrets**：sops + age
- **备份**：Restic（本地 + 异地）
- **监控**：Uptime Kuma + 告警脚本
- **远程接入**：EasyTier（零公网暴露）

## 快速开始

```bash
# 安装依赖
pip install ansible-core ansible-lint yamllint
ansible-galaxy install -r requirements.yml
ansible-galaxy collection install -r requirements.yml

# 验证连接
ansible nas -m ping

# dry-run 基线检查
ansible-playbook -i inventory/prod ansible/playbooks/baseline.yml --check --diff

# 部署
ansible-playbook -i inventory/prod ansible/playbooks/deploy.yml
```

## 文档

- [v3.1 方案](nas-gitops-plan-v3.1-2026-03-21.md)
- [CLAUDE.md](CLAUDE.md) — AI 开发协作指引
- [AGENTS.md](AGENTS.md) — 多 Agent 兼容指引
- `docs/runbooks/` — 运维 Runbook
- `docs/adr/` — 架构决策记录

## 安全原则

- 🔒 零入站公网暴露
- 🔑 Secrets 使用 sops + age 加密
- 🛡️ 所有服务仅 LAN / EasyTier 可达
