#!/bin/bash
set -e

# ─────────────────────────────────────────────
# VULNERABLE TELNET LAB SETUP SCRIPT (FIXED)
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
apt-get install -y build-essential wget libpam0g-dev gnupg

# FIX #3: openbsd-inetd is now the actual supervisor for telnetd.
# We install it here and configure it properly in step 6.
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

cd /tmp
INETUTILS_VERSION="2.7"
INETUTILS_TARBALL="inetutils-${INETUTILS_VERSION}.tar.gz"
INETUTILS_URL="https://ftp.gnu.org/gnu/inetutils/${INETUTILS_TARBALL}"

# 1. Download tarball + signature
wget -O "${INETUTILS_TARBALL}" "${INETUTILS_URL}"
wget -O "${INETUTILS_TARBALL}.sig" "${INETUTILS_URL}.sig"

# FIX #1: Dynamically extract the real signing key fingerprint from the .sig
# file instead of hardcoding a wrong value.
echo "[*] Extracting GPG signing key fingerprint from .sig file..."
GNU_SIGNING_KEY=$(gpg --verify "${INETUTILS_TARBALL}.sig" 2>&1 |
  grep -oP '(?<=key )[0-9A-F]+')

if [ -z "${GNU_SIGNING_KEY}" ]; then
  echo "❌ Could not extract signing key fingerprint. Aborting."
  exit 1
fi
echo "[*] Found signing key: ${GNU_SIGNING_KEY}"

# 2. Import the maintainer's public key
gpg --keyserver keyserver.ubuntu.com --recv-keys "${GNU_SIGNING_KEY}"

# 3. Verify GPG signature
gpg --verify "${INETUTILS_TARBALL}.sig" "${INETUTILS_TARBALL}" || {
  echo "❌ GPG verification FAILED. Aborting."
  exit 1
}
echo "✅ GPG signature valid. Proceeding..."

# 4. Extract and build
tar xzf "${INETUTILS_TARBALL}"
cd "inetutils-${INETUTILS_VERSION}"

./configure --prefix=/usr/local
make -j$(nproc)
make install

# ─────────────────────────────────────────────
# 4. CREATE WEAK USER ACCOUNTS
# ─────────────────────────────────────────────
echo "[*] Creating user accounts with weak credentials..."

useradd -m -s /bin/bash student 2>/dev/null || true
echo "student:student123" | chpasswd
echo "root:toor" | chpasswd

# ─────────────────────────────────────────────
# 5. WEAKEN SECURITY SETTINGS (LAB ONLY ⚠️)
# ─────────────────────────────────────────────
echo "[*] Configuring PAM for telnet root access..."

sed -i 's/^auth.*pam_securetty.so/#&/' /etc/pam.d/login || true

# ─────────────────────────────────────────────
# 6. CONFIGURE INETD TO MANAGE TELNETD
# ─────────────────────────────────────────────
# FIX #2 + FIX #3 + FIX #4:
#   - telnetd has no valid standalone daemon flag (-D was wrong)
#   - inetd is the correct supervisor: spawns telnetd per connection
#   - No custom start script needed — inetd handles the lifecycle
#   - No systemd vuln-telnet.service needed either

echo "[*] Registering telnetd with openbsd-inetd..."

# Remove any existing telnet entry to avoid duplicates on re-runs
sed -i '/^telnet/d' /etc/inetd.conf

# Add telnet entry: inetd listens on port 23, spawns telnetd per connection
echo "telnet  stream  tcp  nowait  root  /usr/local/libexec/telnetd  telnetd" \
  >>/etc/inetd.conf

echo "[*] Enabling and starting openbsd-inetd..."
systemctl enable openbsd-inetd
systemctl restart openbsd-inetd

# ─────────────────────────────────────────────
# 7. PLANT FLAG & HINTS
# ─────────────────────────────────────────────
echo "[*] Planting flag and hints..."

echo "FLAG{telnet_rce_root_bypass}" >/root/flag.txt
chmod 600 /root/flag.txt

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
