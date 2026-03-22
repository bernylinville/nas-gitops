---
name: context7-cli
description: >-
  Use Context7 CLI to fetch up-to-date library documentation for Ansible,
  Docker, systemd, and other NAS-related technologies. Activate when you
  need current docs for any library, want to verify API signatures, or
  when training data may be outdated. Also manages AI coding skills.
  Use when developing new roles, debugging module usage, or verifying
  best practices against official documentation.
metadata:
  version: 1.0.0
---

# Context7 CLI — Fetch Latest Documentation

## Setup

The API key is pre-configured for this project:

```bash
export CONTEXT7_API_KEY=ctx7sk-5278f331-8936-415e-bd87-82aa538045e4
```

Ensure the CLI is available:

```bash
npx ctx7@latest <command>
# or if installed globally:
ctx7 <command>
```

## Documentation Lookup (2-step process)

### Step 1: Resolve library ID

```bash
ctx7 library <name> <query>
```

Example:
```bash
ctx7 library ansible "deb822_repository module"
# Returns: /websites/ansible_ansible (65K+ snippets)
```

### Step 2: Fetch docs

```bash
ctx7 docs <libraryId> <query>
```

Example:
```bash
ctx7 docs /ansible/ansible-documentation "role best practices molecule"
ctx7 docs /websites/ansible_ansible "systemd module timer"
```

## Pre-resolved Library IDs for This Project

| Library | Context7 ID | Snippets |
|---------|-------------|----------|
| Ansible (full docs) | `/websites/ansible_ansible` | 65K+ |
| Ansible (official docs) | `/ansible/ansible-documentation` | 5.5K+ |
| Ansible (core source) | `/ansible/ansible` | 192 |

## When to Use

- **Before writing new modules/tasks**: Verify module parameters and
  syntax with latest docs
- **When debugging task failures**: Check if module behavior has changed
  in recent versions
- **When developing roles**: Look up best practices for role structure,
  variable naming, molecule testing
- **When unsure about FQCN**: Find the correct fully qualified
  collection name for a module
- **When referencing Docker/systemd**: Look up Docker CLI or systemd
  unit file options

## Skills Management

```bash
ctx7 skills search <keywords>    # Search skill registry
ctx7 skills list                 # List installed skills
ctx7 skills suggest              # Auto-suggest based on project
```
