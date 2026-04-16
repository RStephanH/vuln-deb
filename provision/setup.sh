#!/bin/bash
set -e

# ─────────────────────────────────────────────
# VULNERABLE TELNET LAB SETUP SCRIPT
# ─────────────────────────────────────────────
# This script creates a vulnerable environment
# for testing telnet-based exploits (LAB ONLY)
# ─────────────────────────────────────────────

# ─────────────────────────────────────────────
# 1. SYSTEM PREPARATION
# ─────────────────────────────────────────────
echo "[*] Updating packages..."
apt-get update -qq

echo "[*] Installing build tools and dependencies..."
apt-get install -y build-essential wget libpam0g-dev

echo "[*] Installing openbsd-inetd (inet daemon)..."
apt-get install -y openbsd-inetd

# ─────────────────────────────────────────────
# 2. REMOVE SECURE TELNET PACKAGES
# ─────────────────────────────────────────────
echo "[*] Removing secure telnet packages..."
apt-get remove -y inetutils-telnetd telnetd xinetd || true

# ─────────────────────────────────────────────
# 3. COMPILE & INSTALL VULNERABLE INETUTILS
# ─────────────────────────────────────────────
echo "[*] Installing vulnerable GNU InetUtils 2.7..."

# Download and extract vulnerable version
cd /tmp
wget https://ftp.gnu.org/gnu/inetutils/inetutils-2.7.tar.gz
tar xzf inetutils-2.7.tar.gz
cd inetutils-2.7

# Configure, compile, and install
./configure --prefix=/usr/local
make -j$(nproc)
make install

# telnetd is started later as a standalone systemd service.
# Do not also register it with inetd, or both services will
# compete for port 23 and one of them will fail to start.

# ─────────────────────────────────────────────
# 4. CREATE WEAK USER ACCOUNTS
# ─────────────────────────────────────────────
echo "[*] Creating user accounts with weak credentials..."

# Create student user with default password
useradd -m -s /bin/bash student 2>/dev/null || true
echo "student:student123" | chpasswd

# Set weak root password for testing
echo "root:toor" | chpasswd

# ─────────────────────────────────────────────
# 5. WEAKEN SECURITY SETTINGS (LAB ENVIRONMENT ONLY ⚠️)
# ─────────────────────────────────────────────
echo "[*] Configuring PAM for telnet root access..."

# Allow root login via pseudo-terminals (pts)
echo "pts/0" >>/etc/securetty
echo "pts/1" >>/etc/securetty
echo "pts/2" >>/etc/securetty

# Disable pam_securetty restriction to allow root telnet access
sed -i 's/^auth.*pam_securetty.so/#&/' /etc/pam.d/login || true

# ─────────────────────────────────────────────
# 6. SETUP TELNETD SERVICE & STARTUP
# ─────────────────────────────────────────────
echo "[*] Creating telnetd startup script..."

# Create daemon startup script
cat <<'EOF' >/usr/local/bin/start-telnetd.sh
#!/bin/bash
pkill telnetd || true

echo "[*] Starting telnetd (daemon mode)..."
exec /usr/local/libexec/telnetd -D
EOF

chmod +x /usr/local/bin/start-telnetd.sh

# Create systemd service for auto-start on boot
cat <<'EOF' >/etc/systemd/system/vuln-telnet.service
[Unit]
Description=Vulnerable Telnet Server
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/start-telnetd.sh
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Register and start the vulnerable telnet service
echo "[*] Enabling telnet service..."
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable vuln-telnet
systemctl start vuln-telnet

# Enable and restart inet daemon
systemctl enable openbsd-inetd
systemctl restart openbsd-inetd

# ─────────────────────────────────────────────
# 7. PLANT FLAG & HINTS
# ─────────────────────────────────────────────
echo "[*] Planting flag and hints..."

# Create flag file (restricted to root only)
echo "FLAG{telnet_rce_root_bypass}" >/root/flag.txt
chmod 600 /root/flag.txt

# Create readme hint for the student user
echo "Hint: USER env injection may lead to authentication bypass." \
  >/home/student/readme.txt
chown student:student /home/student/readme.txt

# ─────────────────────────────────────────────
# SETUP COMPLETE
# ─────────────────────────────────────────────
echo ""
echo "============================================"
echo "  Vulnerable Telnet Lab Ready!"
echo "  Target IP : 192.168.56.10"
echo "  Port      : 23"
echo "  Exploit   : USER='-f root' telnet -a IP"
echo "============================================"
