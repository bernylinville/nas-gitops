---
name: ansible-scaffold-role
description: >-
  Scaffold a new Ansible role following Red Hat CoP good practices, adapted
  for the nas-gitops project. Creates roles under ansible/roles/ with
  NAS-specific patterns (Docker, systemd timers, nftables, Restic backup,
  sops secrets). Use when user says "create a role", "new role", "scaffold
  role", or "add ansible role". Do NOT use for reviewing existing roles
  (use ansible-cop-review instead).
argument-hint: "[role-name]"
disable-model-invocation: true
user-invocable: true
metadata:
  author: Leonardo Gallego (original), adapted for nas-gitops
  version: 1.1.0
---

# Ansible Scaffold Role (nas-gitops adapted)

Create a new Ansible role under `ansible/roles/` that complies with CoP
rules and follows nas-gitops project conventions.

## Project context

This is a **single-host NAS GitOps** project. Roles manage a Debian 13
NAS with:
- Docker Compose services
- systemd timers for scheduled tasks
- Restic backups
- sops + age encrypted secrets
- Caddy reverse proxy
- Access restricted to LAN / EasyTier only (no firewall)

## Gather inputs

If `$ARGUMENTS` is provided, use it as the role name. Otherwise ask.

Ask the user for:
1. **Role name** (snake_case, no dashes) — required
2. **Brief description** — what the role does
3. **What does the role manage?** Common NAS patterns:
   - **Packages** — installs/removes packages
   - **Services** — manages systemd services
   - **Docker services** — deploys Docker Compose stacks
   - **Configuration files** — manages config via templates
   - **Scheduled tasks** — manages systemd timers
   - **Backup tasks** — manages Restic backup jobs
   - **Custom** — user describes freely

## Scaffolding

Create the role at `ansible/roles/<role_name>/` with:

### `defaults/main.yml`
- All user-facing variables prefixed with role name
- Variables without safe defaults: commented out with description
- For Docker roles: include `<role>_image`, `<role>_version`,
  `<role>_compose_dir`, `<role>_data_dir`
- For service roles: include `<role>_service_name`,
  `<role>_service_state`, `<role>_service_enabled`

### `vars/main.yml`
- Internal constants prefixed with `__<role_name>_`
- NEVER user-facing defaults here

### `tasks/main.yml`
- Use FQCN for all modules
- Use `loop:` not `with_*`
- All task names in imperative form
- Split into component files if the role manages multiple concerns:
  - `tasks/install.yml` — package installation
  - `tasks/configure.yml` — configuration/templates
  - `tasks/service.yml` — service management
  - `tasks/docker.yml` — Docker Compose deployment
  - `tasks/backup.yml` — backup job setup

### NAS-specific task patterns

For **Docker Compose services**, include:
```yaml
- name: "deploy | Create compose directory"
  ansible.builtin.file:
    path: "{{ <role>_compose_dir }}"
    state: directory
    mode: '0755'

- name: "deploy | Deploy compose file"
  ansible.builtin.template:
    src: docker-compose.yml.j2
    dest: "{{ <role>_compose_dir }}/docker-compose.yml"
    mode: '0644'
    backup: true
  notify: Restart <role>

- name: "deploy | Deploy environment file"
  ansible.builtin.template:
    src: env.j2
    dest: "{{ <role>_compose_dir }}/.env"
    mode: '0600'
    backup: true
  notify: Restart <role>
  no_log: true
```

For **systemd timers**, include:
```yaml
- name: "timer | Deploy systemd timer"
  ansible.builtin.template:
    src: "{{ item }}.j2"
    dest: "/etc/systemd/system/{{ item }}"
    mode: '0644'
  loop:
    - "<role>.service"
    - "<role>.timer"
  notify: Reload systemd

- name: "timer | Enable and start timer"
  ansible.builtin.systemd:
    name: "<role>.timer"
    enabled: true
    state: started
    daemon_reload: true
```

### `handlers/main.yml`
Generate real handlers based on role purpose:
- Docker roles: `Restart <role>` using `community.docker.docker_compose_v2`
- Service roles: `Restart <role>` and `Reload <role>`
- Timer roles: `Reload systemd`
- Config roles: validate config then restart

### `meta/main.yml`
Role metadata: author, description, license, min_ansible_version,
platforms (Debian 13).

### `templates/`
Include `{{ ansible_managed | comment }}` header in all templates.
Use `backup: true` in corresponding tasks.

### `molecule/default/`

Always scaffold Molecule test structure:

`molecule.yml`:
```yaml
---
dependency:
  name: galaxy
  options:
    requirements-file: ${MOLECULE_PROJECT_DIRECTORY}/../../../requirements.yml
    force: false
driver:
  name: docker
platforms:
  - name: "nas-<role>-test"
    image: "geerlingguy/docker-debian13-ansible:latest"
    command: ""
    pre_build_image: true
    privileged: true
    cgroupns_mode: host
    tmpfs:
      - /run
      - /tmp
    volumes:
      - /sys/fs/cgroup:/sys/fs/cgroup:rw
provisioner:
  name: ansible
  env:
    ANSIBLE_ROLES_PATH: "${MOLECULE_PROJECT_DIRECTORY}/.."
  playbooks:
    converge: converge.yml
    verify: verify.yml
  inventory:
    host_vars:
      nas-<role>-test:
        # role-specific test variables
verifier:
  name: ansible
```

`converge.yml` must include systemd pre_tasks:
```yaml
---
- name: Converge
  hosts: all
  become: true
  gather_facts: true
  pre_tasks:
    - name: "Pre | Update apt cache"
      ansible.builtin.apt:
        update_cache: true
        cache_valid_time: 600
    - name: "Pre | Install systemd"
      ansible.builtin.apt:
        name: [systemd, python3]
        state: present
    - name: "Pre | Wait for systemd"
      ansible.builtin.command:
        cmd: systemctl is-system-running
      register: __systemctl_status
      until: >
        'running' in __systemctl_status.stdout or
        'degraded' in __systemctl_status.stdout
      retries: 30
      delay: 5
      changed_when: false
      failed_when: __systemctl_status.rc > 1
  roles:
    - role: <role_name>
```

### `README.md`
- Role description
- Requirements
- Role variables (from defaults/main.yml)
- Example playbook
- Dependencies
- License and author

## Post-scaffold validation

Verify:
- No dashes in role name
- All variables role-name prefixed
- Internal variables use `__` prefix
- All task names imperative with `"Prefix | Description"` format
- All modules use FQCN
- YAML: 2-space indent, `true`/`false` booleans
- Secrets use `no_log: true`
- File permissions: `.env` files are `0600`
- Molecule converge.yml has systemd pre_tasks
- Molecule molecule.yml uses `MOLECULE_PROJECT_DIRECTORY` for roles_path
