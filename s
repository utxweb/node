#!/bin/bash
# UTX agent node setup: internet apt sources, SSH with the firstmate public keys, never sleep.
# Public keys only; nothing secret in this file.
set -e
[ "$(id -u)" = 0 ] || { echo "Run it with sudo: curl -sL https://raw.githubusercontent.com/utxweb/node/main/s | sudo bash"; exit 1; }
U=${SUDO_USER:-$(logname 2>/dev/null || echo utxweb)}
for s in noble noble-updates noble-security; do echo "deb http://archive.ubuntu.com/ubuntu $s main universe restricted multiverse"; done > /etc/apt/sources.list
rm -f /etc/apt/sources.list.d/*
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y openssh-server build-essential curl git avahi-daemon
H=$(getent passwd "$U" | cut -d: -f6)
mkdir -p "$H/.ssh"
for k in "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG9bAOiy06P1qzUv2Tff1IGJqGfrTu3ClZgATA6oitBF firstmate-fleet-node" "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDc784R+On5XNhTaS0NiQhcaHl32NsJOKZpk+krfrdj9 rafalklo@gmail.com"; do grep -qF "$k" "$H/.ssh/authorized_keys" 2>/dev/null || echo "$k" >> "$H/.ssh/authorized_keys"; done
chown -R "$U:$U" "$H/.ssh"; chmod 700 "$H/.ssh"; chmod 600 "$H/.ssh/authorized_keys"
echo "$U ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/90-fm-node; chmod 440 /etc/sudoers.d/90-fm-node
systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target
mkdir -p /etc/systemd/logind.conf.d
printf "[Login]\nHandleLidSwitch=ignore\nHandleLidSwitchExternalPower=ignore\nHandleLidSwitchDocked=ignore\nIdleAction=ignore\n" > /etc/systemd/logind.conf.d/no-sleep.conf
systemctl restart systemd-logind || true
systemctl enable --now ssh
echo; echo "DONE. Tell firstmate: user=$U  ip=$(hostname -I)"
