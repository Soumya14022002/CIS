#!/bin/bash
set -e

# 📁 Create a working directory
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

# 🧰 Install OpenSCAP tools
echo "[+] Installing OpenSCAP..."
sudo yum install -y openscap openscap-utils

# 📥 Download SCAP Security Guide
echo "[+] Downloading SCAP Security Guide..."
git clone https://github.com/ComplianceAsCode/content.git scap-security-guide
cd scap-security-guide

echo "[+] Building SCAP Security Guide..."
mkdir -p build
cd build
sudo yum install -y cmake make gcc gcc-c++
cmake ..
make -j$(nproc)

# 📄 Locate SCAP file
SCAP_FILE="ssg-alinux2-ds.xml"
if [ ! -f "$SCAP_FILE" ]; then
    echo "[!] Amazon Linux 2 SCAP DataStream file not found!"
    exit 1
fi

# 🔍 Run OpenSCAP evaluation
echo "[+] Running OpenSCAP audit (CIS profile)..."
sudo oscap xccdf eval \
  --profile xccdf_org.ssgproject.content_profile_cis \
  --results ~/amzn2-audit-results/amzn2-results.xml \
  --report ~/amzn2-audit-results/amzn2-report.html \
  "$SCAP_FILE"

echo "[+] Reports generated in ~/amzn2-audit-results:"
echo " - lynis-report.txt"
echo " - amzn2-results.xml"
echo " - amzn2-report.html"
