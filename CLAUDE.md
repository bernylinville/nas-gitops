# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) and other AI
coding agents when working with code in this repository.

## What This Repository Is

A **GitOps repository** for managing a single-host home NAS running
Debian 13 (trixie). It uses Ansible for host configuration, Docker Compose
for service orchestration, and GitHub Actions for CI. All changes go through
PR review and CI before deployment.

## Repository Structure

```
nas-gitops/
├── ansible/
│   ├── playbooks/          # baseline.yml, docker.yml, backup.yml, verify.yml, bootstrap.yml
│   └── roles/              # baseline, docker, monitoring, restic
├── compose/
│   └── platform/           # Platform services (caddy, uptime-kuma)
├── inventory/
│   └── prod/               # Production inventory + sops-encrypted vars
├── scripts/
│   ├── bootstrap.sh        # Bare-metal → Ansible-ready bootstrap
│   └── alerts/             # notify.sh + check-{smart,raid,disk,backup}.sh
├── policy/
│   └── check-compose-policy.sh  # Docker Compose policy checks
├── docs/
│   ├── runbooks/           # disaster-recovery, disk-replacement, restore-from-backup
│   └── development-roadmap.md  # SSOT: project status + NAS state
├── .claude/skills/         # AI agent skills (ansible-cop-review, scaffold-role, zen, context7)
└── .github/workflows/      # CI: ci.yml, molecule.yml, deploy-test.yml
```

## Key Commands

### Linting

```bash
# Ansible
ansible-lint ansible/
yamllint ansible/ inventory/

# Shell scripts
shellcheck scripts/**/*.sh
shfmt -d scripts/

# Docker Compose
docker compose -f compose/platform/caddy/docker-compose.yml config
docker compose -f compose/platform/uptime-kuma/docker-compose.yml config

# Secrets leak check
gitleaks detect --source .

# Policy check
bash policy/check-compose-policy.sh
```

### Deployment (from dev machine via SSH/EasyTier to NAS)

```bash
# Deploy (按顺序)
ansible-playbook -i inventory/prod ansible/playbooks/baseline.yml
ansible-playbook -i inventory/prod ansible/playbooks/docker.yml
ansible-playbook -i inventory/prod ansible/playbooks/backup.yml

# Verify
ansible-playbook -i inventory/prod ansible/playbooks/verify.yml

# Drift check
ansible-playbook -i inventory/prod ansible/playbooks/baseline.yml --check --diff
```

### Secrets (sops + age)

```bash
# Edit secrets
sops inventory/prod/group_vars/all.sops.yml

# Encrypt new file
sops -e -i inventory/prod/group_vars/all.sops.yml

# Decrypt for inspection (DO NOT COMMIT)
sops -d inventory/prod/group_vars/all.sops.yml
```

## Hard Constraints

These rules are non-negotiable. Every piece of code in this repo must
comply:

### Security

1. **Zero inbound exposure** — NAS services are NEVER exposed to the
   public internet. No port forwarding, no DMZ, no UPnP.
2. **Access paths** — Only home LAN and EasyTier VPN. No Tailscale, no
   public SSH.
3. **Secrets** — All secrets in `all.sops.yml` via sops + age. NEVER
   plaintext in Git. NEVER in CI logs.
4. **File permissions** — `.env` files deployed with mode `0600`,
   root-only readable.
5. **Docker socket** — NEVER exposed.
6. **Service binding** — Services bind to specific LAN/EasyTier IPs,
   NEVER `0.0.0.0`.

### Ansible Rules

7. **FQCN** — All modules MUST use fully qualified collection names
   (e.g., `ansible.builtin.file`, NOT `file`).
8. **Booleans** — Use `true`/`false`, NEVER `yes`/`no`.
9. **Variables** — Role variables prefixed with role name. Internal
   vars use `__` prefix. User-facing vars in `defaults/`, NOT `vars/`.
10. **Idempotency** — All playbooks MUST be safe to re-run.
    `changed_when:` required on `command:`/`shell:` tasks.
11. **Task names** — Imperative form, descriptive. Use sub-task prefixes
    matching file name (e.g., `install | Install packages`).
12. **Loops** — Use `loop:`, NOT `with_*`.
13. **YAML** — 2-space indent. Line length under 120 chars.
14. **Templates** — Include `{{ ansible_managed | comment }}` header.
    Use `backup: true` in template tasks.

### Docker Compose Rules

15. **No `latest` tag** — All images must pin version or digest.
16. **Healthcheck** — All services must define `healthcheck`.
17. **Restart policy** — All services must define `restart`.
18. **Port binding** — No `0.0.0.0` binding. Use specific IPs or omit
    host binding for internal services.
19. **Log rotation** — Docker daemon configured with `max-size: 50m`,
    `max-file: 3`.

### GitOps Rules

20. **All changes via PR** — No direct commits to `main`.
21. **CI must pass** — Merge only after CI checks pass.
22. **Deploy tags** — Tag every successful production deployment:
    `deploy-YYYYMMDD-HHMM`.
23. **Manual deploy approval** — Production deployment requires manual
    trigger, not auto-deploy on merge.

## Skills

This project includes AI agent skills in `.claude/skills/`:

- **ansible-cop-review** — Review Ansible code against CoP rules +
  NAS-specific constraints
- **ansible-scaffold-role** — Create new roles with NAS patterns
  (Docker, systemd, Restic) + Molecule scaffold
- **ansible-zen** — Zen of Ansible philosophical review
- **context7-cli** — Fetch up-to-date Ansible/Docker/systemd documentation

## Architecture Decisions

See `docs/adr/` for recorded architecture decisions. Key decisions:

- Ansible + Docker Compose (not Kubernetes)
- Caddy (not Traefik) for reverse proxy
- Uptime Kuma + shell scripts (not Prometheus stack) for monitoring
- sops + age (not Vault) for secrets
- EasyTier (not Tailscale) for remote access
- Restic (not Borg) for backup
