# ADR-0002: 使用 sops + age 管理 Secrets

- **状态**: 已采纳
- **日期**: 2026-03-21
- **决策者**: @bernylinville

## 背景

项目需要安全存储敏感信息（Restic 密码、Telegram bot token 等），
且需支持 Git 版本控制和离线操作。

## 决策

使用 **sops + age** 加密 secrets，存储在 `inventory/prod/group_vars/all.sops.yml`。

## 备选方案

| 方案 | 优点 | 缺点 |
|------|------|------|
| **sops + age** | Git 友好、离线可用、无服务端依赖 | 需管理 age key 文件 |
| Ansible Vault | Ansible 原生集成 | 密码管理不如 age 灵活 |
| HashiCorp Vault | 企业级、动态 secrets | 需运行服务端、单机 overkill |

## 影响

- Secrets 加密存储在 Git 中
- 运行 Ansible 需要 `SOPS_AGE_KEY_FILE` 环境变量
- `ansible.cfg` 启用 `community.sops.sops` vars plugin
