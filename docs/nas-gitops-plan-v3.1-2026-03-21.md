# NAS GitOps 最终方案 v3.1

- 版本：v3.1（审查修订最终版）
- 日期：2026-03-21
- 适用对象：家用单机 NAS
- 目标主机：`nas`
- 系统：Debian GNU/Linux 13 (trixie)
- 内核：`6.12.74+deb13+1-amd64`

---

## 一、文档目的

这份 v3.1 文档是在 v3 基础上纳入最终审查意见后的定稿。

v3.1 不改变 v3 的方向和骨架，仅补齐以下细节：

1. 明确 CI→CD 部署执行路径
2. 明确"零公网暴露"的准确语义（入站 vs 出站）
3. 补充 EasyTier 不可用时的应急方案
4. 补充 Caddy 绑定地址约束
5. 补充 NAS 本地 Git 仓库镜像策略
6. 补充 Restic 备份前置检查和防勒索加固
7. 精简仓库结构中的轻微过度设计
8. Runbook 分批交付优先级
9. 补充 bootstrap.sh 最小引导脚本

---

## 二、最终结论

### 1. 当前 NAS 健康状态结论

这台 NAS 当前状态可以继续投入使用，且适合开始做 GitOps 化管理。

#### 已确认事实

- 软 RAID1 正常
  - `/proc/mdstat` 为 `[2/2] [UU]`
  - `mdadm --detail /dev/md0` 显示 `State : clean`
  - `Failed Devices : 0`
- `/data` 挂载正常
  - `/dev/md0 -> /data`
  - 文件系统为 `ext4`
  - `/etc/fstab` 已按 UUID 挂载
- 两块数据盘 SMART 总体健康通过
  - `SMART overall-health ... PASSED`
  - `Reallocated_Sector_Ct = 0`
  - `Current_Pending_Sector = 0`
  - `Offline_Uncorrectable = 0`
  - `UDMA_CRC_Error_Count = 0`
  - 当前温度约 `37°C`

#### 风险事实

- 两块数据盘盘龄较高
  - 一块约 `53770` 小时
  - 一块约 `63293` 小时
- 系统盘 `sda` 是**单点故障**
- 当前基础系统虽然已经有 mdadm/timer 等默认机制，但：
  - 备份目标未正式固化
  - 恢复 SOP 未正式固化
  - secrets 恢复链路未正式固化
  - 监控/告警与日志策略未正式固化

### 2. 最终判断

> 这台 NAS **不需要重做存储结构**，正确路线是继续保留 `mdadm RAID1 + ext4`，把精力集中到：备份、恢复、secrets、部署规范、监控、最小暴露面和 GitOps 管理上。

---

## 三、设计原则

### 原则 1：先保证能恢复，再谈优雅架构

优先级顺序是：

1. 可恢复
2. 可回滚
3. 可审计
4. 可自动化
5. 可扩展

### 原则 2：家用单机 NAS 不上重型平台

明确不采用：

- Kubernetes
- ArgoCD
- Flux
- 复杂多节点编排

### 原则 3：GitOps 要严格，但边界要现实

采用：

- 配置 GitOps
- secrets 加密 GitOps
- 硬件初始化 / 灾难恢复 Runbook 化

而不是把一切硬塞进"纯声明式自动化"。

### 原则 4：先用最少组件覆盖关键需求

前期尽量少组件，但不能少掉这些核心能力：

- 备份
- 恢复
- secrets 管理
- 基线配置管理
- 部署校验
- 最小监控告警
- 最小暴露面控制

### 原则 5：抽象保留，但实现不做过早复杂化

对 openclaw / claw 类服务，**架构上保留"AI coding runtime / gateway"这一抽象层**，但第一阶段实现上**直接部署 openclaw 或具体 runtime**，不一开始自建复杂网关。

### 原则 6：访问路径必须收敛

NAS 服务访问路径只能是：

- 家庭内网
- EasyTier 虚拟专网

不新增第二套远程接入系统。不做公网入口。不在主路由暴露端口。

---

## 四、最终推荐方案

### 1. 主轴技术选型

#### 保留的核心选型

- **主机配置管理：Ansible**
- **服务编排：Docker Compose**
- **代码托管：GitHub**
- **CI：GitHub Actions**
- **Secrets：sops + age**
- **备份：Restic**
- **远程接入：EasyTier（已有，不新增 Tailscale）**

#### 收敛后的平台选型

- **反向代理：Caddy**
  - 保留未来切换 Traefik 的空间
- **监控告警：轻量方案优先**
  - 第一阶段：Uptime Kuma + 告警脚本
  - 第二阶段：按需升级到 Prometheus + Grafana + Alertmanager

#### 明确暂不作为第一阶段重点的内容

- Go 自研工具
- conftest / OPA / Rego 策略引擎
- 长期维护的 lab 环境
- 复杂 AI gateway 多 provider 编排层
- Loki 等完整日志平台
- Tailscale
- 任何需要公网暴露的入口服务

### 2. 一句话总结

> Ansible 管主机，Compose 管服务，GitHub 管变更，CI 管质量，sops 管 secrets，Restic 管恢复，EasyTier / 家庭内网管访问路径，Caddy 管内网服务入口。

---

## 五、关键选型理由

> 详细的决策过程建议记录到 `docs/adr/` 中，这里只保留核心结论。

| 决策 | 结论 | 核心理由 |
|------|------|----------|
| 编排 | Ansible + Compose | 单机最合适，可读性高，故障排查直观 |
| 不用 K8s | 确认 | 资源浪费，维护成本远大于收益 |
| 反向代理 | Caddy（非 Traefik） | 配置更简洁，固定少量服务足够用；服务增多后可迁移 |
| 监控 | 先轻后重 | 先确保关键风险能告警，再按需上 Prometheus 栈 |
| AI runtime | 简单部署，结构留余地 | 目录用 `ai-runtime/` 不绑死 openclaw，但不做过早网关化 |
| 远程接入 | EasyTier（非 Tailscale） | 已有现成网络，避免重复接入方案，减少运维面 |
| 暴露策略 | 零入站暴露 | 家用 NAS 稳定性和安全性优先，拒绝端口映射 |

---

## 六、职责边界

### 1. Ansible 负责什么

Ansible 是这套方案的主轴，负责"把机器收敛到期望状态"。

主要包括：

- Debian baseline
- 包管理
- SSH hardening
- 防火墙
- NTP / 时区
- Docker Engine / Compose 插件
- EasyTier 客户端 / 相关基础配置（如需要在 NAS 侧纳管）
- smartmontools
- mdadm 监控
- systemd service / timer
- Caddy
- Uptime Kuma
- Restic
- compose 文件下发与部署
- 部署后 verify

### 2. Shell 负责什么

Shell 只做薄胶水：

- `bootstrap.sh`（裸机 → 能跑 Ansible 的最小引导）
- deploy / verify / rollback / backup / restore wrapper
- 简单策略检查
- 快速健康检查
- 告警通知脚本

不要让 Shell 变成长期主平台。

### 3. Go 负责什么

Go 不进入第一阶段范围。

只有在未来明确出现以下需求时，才考虑引入：

- 自定义配置审计
- 更复杂的 drift detection
- 专门的恢复 CLI
- 多服务策略校验器

### 4. 一句话边界

- **Ansible：主机和服务状态收敛**
- **Shell：引导、胶水、告警、应急**
- **Go：未来增强，不是首发重点**

---

## 七、GitOps 边界

### 1. 完全纳入 Git 的内容

- Ansible playbooks / roles
- Docker Compose 文件
- Caddy 配置
- systemd unit / timer 模板
- 部署 / 恢复 / 备份 / 告警脚本
- 文档 / Runbooks
- CI 工作流
- 策略检查脚本
- 防火墙规则模板
- EasyTier 相关纳管配置（如果需要）

### 2. 不应明文纳入 Git 的内容

- API keys
- 私钥
- tokens
- break-glass 凭据
- 某些首次引导和硬件特定数据

### 3. 不应纳入 GitOps 管理的内容

- 数据库实际数据（由备份策略管理）
- Docker volumes 中的运行时数据
- 容器日志
- Restic 备份仓库内容本身

### 4. 正确做法

- **配置 GitOps**
- **secrets 加密 GitOps**
- **硬件初始化 / 灾难恢复文档化**

---

## 八、Secrets 方案

### 1. 选型

- **sops + age**

### 2. age 私钥管理 SOP（强制要求）

#### age 私钥必须满足：

- 至少 **2 份离线副本**
- 与主工作机分开放置
- 有明确恢复说明
- 有泄露后的重建流程

#### 推荐方案

- 主副本：你的主力电脑本地安全保存
- 副本 1：加密 U 盘，单独存放
- 副本 2：纸质恢复说明 + 公钥指纹 + 恢复步骤

#### 必须写成 Runbook 的内容

- 密钥生成方式
- 保存位置
- 如何验证可用性
- 丢失怎么办
- 泄露怎么办
- 如何 rekey
- 如何重新加密全部 secrets
- 如何轮换所有受影响的 API key / token

#### 轮换建议

- age 主密钥：至少每年复核一次
- API key / token：至少每年轮换一次，或在疑似泄露时立即轮换

### 3. Restic 仓库密码与 age 密钥的关系

Restic repo password **必须同时满足**以下条件：

- 作为 sops 加密的 secret 存入 `all.sops.yml`
- **同时**在 age 密钥的离线副本物理介质（加密 U 盘、纸质记录）中**独立保存一份**

原因：如果 age 密钥丢失，但 Restic 密码可用，你仍然可以直接恢复备份数据（Restic 不需要 age 解密，只需 repo password）。这是最后一道恢复防线。

### 4. 仓库布局

- `inventory/prod/group_vars/all.sops.yml`

### 5. 落地约束

部署时解密到目标机：

- `/opt/<service>/.env`
- 权限 `0600`
- 仅 root 可读

禁止：

- 把 secrets 打进镜像
- 把 secrets 写入日志
- 在 CI 日志里输出 secrets

---

## 九、备份与恢复方案

### 1. 原则

> **RAID ≠ 备份**

> **没有演练过的恢复，不算真正可恢复。**

> **3-2-1 原则：至少 3 份副本、2 种存储介质、1 份异地保存。**

在本方案中：
- 副本 1：NAS `/data` 上的原始数据
- 副本 2：NAS 本地 Restic 仓（同机不同目录，应对误删/配置回滚）
- 副本 3：异地对象存储（应对整机损毁/灾难）

### 2. 工具

- **Restic**

### 3. 备份目标

#### 本地备份仓

- 路径：`/data/backups/restic`

用途：快速恢复、单文件/单服务恢复、短期版本保留

#### 异地备份仓

- 推荐：Backblaze B2 或任意 S3 兼容对象存储
- 成本参考：B2 约 $5/TB/月

用途：防整机损坏、防误删、防灾难性事故

#### v3.1 新增：异地仓防勒索加固

建议在 B2/S3 上启用 Object Lock（对象锁定）：

- 防止攻击者通过 NAS 上的 Restic 凭据删除异地备份
- 设置保留期（如 30 天），在此期间对象无法被删除或覆盖
- 这是应对勒索软件的最后防线

### 4. 备份范围

#### 必须备份

- `/etc`
- `/boot`
- `/opt`
- compose 文件实际下发目录
- 业务数据卷
- 数据库 dump（备份前先 `pg_dump` / `redis-cli BGSAVE`）
- GitOps 仓库镜像/导出
- Restic 仓库凭据
- age 恢复材料
- Runbooks

#### 系统盘关键补充

- 分区表导出：`sfdisk -d /dev/sda > sda-partition-table.dump`
- UEFI 启动信息说明
- 恢复 U 盘制作说明

#### 不必重点备份

- Docker 镜像层本体
- 可重新拉取的构件
- 临时缓存
- 非关键临时日志

### 5. v3.1 新增：备份前置检查

Restic 备份脚本在执行备份前，必须先检查：

1. RAID 状态是否正常（`/proc/mdstat` 是否 `[UU]`）
2. `/data` 是否正常挂载
3. 数据库服务是否正常（如有）

任何一项失败，跳过本次备份并立即告警，避免将损坏数据写入备份。

### 6. 恢复演练要求

至少要完成并记录以下演练：

1. 恢复单个配置文件
2. 恢复单个服务
3. 恢复数据库
4. 恢复 secrets
5. 系统盘故障后从裸机恢复基础系统
6. 恢复到"能重新部署所有服务"的状态

### 7. 备份保留策略

- 最近 7 天日备份
- 最近 4 周周备份
- 最近 6~12 月月备份

### 8. 备份验证

- 定期 `restic check`（每月）
- 定期随机恢复验证（每季度）
- 备份失败立即告警

---

## 十、系统盘单点故障应对

### 1. 现实

- 数据盘有 RAID1
- 系统盘没有冗余
- 系统盘坏了，整机短期不可用

### 2. 处理策略

不重构成系统盘镜像（增加复杂度，非当前优先级），但必须补齐恢复能力：

- 系统盘关键内容纳入 Restic
- 裸机安装 SOP
- 恢复 U 盘
- 引导恢复说明
- `bootstrap.sh`（纯 Shell 最小引导：裸机 Debian → 能跑 Ansible）
- 重装后拉起 Ansible 的最小 bootstrap 步骤
- age 私钥恢复链路

### 3. 恢复目标

> 系统盘坏了以后，能在可接受时间内（目标 < 2 小时）从文档和备份里把机器恢复回来。

---

## 十一、日志策略

### 1. Docker 日志轮转（硬要求）

在 Ansible baseline 中配置 `/etc/docker/daemon.json`：

```json
{
  "log-driver": "local",
  "log-opts": {
    "max-size": "50m",
    "max-file": "3"
  }
}
```

### 2. 第一阶段

- 容器日志走 stdout/stderr
- Docker daemon 做日志轮转
- 关键业务日志保存在受控卷内
- 不上 Loki

### 3. 第二阶段

服务增多后按需引入 Loki + Promtail。

---

## 十二、监控与告警方案

### 1. 第一阶段目标

只追求把最关键风险监控起来：

- 服务是否存活
- RAID 是否降级
- SMART 是否异常
- 磁盘空间是否不足
- 备份是否成功
- 温度是否异常
- 时间同步是否异常
- EasyTier 是否可达

### 2. 第一阶段实现

- **Uptime Kuma**：服务可用性和基础告警
- 告警脚本（`scripts/alerts/`）+ systemd timer

#### 告警脚本框架

```text
scripts/alerts/
├── notify.sh              # 统一告警发送（支持 Telegram / ntfy / 邮件）
├── check-smart.sh         # SMART 异常检测
├── check-raid.sh          # RAID 降级检测
├── check-disk-space.sh    # 磁盘空间检测（阈值 85%）
├── check-backup.sh        # 备份执行结果检测
├── check-temp.sh          # 温度异常检测
└── check-easytier.sh      # EasyTier 连通性检测
```

每个脚本遵循统一模式：检查 → 判断 → 调用 `notify.sh` 发送告警。
通过 systemd timer 定时执行。

### 3. 告警通道

至少一条要落地（Telegram / ntfy / 邮件）。关键告警建议双通道。

### 4. 第二阶段

确实需要历史指标和趋势分析时，按需加入 node_exporter + Prometheus + Grafana + Alertmanager。

---

## 十三、反向代理与网络暴露

### 1. 反向代理

- **Caddy**

### 2. 零公网暴露约束（准确定义）

**"零公网暴露"特指零入站暴露：**

- 严禁把 NAS 管理面或业务面暴露到公网
- 严禁在家庭主路由做端口映射 / 端口转发 / DMZ
- 严禁依赖公网入口作为常规运维路径

**NAS 主动出站是允许的：**

- apt 安全更新
- Docker 镜像拉取
- Restic → B2/S3 异地备份上传
- GitHub API 调用（CI 状态查询等）

### 3. 访问路径

NAS 服务访问路径只允许：

- 家庭内网
- EasyTier 虚拟专网

### 4. 服务暴露原则

- SSH：仅内网 / EasyTier
- Caddy HTTP/HTTPS：仅内网 / EasyTier
- 管理面板（Grafana / Prometheus / Uptime Kuma）：仅内网 / EasyTier
- Docker socket：绝不暴露
- 数据库端口：绝不暴露

### 5. v3.1 新增：Caddy 绑定地址约束

Caddy 必须**显式绑定**到 LAN IP 和/或 EasyTier 接口 IP，**禁止使用 `0.0.0.0`**。

示例 Caddyfile：

```
{
  # 绑定到 LAN IP 和 EasyTier IP
  # 根据实际网络情况调整
}

192.168.50.10:443, <easytier-ip>:443 {
  # ...
}
```

配合 nftables 规则形成纵深防御：即使防火墙配置失误，Caddy 本身也不会在非预期接口上监听。

### 6. 防火墙策略（nftables）

Ansible baseline 中配置：

- **默认策略**：`INPUT DROP`、`FORWARD DROP`、`OUTPUT ACCEPT`
- **放行规则**：
  - Loopback
  - 已建立连接（ESTABLISHED, RELATED）
  - ICMP（按需）
  - 来自家庭内网网段的 SSH / HTTP / HTTPS
  - 来自 EasyTier 虚拟网段的 SSH / HTTP / HTTPS
  - EasyTier 本身需要的节点通信端口
- **禁止**：
  - 所有来自公网的不必要入站
  - UPnP
  - 未授权入站

### 7. 路由器策略

家庭主路由必须遵守：

- 不对 NAS 做端口映射
- 不对 NAS 做 DMZ
- 不使用 UPnP 自动开口

### 8. 远程入口

- **EasyTier** 是唯一远程管理入口
- 家中本地时走 LAN
- 出门在外时走 EasyTier

### 9. v3.1 新增：EasyTier 不可用时的应急方案

EasyTier 是唯一远程路径，一旦不可用需要有后备方案：

- **场景 1：EasyTier 进程崩溃 / 配置损坏**
  → 在 `docs/runbooks/remote-recovery.md` 中记录：远程指导家人物理接触 NAS 重启 EasyTier 的步骤
- **场景 2：EasyTier 网络层不通**
  → 如果家中有第二台长期在线设备（路由器上的 EasyTier / 另一台 PC），可以通过它做跳板 SSH 到 NAS
- **场景 3：完全无法远程**
  → 接受这个风险，等回家处理。记录恢复步骤以缩短回家后的处理时间
- **缓解措施**：`check-easytier.sh` 告警脚本定时检测 EasyTier 连通性，断开时立即告警

---

## 十四、AI runtime / openclaw 方案

### 1. 态度

保留抽象层，但实现上不复杂化。

### 2. 第一阶段做法

直接部署 openclaw 或其他选定的 claw/runtime。

### 3. 仓库结构

使用 `compose/apps/ai-runtime/`，当前实现为 openclaw。未来替换不推翻结构。

### 4. 第一阶段不做

- 多 provider 智能路由
- 熔断 / 高级限流
- 自研统一网关 / 策略引擎

### 5. 第一阶段必须保留

- 基础认证
- 配置与 secrets 分离
- 健康检查
- 清晰的版本固定
- 可回滚部署
- 默认仅内网 / EasyTier 可访问

---

## 十五、资源规划

正式落地前必须补充资源预算，确认硬件能承载所有计划服务。

### 1. 硬件信息

| 项目 | 当前值（待填写） |
|------|------------------|
| CPU 型号 / 核心数 | |
| 内存大小 | |
| 系统盘类型 / 大小 | ~1TB（sda） |
| 数据盘类型 / 大小 | 2x ~8TB HDD RAID1 |
| 网络带宽 | |
| EasyTier 运行位置 | |

### 2. 第一阶段服务资源估算

| 服务 | 预估内存占用 | 说明 |
|------|-------------|------|
| Debian 基础系统 | ~300-500MB | 含 systemd、SSH 等 |
| Docker daemon | ~100-200MB | 守护进程本身 |
| Caddy | ~30-50MB | 轻量反向代理 |
| Uptime Kuma | ~100-200MB | 含 SQLite |
| Restic 任务 | ~200-500MB（峰值） | 仅备份运行期间 |
| openclaw / AI runtime | ~200-500MB（视实现） | 需实测确认 |
| Redis（如需） | ~50-100MB | 取决于数据量 |
| PostgreSQL（如需） | ~100-300MB | 取决于负载 |
| **第一阶段合计** | **~1-2.5GB** | 建议主机至少 8GB 内存 |

> [!IMPORTANT]
> 后续升级 Prometheus 全家桶额外需要 ~1-2GB。部署前务必确认余量。

---

## 十六、CI / 部署 / 回滚

### 1. CI 第一阶段

- `yamllint`
- `ansible-lint`
- `shellcheck`
- `shfmt`
- `docker compose config`
- `gitleaks`

不引入 conftest / OPA。

### 2. 策略检查

用一个 Shell 脚本 `policy/check-compose-policy.sh` 完成所有检查：

- 禁止 `latest` tag
- 必须存在 `healthcheck`
- 必须存在 `restart`
- 禁止暴露不该暴露的端口
- 禁止 `0.0.0.0` 绑定或未指定绑定地址的端口映射（Docker 默认为 `0.0.0.0`）

> 等仓库内 Compose 文件数量超过 5 个再考虑拆分为多个脚本。

### 3. 部署流程

1. 本地改动
2. 发 PR
3. CI 通过
4. Review
5. 合并到 `main`
6. 手动批准部署生产
7. 执行 `deploy`
8. 执行 `verify`
9. 成功后打 tag

### 4. v3.1 新增：CI→CD 部署执行路径

GitHub Actions CI 运行在云端，NAS 不暴露公网。部署动作的执行路径为：

> **你的开发机 → 通过 LAN 或 EasyTier SSH 到 NAS → 执行 `ansible-playbook deploy.yml`**

具体步骤：

1. GitHub CI 全部通过，PR 合并到 `main`
2. 你在开发机上 `git pull` 最新 `main` 分支
3. 确认部署时间窗口
4. 通过 LAN 或 EasyTier 执行部署：
   ```bash
   ansible-playbook -i inventory/prod ansible/playbooks/deploy.yml
   ```
5. 部署后执行验证：
   ```bash
   ansible-playbook -i inventory/prod ansible/playbooks/verify.yml
   ```
6. 验证通过后打 tag：
   ```bash
   git tag deploy-$(date +%Y%m%d-%H%M)
   git push origin --tags
   ```

此路径不需要：
- NAS 上运行 self-hosted GitHub Actions runner
- NAS 暴露任何公网端口
- NAS 主动轮询 GitHub

### 5. 回滚策略

#### 配置回滚
- `git revert` 到上一个稳定状态
- 重新执行部署

#### 版本管理
- 每次生产成功部署后打 Git tag
- 格式：`deploy-YYYYMMDD-HHMM`

#### 服务回滚
- Compose 文件固定镜像版本或 digest
- 回滚时切回上一个已知正常 tag

#### 数据回滚
- 由 Restic / 数据库备份承担
- 有独立 Runbook

---

## 十七、v3.1 新增：NAS 本地 Git 仓库镜像

### 为什么需要

如果 GitHub 不可达（出站网络故障），NAS 上应有仓库镜像，至少能做紧急参照和回滚。

### 实现

- 在 NAS 上维护一份 `git clone --mirror`：
  ```bash
  git clone --mirror git@github.com:<user>/nas-gitops.git /opt/nas-gitops-mirror
  ```
- 通过 systemd timer 每天同步一次：
  ```bash
  cd /opt/nas-gitops-mirror && git remote update
  ```
- 此镜像为只读参考，不用于日常操作

### 用途

- GitHub 不可达时的紧急 fallback
- 紧急回滚时的快速参照
- 灾难恢复时的配置来源

---

## 十八、仓库结构

```text
nas-gitops/
├── README.md
├── docs/
│   ├── architecture/
│   ├── runbooks/
│   ├── standards/
│   └── adr/
├── inventory/
│   └── prod/
├── ansible/
│   ├── playbooks/
│   └── roles/
├── compose/
│   ├── platform/
│   │   ├── caddy/
│   │   └── uptime-kuma/
│   └── apps/
│       └── ai-runtime/
├── scripts/
│   ├── bootstrap.sh       # 裸机 → 能跑 Ansible 的最小引导
│   └── alerts/             # 统一告警脚本
├── tests/
├── policy/
│   └── check-compose-policy.sh   # 统一策略检查
└── .github/workflows/
```

### 说明

- 不在第一阶段维护 `lab/` 环境
- 备份（Restic）通过 Ansible role + systemd timer 管理，不放在 `compose/platform/` 中
- 策略检查先用一个脚本统一处理，规模上来再拆分

### 目录职责

#### `inventory/prod/`
NAS 清单与变量

#### `ansible/playbooks/`
至少包括：

- `bootstrap.yml`
- `baseline.yml`
- `docker.yml`
- `backup.yml`
- `monitoring.yml`
- `deploy.yml`
- `verify.yml`
- `rollback.yml`

#### `compose/platform/`
平台服务：`caddy/`、`uptime-kuma/`

#### `compose/apps/`
业务服务：`ai-runtime/`

#### `scripts/alerts/`
告警脚本集合，统一调用 `notify.sh` 发送。

#### `scripts/bootstrap.sh`
纯 Shell 最小引导脚本，覆盖"裸机 Debian → 能跑 Ansible"的最小路径：

1. 安装 Python3、pip
2. 安装 Ansible
3. 配置 SSH 免密或 deploy key
4. 从 Git mirror 或 GitHub 克隆仓库
5. 提示执行 `ansible-playbook bootstrap.yml`

#### `docs/runbooks/`

分两批交付：

**M0-M2 优先交付（5 个最关键）：**

- `age-key-recovery.md`
- `bootstrap-host.md`
- `backup-restore.md`
- `system-disk-recovery.md`
- `no-public-exposure.md`

**M3-M4 逐步补充：**

- `deploy-service.md`
- `rollback.md`
- `disk-failure.md`
- `raid-degraded.md`
- `secrets-rotation.md`
- `remote-recovery.md`（含 EasyTier 不可用应急方案）
- `ups-power-event.md`
- `debian-upgrade.md`
- `easytier-access-policy.md`

---

## 十九、家用 NAS 容易遗漏的点

### 1. UPS

如有 UPS：纳管 NUT、低电量自动关机、掉电告警、来电恢复策略。
如没有：进入待办优先级。

### 2. SMART 自检

- short test：每周
- long test：每月

### 3. RAID 巡检

- mdadm monitor
- mdcheck timer
- RAID 降级告警

### 4. Docker 日志轮转

必须项，不再可选。

### 5. 系统盘恢复材料

- 恢复 U 盘
- 分区表导出
- 引导恢复说明
- age 密钥恢复材料
- `bootstrap.sh`

### 6. 换盘预案

- 记录当前盘型号
- 记录采购渠道
- 评估冷备盘策略
- 编写换盘 SOP

### 7. 更新策略

- Debian 安全更新：偏自动（`unattended-upgrades` 仅安全源）
- Docker / 平台组件：半自动（Dependabot PR → CI → 手动合并）
- AI runtime / 业务服务：PR + CI + 手动批准

### 8. Debian 大版本升级策略

- 先在测试 VM 上验证升级流程
- 确认关键包兼容性
- 升级前做全量备份（本地 + 异地）
- 升级后执行 `verify.yml` 验证基线
- 编写 Runbook

### 9. 零入站暴露原则

- 不开放家庭主路由端口映射
- 不开放公网 SSH / 80 / 443
- 不因图省事破坏"LAN / EasyTier only"原则
- 出站允许

### 10. Docker network 隔离

建议每个 Compose stack 使用独立的 Docker network，避免服务间不必要的网络互通。

---

## 二十、实施路线图

### M0：仓库与安全基础（1~2 天）

交付：

- GitHub 仓库、README、PR 模板、CODEOWNERS
- 基础 CI（yamllint + ansible-lint + shellcheck + docker compose config + gitleaks）
- `.sops.yaml` + age 密钥生成与离线备份 SOP
- `bootstrap.sh`（纯 Shell 最小引导脚本）
- "零入站暴露"策略文档
- CI→CD 部署路径文档

优先 Runbook：
- `age-key-recovery.md`
- `no-public-exposure.md`

### M1：主机基线（3~5 天）

交付：

- Ansible baseline
- SSH hardening（禁用密码登录、限制 root、仅内网/EasyTier 放行）
- nftables 防火墙
  - 默认策略：INPUT DROP、FORWARD DROP、OUTPUT ACCEPT
  - 放行：内网/EasyTier 来源的 SSH、HTTP、HTTPS
  - 放行：EasyTier 节点通信端口
  - 禁止：UPnP、未授权入站
- Docker（含 daemon.json 日志轮转）
- NTP
- smartmontools（short 每周、long 每月）
- mdadm monitor + 降级告警
- EasyTier 纳管（如需）
- NAS 本地 Git mirror + cron 每日同步
- 系统盘关键内容备份脚本

优先 Runbook：
- `bootstrap-host.md`
- `system-disk-recovery.md`

### M2：备份与轻量监控（3~5 天）

交付：

- Restic 本地仓：`/data/backups/restic`
- Restic 异地仓：B2/S3（评估 Object Lock）
- 备份脚本 + 前置检查 + systemd timer
- Uptime Kuma（Docker 部署）
- 告警脚本框架（`scripts/alerts/`）全部到位
- UPS/NUT（如果已有 UPS）

优先 Runbook：
- `backup-restore.md`

### M3：平台入口与 AI 服务（3~5 天）

交付：

- Caddy（显式绑定 LAN/EasyTier IP）
- openclaw / claw runtime / AI runtime
- `deploy.yml` + `verify.yml` + `rollback.yml`
- 生产部署 tag 机制
- 访问控制验证：确保服务仅 LAN/EasyTier 可达

补充 Runbook：
- `deploy-service.md`
- `rollback.md`

### M4：恢复演练与加固（持续）

交付：

- 系统盘故障恢复演练
- secrets 轮换演练
- 备份恢复演练
- EasyTier 故障场景应急演练
- 漂移检测（`ansible --check --diff`）
- 公网暴露自检清单
- 换盘预案
- 资源预算页补全
- 补齐剩余所有 Runbook

---

## 二十一、最终决策清单

### 保留
- Debian 13 + `mdadm RAID1 + ext4`
- Ansible + Docker Compose
- GitHub + GitHub Actions
- sops + age
- Restic
- EasyTier

### 第一阶段采用
- Caddy（绑定 LAN/EasyTier IP）
- Uptime Kuma
- Shell 策略检查 + 告警脚本
- `ansible --check --diff` 漂移检查
- nftables 零入站暴露策略
- NAS 本地 Git mirror
- `bootstrap.sh` 最小引导脚本

### 第一阶段暂缓
- Traefik / Prometheus 全家桶 / Loki
- Go 工具 / OPA / conftest
- 长期 lab 环境
- 复杂 AI gateway 编排
- Tailscale / 公网入口方案

### 必须新增
- age 私钥管理 SOP
- Restic repo password 独立离线保存
- 异地备份目标（B2/S3）+ Object Lock 评估
- 系统盘恢复 SOP
- Docker 日志轮转
- 资源预算页
- 换盘预案
- 防火墙规则 + Caddy 绑定约束
- 告警脚本框架（含 EasyTier 检测）
- CI→CD 部署执行路径文档
- "零入站暴露"准确定义文档
- EasyTier 不可用应急方案
- NAS 本地 Git mirror
- `bootstrap.sh`
- Debian 升级策略

---

## 二十二、最终结论

这台 NAS 现在最值得做的，不是继续纠结底层存储，也不是堆更多"看起来专业"的组件。

真正应该做的是：

1. 把这台 NAS 变成一台**受管主机**
2. 把 secrets、备份、恢复链路做扎实
3. 用 GitHub + Ansible + Compose 建立严格但轻量的 GitOps 流程
4. 把访问路径严格限制在**家庭内网 / EasyTier**
5. 在这个基础上，再部署 AI runtime / claw 类服务

最终方案可以概括成一句话：

> **保持底层简单，把恢复能力做硬，把自动化做稳，把暴露面压到最低，把复杂度延后。**

---

## 附：v3 → v3.1 变更记录

| 变更项 | 说明 |
|--------|------|
| 明确 CI→CD 部署路径 | 开发机 → SSH/EasyTier → NAS → `ansible-playbook deploy.yml` |
| 明确"零公网暴露"语义 | 特指零入站暴露，NAS 出站（apt/Docker pull/Restic→B2）允许 |
| Caddy 绑定地址约束 | 显式绑定 LAN/EasyTier IP，禁止 `0.0.0.0` |
| EasyTier 不可用应急方案 | Runbook 中记录三种场景的 fallback 策略 |
| `check-easytier.sh` | 从"可选"升级为"建议" |
| NAS 本地 Git mirror | `git clone --mirror` + cron 每日同步 |
| Restic 备份前置检查 | 检查 RAID/挂载状态后再备份 |
| Restic 异地仓 Object Lock | 建议启用，防勒索软件删除备份 |
| Restic repo password 独立保存 | 与 age 离线副本独立，作为最后恢复防线 |
| `bootstrap.sh` | 新增纯 Shell 最小引导脚本 |
| 策略检查脚本合并 | `policy/checks/` 4个脚本 → `check-compose-policy.sh` 1个 |
| 备份从 compose 改 systemd | Restic 不再放在 `compose/platform/backup/`，改为 Ansible role + systemd timer |
| Runbook 分批交付 | M0-M2 先写 5 个最关键的，其余逐步补充 |
| Docker network 隔离 | 建议每个 stack 使用独立网络 |
| Compose 端口绑定检查增强 | 增加检查未指定绑定地址的端口映射 |
