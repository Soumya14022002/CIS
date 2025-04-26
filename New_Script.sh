#!/bin/bash

set -e

echo "===== Amazon Linux 2 CIS Benchmark + Lynis Audit Script ====="

# Update system first
echo "[+] Updating system packages..."
sudo yum update -y

# Install essential packages
echo "[+] Installing required packages..."
sudo yum install -y git wget unzip python3 cmake gcc gcc-c++ make openscap-scanner scap-security-guide

# Install awscli if not present
if ! command -v aws &> /dev/null
then
    echo "[+] Installing AWS CLI..."
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
fi

# Install ansible if needed
if ! command -v ansible-playbook &> /dev/null
then
    echo "[+] Installing Ansible..."
    sudo amazon-linux-extras enable ansible2
    sudo yum clean metadata
    sudo yum install -y ansible
fi

# Install OpenSCAP and SCAP Security Guide
echo "[+] Setting up SCAP Security Guide..."
if [ -d "scap-security-guide" ]; then
    echo "[*] Removing old scap-security-guide folder..."
    rm -rf scap-security-guide
fi

git clone https://github.com/ComplianceAsCode/content.git scap-security-guide

cd scap-security-guide
# Checkout a stable version (optional, or stay at latest)
# git checkout v0.1.76

# Build not required — we directly use the XML
cd ..

# Copy Amazon Linux 2 SCAP content
mkdir -p /usr/share/xml/scap/ssg/content/
cp scap-security-guide/ssg-alinux2-ds.xml /usr/share/xml/scap/ssg/content/

# Run OpenSCAP scan
echo "[+] Running OpenSCAP Amazon Linux 2 CIS Benchmark..."
oscap xccdf eval \
    --profile xccdf_org.ssgproject.content_profile_cis \
    --results oscap-results.xml \
    --report oscap-report.html \
    /usr/share/xml/scap/ssg/content/ssg-alinux2-ds.xml

echo "[+] OpenSCAP audit completed. Report saved to oscap-report.html."

# Install Lynis
echo "[+] Setting up Lynis..."
if [ -d "lynis" ]; then
    echo "[*] Removing old lynis folder..."
    rm -rf lynis
fi

git clone https://github.com/CISOfy/lynis.git
cd lynis

echo "[+] Running Lynis system audit..."
sudo ./lynis audit system --quiet | tee ../lynis-report.txt

cd ..

echo "===== All audits completed successfully ====="
echo "Reports generated:"
echo "  -> OpenSCAP HTML Report : oscap-report.html"
echo "  -> Lynis Text Report    : lynis-report.txt"
