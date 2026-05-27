#!/usr/bin/env bash
set -euo pipefail

SWAPFILE="/swapfile"
SIZE="4G"

echo "Creating ${SIZE} swap file at ${SWAPFILE}..."

# Disable existing swapfile if it exists
if swapon --show | grep -q "^${SWAPFILE}"; then
    echo "Disabling existing swapfile..."
    sudo swapoff "${SWAPFILE}"
fi

# Create swap file
sudo fallocate -l "${SIZE}" "${SWAPFILE}"

# If fallocate fails on your filesystem, use:
# sudo dd if=/dev/zero of="${SWAPFILE}" bs=1M count=4096 status=progress

# Set correct permissions
sudo chmod 600 "${SWAPFILE}"

# Format as swap
sudo mkswap "${SWAPFILE}"

# Enable swap
sudo swapon "${SWAPFILE}"

# Backup fstab before editing
sudo cp /etc/fstab /etc/fstab.bak

# Add to /etc/fstab if not already present
if ! grep -q "^${SWAPFILE}" /etc/fstab; then
    echo "${SWAPFILE} none swap sw 0 0" | sudo tee -a /etc/fstab
fi

# Show active swap
echo
echo "Swap successfully enabled:"
swapon --show

echo
echo "Memory summary:"
free -h
