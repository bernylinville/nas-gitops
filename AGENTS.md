# AGENTS.md

This file provides guidance to AI coding agents (Claude Code, Codex,
Gemini, etc.) when working with this repository.

## Project Overview

| Field | Value |
|-------|-------|
| Project | nas-gitops |
| Type | Infrastructure-as-Code / GitOps |
| Target | Single-host home NAS (Debian 13) |
| Primary Language | Ansible (YAML) + Shell + Docker Compose |
| CI | GitHub Actions |
| Secrets | sops + age |

## Quick Start for Agents

1. Read `CLAUDE.md` for hard constraints and coding rules
2. Read `nas-gitops-plan-v3.1-2026-03-21.md` for architecture context
3. Check `docs/adr/` for recorded decisions before proposing alternatives
4. Check `docs/runbooks/` before writing operational procedures

## What You Can Safely Do

- Create/modify Ansible playbooks and roles under `ansible/`
- Create/modify Docker Compose files under `compose/`
- Create/modify shell scripts under `scripts/`
- Create/modify policy checks under `policy/`
- Create/modify documentation under `docs/`
- Create/modify CI workflows under `.github/workflows/`
- Run linting commands (ansible-lint, yamllint, shellcheck, etc.)
- Run `--check --diff` mode Ansible playbooks (dry-run)
- Run `docker compose config` to validate Compose files

## What You Must NOT Do

- **Never commit plaintext secrets** — Use sops + age only
- **Never expose services to 0.0.0.0** — Bind to LAN/EasyTier IPs only
- **Never add public internet access paths** — No port forwarding, no
  public DNS, no Tailscale
- **Never deploy directly** — All changes go through PR → CI → manual
  approval
- **Never modify inventory without understanding sops** — Encrypted
  files need `sops` to edit
- **Never use `latest` Docker image tags** — Pin versions or digests
- **Never use `yes`/`no` for YAML booleans** — Use `true`/`false`

## Coding Standards

### Ansible

- **FQCN mandatory**: `ansible.builtin.file` not `file`
- **Role variables**: prefix with role name (`baseline_ntp_servers`)
- **Internal variables**: prefix with `__` (`__baseline_packages`)
- **Task names**: imperative, with sub-task prefix
  (`install | Install required packages`)
- **Idempotency**: all playbooks safe to re-run
- **`changed_when:`**: required on all `command:` / `shell:` tasks
- **Loops**: `loop:` only, never `with_*`
- **YAML style**: 2-space indent, `true`/`false`, lines < 120 chars

### Docker Compose

- Pin image versions (no `latest`)
- Define `healthcheck` for every service
- Define `restart` policy for every service
- Bind ports to specific IPs, never `0.0.0.0`
- Environment files with mode `0600`

### Shell Scripts

- Pass `shellcheck` and `shfmt`
- Use `set -euo pipefail` at the top
- Exit codes: 0 = success, 1 = failure, 2 = invalid usage
- Alert scripts call `notify.sh` for unified notification

## Deployment Model

```
Developer Machine
       │
       │ git push → PR → CI (GitHub Actions, cloud)
       │
       │ CI passes, PR merged to main
       │
       │ Manual trigger: SSH via LAN or EasyTier
       ▼
NAS (192.168.x.x / EasyTier IP)
       │
       │ ansible-playbook deploy.yml
       │ ansible-playbook verify.yml
       │ git tag deploy-YYYYMMDD-HHMM
       ▼
    Services Running
```

**Key point**: CI runs in the cloud (GitHub Actions) for linting and
validation only. Actual deployment is triggered manually from the
developer's machine via SSH to the NAS.

## File Organization

| Path | Purpose | Language |
|------|---------|----------|
| `ansible/playbooks/` | Ansible playbooks | YAML |
| `ansible/roles/` | Ansible roles | YAML |
| `inventory/prod/` | Inventory + sops vars | YAML |
| `compose/platform/` | Platform services | YAML (Compose) |
| `compose/apps/` | Business services | YAML (Compose) |
| `scripts/bootstrap.sh` | Bare-metal bootstrap | Shell |
| `scripts/alerts/` | Alert/monitoring scripts | Shell |
| `policy/` | CI policy checks | Shell |
| `docs/runbooks/` | Operational procedures | Markdown |
| `docs/adr/` | Architecture decisions | Markdown |
| `.github/workflows/` | CI pipelines | YAML |
| `.claude/skills/` | AI agent skills | Markdown |

## Testing

All CI checks must pass before merge:

```bash
yamllint ansible/ inventory/
ansible-lint ansible/
shellcheck scripts/**/*.sh
shfmt -d scripts/
docker compose config    # for each compose file
gitleaks detect --source .
bash policy/check-compose-policy.sh
```

## Key Architecture Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Orchestration | Ansible + Docker Compose | Single host, simple, debuggable |
| Not K8s | Confirmed | Overkill for single home NAS |
| Reverse proxy | Caddy | Simpler config than Traefik for few services |
| Monitoring | Uptime Kuma + scripts | Lighter than Prometheus stack |
| Secrets | sops + age | Git-friendly, offline-capable, no server needed |
| Remote access | EasyTier | Already deployed, no redundant VPN |
| Backup | Restic → local + B2 | 3-2-1 principle |
| Network | Zero inbound exposure | LAN + EasyTier only |

## Related Documents

- [CLAUDE.md](CLAUDE.md) — Detailed coding rules and commands
- [v3.1 Plan](nas-gitops-plan-v3.1-2026-03-21.md) — Full architecture plan
- [Skills](.claude/skills/) — AI agent skills for Ansible development
