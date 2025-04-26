#!/bin/bash

set -e

# 📁 Create result folder
mkdir -p ~/amzn2-audit-results
cd ~/amzn2-audit-results

echo "[+] Updating system..."
sudo yum update -y

# 🧪 Install Lynis
echo "[+] Installing Lynis..."
sudo yum install -y git
git clone https://github.com/CISOfy/lynis.git
cd lynis
echo "[+] Running Lynis audit..."
sudo ./lynis audit system --quiet | tee ../lynis-report.txt
cd ..

# 🧰 Install OpenSCAP tools and SCAP Security Guide
echo "[+] Installing OpenSCAP and SCAP content..."
sudo yum install -y openscap openscap-utils scap-security-guide

# 📄 Find Amazon Linux 2 SCAP content
SCAP_FILE="/usr/share/xml/scap/ssg/content/ssg-alinux2-ds.xml"
if [ ! -f "$SCAP_FILE" ]; then
  echo "[!] Amazon Linux 2 SCAP data not found at $SCAP_FILE"
  exit 1
fi

# 🔍 Run OpenSCAP evaluation
echo "[+] Running OpenSCAP audit (CIS profile)..."
sudo oscap xccdf eval \
  --profile xccdf_org.ssgproject.content_profile_cis \
  --results amzn2-results.xml \
  --report amzn2-report.html \
  "$SCAP_FILE"

echo "[+] Reports generated in ~/amzn2-audit-results:"
echo "  - lynis-report.txt"
echo "  - amzn2-results.xml"
echo "  - amzn2-report.html"
