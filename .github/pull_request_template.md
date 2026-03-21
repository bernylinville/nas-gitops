---
name: Pull Request
about: Propose changes to nas-gitops
---

## 变更内容

<!-- 简要描述你做了什么 -->

## 变更类型

- [ ] 主机基线配置（Ansible role/playbook）
- [ ] Docker Compose 服务
- [ ] 告警 / 监控脚本
- [ ] CI / 策略检查
- [ ] 文档 / Runbook
- [ ] 其他

## 检查清单

- [ ] `yamllint` 通过
- [ ] `ansible-lint` 通过
- [ ] `shellcheck` 通过（如涉及 shell 脚本）
- [ ] `docker compose config` 通过（如涉及 compose 文件）
- [ ] 无明文 secrets 泄露
- [ ] 服务绑定地址不是 `0.0.0.0`
- [ ] Docker 镜像 tag 非 `latest`
- [ ] 已在 `--check --diff` 模式下验证（如涉及 Ansible）

## 部署说明

<!-- 合并后需要的手动操作步骤，如果不需要则删除此节 -->
