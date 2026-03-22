# ADR-0004: 使用 Caddy 作为反向代理

- **状态**: 已采纳
- **日期**: 2026-03-22
- **决策者**: @bernylinville

## 背景

NAS 运行多个 Web 服务 (Uptime Kuma 等)，需要统一入口和路由。
家庭内网环境，无公网域名需求。

## 决策

使用 **Caddy 2.11.2** 作为反向代理，HTTP 模式 (`auto_https off`)。

## 备选方案

| 方案 | 优点 | 缺点 |
|------|------|------|
| **Caddy** | 配置极简、自动 HTTPS、性能好 | 家庭内网 HTTPS 无意义 |
| Traefik | Docker 深度集成、自动发现 | 配置复杂、少量服务 overkill |
| Nginx | 性能极佳、文档丰富 | 配置繁琐 |

## 影响

- Caddy 绑定 LAN IP 80/443 端口
- 通过 `nas-platform` Docker network 做服务发现
- 路由配置在 `Caddyfile` 中
