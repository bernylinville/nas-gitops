#!/usr/bin/env bash
# bootstrap.sh — Bare-metal Debian → Ansible-ready bootstrap
# Run this on the NAS directly if Ansible is not yet usable
set -euo pipefail

echo "=== NAS GitOps Bootstrap ==="
echo "This script prepares a bare Debian 13 system for Ansible management."
echo ""

# Check we're running as root
if [[ $EUID -ne 0 ]]; then
  echo "ERROR: This script must be run as root (sudo ./bootstrap.sh)"
  exit 1
fi

# Step 1: Install Python3 and essentials
echo "[1/5] Installing Python3 and essential packages..."
apt-get update -qq
apt-get install -y -qq python3 python3-pip python3-apt sudo curl git openssh-server

# Step 2: Create deploy user if not exists
DEPLOY_USER="kchou"
echo "[2/5] Ensuring deploy user '${DEPLOY_USER}' exists..."
if ! id "${DEPLOY_USER}" &>/dev/null; then
  useradd -m -s /bin/bash "${DEPLOY_USER}"
  echo "Created user ${DEPLOY_USER}"
fi

# Step 3: Configure sudo
echo "[3/5] Configuring passwordless sudo for ${DEPLOY_USER}..."
echo "${DEPLOY_USER} ALL=(ALL) NOPASSWD: ALL" > "/etc/sudoers.d/${DEPLOY_USER}"
chmod 0440 "/etc/sudoers.d/${DEPLOY_USER}"
visudo -cf "/etc/sudoers.d/${DEPLOY_USER}"

# Step 4: Ensure SSH is running
echo "[4/5] Ensuring SSH is running..."
systemctl enable --now sshd

# Step 5: Display next steps
echo "[5/5] Bootstrap complete!"
echo ""
echo "=== Next Steps ==="
echo "1. From your dev machine, copy your SSH key:"
echo "   ssh-copy-id ${DEPLOY_USER}@$(hostname -I | awk '{print $1}')"
echo ""
echo "2. Test Ansible connectivity:"
echo "   ansible nas -m ping"
echo ""
echo "3. Run baseline playbook:"
echo "   ansible-playbook -i inventory/prod ansible/playbooks/baseline.yml --check --diff"
echo ""
echo "4. If satisfied, apply:"
echo "   ansible-playbook -i inventory/prod ansible/playbooks/baseline.yml"
