#!/bin/bash
set -e

echo "[*] Updating packages..."
apt-get update -qq

# ── 1. Install telnetd (intentionally insecure service) ──────────────────────
echo "[*] Installing telnet server..."
apt-get install -y telnetd xinetd 2>/dev/null || \
apt-get install -y inetutils-inetd inetutils-telnetd

# ── 2. Configure xinetd for telnet ───────────────────────────────────────────
cat > /etc/xinetd.d/telnet <<'EOF'
service telnet
{
    flags           = REUSE
    socket_type     = stream
    wait            = no
    user            = root
    server          = /usr/sbin/in.telnetd
    log_on_failure  += USERID
    disable         = no
}
EOF

# ── 3. Restart xinetd ────────────────────────────────────────────────────────
systemctl enable xinetd
systemctl restart xinetd

# ── 4. Create vulnerable users ───────────────────────────────────────────────
echo "[*] Creating users with weak credentials..."

# Unprivileged user with weak password
useradd -m -s /bin/bash student 2>/dev/null || true
echo "student:student123" | chpasswd

# Root with weak password (intentional for lab)
echo "root:toor" | chpasswd

# ── 5. Plant the flag ────────────────────────────────────────────────────────
echo "[*] Planting flag..."
echo "FLAG{telnet_cleartext_r00t_bypass_lab}" > /root/flag.txt
chmod 600 /root/flag.txt

# Hint for the student user
mkdir -p /home/student
echo "Hint: services running on this machine may expose credentials in cleartext." \
  > /home/student/readme.txt
chown student:student /home/student/readme.txt

# ── 6. Disable firewall restrictions for lab ─────────────────────────────────
# (no iptables rules — VM is isolated by host-only network anyway)

echo ""
echo "============================================"
echo "  Vulnerable Telnet Lab Ready!"
echo "  Target IP : 192.168.56.10"
echo "  Port      : 23 (telnet)"
echo "  Objective : Read /root/flag.txt"
echo "============================================"
