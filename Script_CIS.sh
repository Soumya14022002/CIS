#!/bin/bash

# Amazon Linux 2 - CIS Benchmark Audit Script (with CMake fix)
# Author: [Your Name]
# Version: 1.1
# Date: [Today's Date]

set -e  # Exit if any command fails
set -o pipefail

echo "[*] Starting CIS Benchmark Audit for Amazon Linux 2..."

# 1. Update system
echo "[*] Updating system..."
sudo yum update -y

# 2. Install required packages
echo "[*] Installing required base packages..."
sudo yum install -y git python3 unzip wget gcc gcc-c++ make openscap-scanner scap-security-guide

# 3. Fix CMake: Install latest CMake manually
echo "[*] Installing latest CMake (3.27)..."
cd /tmp
wget https://github.com/Kitware/CMake/releases/download/v3.27.9/cmake-3.27.9.tar.gz
tar -zxvf cmake-3.27.9.tar.gz
cd cmake-3.27.9
./bootstrap
make -j$(nproc)
sudo make install

# Verify CMake version
cmake --version

# 4. Create working directory
WORKDIR="/tmp/cis-audit"
mkdir -p "$WORKDIR"
cd "$WORKDIR"

# 5. Download ComplianceAsCode content
echo "[*] Downloading ComplianceAsCode SCAP content..."
if [ ! -d "content" ]; then
    git clone https://github.com/ComplianceAsCode/content.git
fi

# 6. Build SCAP content
echo "[*] Building SCAP content..."
cd content
mkdir -p build
cd build
cmake ..
make -j$(nproc)

# 7. Check if SCAP DataStream was built
if [ ! -f "ssg-amazon_linux2-ds.xml" ]; then
    echo "[!] Error: SCAP DataStream for Amazon Linux 2 not found after build."
    exit 1
fi

# 8. Run OpenSCAP Audit
echo "[*] Running OpenSCAP CIS Benchmark Audit..."
sudo oscap xccdf eval \
--profile xccdf_org.ssgproject.content_profile_cis \
--results-arf "$WORKDIR/arf.xml" \
--report "$WORKDIR/amazon_linux2_cis_report.html" \
"$WORKDIR/content/build/ssg-amazon_linux2-ds.xml"

# 9. Audit Complete
echo "[*] CIS Benchmark Audit completed successfully."
echo "[*] HTML Report is saved at: $WORKDIR/amazon_linux2_cis_report.html"

echo "[✓] DONE."

