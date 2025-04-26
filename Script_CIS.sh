#!/bin/bash

# Amazon Linux 2 - CIS Benchmark Audit Script
# Author: [Your Name]
# Version: 1.0
# Date: [Today's Date]

set -e  # Exit if any command fails
set -o pipefail

echo "[*] Starting CIS Benchmark Audit for Amazon Linux 2..."

# 1. Update system
echo "[*] Updating system..."
sudo yum update -y

# 2. Install Required Packages
echo "[*] Installing required packages..."
sudo yum install -y git python3 unzip wget gcc gcc-c++ make cmake openscap-scanner scap-security-guide

# 3. Create working directory
WORKDIR="/tmp/cis-audit"
mkdir -p "$WORKDIR"
cd "$WORKDIR"

# 4. Download ComplianceAsCode content
echo "[*] Downloading ComplianceAsCode SCAP content..."
if [ ! -d "content" ]; then
    git clone https://github.com/ComplianceAsCode/content.git
fi

# 5. Build SCAP content
echo "[*] Building SCAP content..."
cd content
mkdir -p build
cd build
cmake ..
make -j$(nproc)

# 6. Check if SCAP DataStream was built
if [ ! -f "ssg-amazon_linux2-ds.xml" ]; then
    echo "[!] Error: SCAP DataStream for Amazon Linux 2 not found after build."
    exit 1
fi

# 7. Run OpenSCAP Audit
echo "[*] Running OpenSCAP CIS Benchmark Audit..."
sudo oscap xccdf eval \
--profile xccdf_org.ssgproject.content_profile_cis \
--results-arf "$WORKDIR/arf.xml" \
--report "$WORKDIR/amazon_linux2_cis_report.html" \
"$WORKDIR/content/build/ssg-amazon_linux2-ds.xml"

# 8. Audit Complete
echo "[*] CIS Benchmark Audit completed successfully."
echo "[*] HTML Report is saved at: $WORKDIR/amazon_linux2_cis_report.html"

echo "[✓] DONE."

