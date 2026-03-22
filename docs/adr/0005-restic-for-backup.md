# ADR-0005: 使用 Restic 进行备份

- **状态**: 已采纳
- **日期**: 2026-03-21
- **决策者**: @bernylinville

## 背景

NAS 存储重要数据 (RAID1 /data + /opt/compose + /etc)，
需要定期备份，未来计划扩展到 B2 远程存储实现 3-2-1 原则。

## 决策

使用 **Restic** 进行增量加密备份，通过 systemd timer 每日 02:00 执行。

## 备选方案

| 方案 | 优点 | 缺点 |
|------|------|------|
| **Restic** | 增量、加密、去重、支持多后端 (local/B2/S3) | 首次全量较慢 |
| BorgBackup | 性能更优、成熟 | 不支持 S3/B2 原生 |
| rsync + cron | 简单直接 | 无加密、无去重、无增量 |

## 影响

- 备份存储在 `/data/backups/restic`
- systemd timer (`restic-backup.timer`) 每日凌晨执行
- 保留策略: 7 daily + 4 weekly + 6 monthly
