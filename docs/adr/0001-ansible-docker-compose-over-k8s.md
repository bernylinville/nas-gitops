# ADR-0001: 使用 Ansible + Docker Compose 而非 Kubernetes

- **状态**: 已采纳
- **日期**: 2026-03-21
- **决策者**: @bernylinville

## 背景

NAS 是单台家用服务器 (Debian 13, i5-9600KF, 16GB RAM)，运行少量容器化服务。
需要选择编排方案管理基础设施和服务部署。

## 决策

使用 **Ansible** 管理主机配置 + **Docker Compose** 管理容器服务。

## 备选方案

| 方案 | 优点 | 缺点 |
|------|------|------|
| **Ansible + Docker Compose** | 简单、可调试、学习成本低、单机足够 | 无自动扩缩、无服务发现 |
| K3s / K8s | 声明式、生态丰富 | 单机 overkill、资源开销大、学习曲线陡 |
| Docker Swarm | 比 K8s 轻量 | 社区萎缩、功能有限 |

## 影响

- 所有服务通过 `compose/` 目录管理
- Ansible role 处理主机配置（baseline, docker, monitoring, restic）
- 部署通过 `deploy.yml` playbook 执行
