# RAID 换盘 Runbook

> 适用场景：RAID1 中一块硬盘故障需要更换

## 前提条件

- RAID 处于 degraded 状态 (`[U_]` 或 `[_U]`)
- 已准备好同等大小的替换硬盘

## 步骤

### 1. 确认 RAID 状态

```bash
cat /proc/mdstat
mdadm --detail /dev/md0
```

### 2. 标记故障盘

```bash
# 确认哪块盘故障 (假设 /dev/sdc)
mdadm --manage /dev/md0 --fail /dev/sdc1
mdadm --manage /dev/md0 --remove /dev/sdc1
```

### 3. 物理更换硬盘

关机 → 更换硬盘 → 开机

### 4. 分区新盘

```bash
# 复制分区表从正常盘
sgdisk -R /dev/sdc /dev/sdb
sgdisk -G /dev/sdc
```

### 5. 重建 RAID

```bash
mdadm --manage /dev/md0 --add /dev/sdc1
```

### 6. 监控重建进度

```bash
watch cat /proc/mdstat
# 或
mdadm --detail /dev/md0
```

> ⚠️ 重建期间避免高 I/O 操作。7.3TB RAID1 重建约需 4-8 小时。

### 7. 验证

```bash
cat /proc/mdstat  # 确认 [UU]
smartctl -H /dev/sdc  # 检查新盘健康
```

## 重建时间参考

| 磁盘大小 | 预计时间 |
|----------|---------|
| 4TB | ~3-5 hours |
| 8TB | ~6-10 hours |
