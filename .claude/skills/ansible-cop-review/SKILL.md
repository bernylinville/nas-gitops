---
name: ansible-cop-review
description: >-
  Review Ansible code against Red Hat CoP automation good practices.
  Adapted for nas-gitops project: reviews playbooks, roles, and inventory
  in ansible/ and inventory/ directories. Use when the user wants to audit,
  lint, review, check, or validate Ansible code for compliance with CoP
  rules and project standards. Use when user says "lint my role", "check
  my playbook", "review best practices", or "audit ansible code".
  Do NOT use for Docker Compose or Shell script review.
argument-hint: "[path or files]"
user-invocable: true
metadata:
  author: Leonardo Gallego (original), adapted for nas-gitops
  version: 1.1.0
---

# Ansible CoP Review (nas-gitops adapted)

## Important

- Do NOT skip any rule category — check all of them (unless user
  requested a category filter).
- When a category does not apply (e.g., no templates exist), mark it N/A.
- Be precise about line numbers and file paths.
- This project is a **single-host NAS GitOps** project, NOT a collection.
  Skip collection-specific rules (galaxy.yml, semantic versioning, etc.).

## Project context

This is a **nas-gitops** repository with this structure:

```
ansible/
├── playbooks/     # bootstrap.yml, baseline.yml, docker.yml, etc.
└── roles/         # Custom roles for NAS management
inventory/
└── prod/          # Production NAS inventory + sops vars
compose/           # Docker Compose files (NOT Ansible)
scripts/           # Shell scripts (NOT Ansible)
```

Focus review on `ansible/` and `inventory/` only. Ignore `compose/`,
`scripts/`, and `policy/`.

## nas-gitops specific rules (in addition to CoP)

- All secrets MUST be in `inventory/prod/group_vars/all.sops.yml`, never
  in plaintext
- Playbooks MUST be idempotent — safe to re-run
- All service `.env` files must be deployed with `mode: '0600'`
- Docker daemon.json must include log rotation config
- nftables rules must default to INPUT DROP
- Services must bind to LAN/EasyTier IPs, never `0.0.0.0`
- Compose files referenced in playbooks must exist in `compose/`

## Review process

1. **Determine review mode** — full project, specific path, or diff-aware
   (run `git diff --name-only` for changed files).

2. **Discover scope** — Based on mode, identify `*.yml`/`*.yaml` files
   under `ansible/` and `inventory/`.

3. **Run ansible-lint** — If available, run and cross-reference with CoP
   rules. If unavailable, proceed with manual review only.

4. **Check every applicable rule category**:

   - **Role naming** — role-prefixed variables, `__` internal prefix,
     no dashes, snake_case
   - **Variable placement** — defaults vs vars, no user-facing vars in
     `vars/main.yml`
   - **Idempotency & check mode** — `changed_when:` on command/shell,
     re-run safety
   - **Argument validation** — `meta/argument_specs.yml` existence
   - **File references** — `{{ role_path }}` usage
   - **Templates** — `{{ ansible_managed | comment }}` header,
     `backup: true`
   - **Platform support** — `ansible_facts['...']` bracket notation
   - **YAML style** — 2-space indent, `true`/`false` booleans,
     line length under 120
   - **Naming** — `snake_case` everywhere, imperative task names
   - **Module usage** — FQCN, `loop:` over `with_*`
   - **Documentation** — README with examples
   - **Security** — secrets handling, file permissions, no plaintext
     credentials
   - **NAS-specific** — nftables rules, Docker config, service binding
     addresses

## Severity levels

- **ERROR** — Must fix. Violates a MUST/NEVER rule.
- **WARNING** — Should fix. Violates a best practice.
- **INFO** — Suggestion for improvement.

## Report format

Group findings by file, then by severity. For each violation:
- Severity: `[ERROR]`, `[WARNING]`, or `[INFO]`
- Rule being violated
- File path and line number
- Offending code snippet
- Corrected code

End with summary table and overall verdict.

## Auto-fix

After reporting, offer to automatically fix violations (ERRORs first,
then WARNINGs). Re-verify after fixing.
