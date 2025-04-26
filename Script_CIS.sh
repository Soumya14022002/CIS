#!/bin/bash

# Amazon Linux 2 CIS Benchmark Audit Script
# Written for automation, with HTML output

set -e

echo "[*] Updating system packages..."
sudo yum update -y

echo "[*] Installing AWS CLI, Python3, Git..."
sudo yum install -y awscli python3 git wget unzip

echo "[*] Installing Development Tools and necessary libraries for CMake..."
sudo yum groupinstall -y "Development Tools"
sudo yum install -y openssl-devel ncurses-devel zlib-devel libcurl-devel expat-devel

echo "[*] Installing CMake (latest version)..."
cd /tmp
wget https://github.com/Kitware/CMake/releases/download/v3.27.9/cmake-3.27.9.tar.gz
tar -zxvf cmake-3.27.9.tar.gz
cd cmake-3.27.9
./bootstrap
make -j$(nproc)
sudo make install

echo "[*] Installing OpenSCAP and SCAP content..."
cd /tmp
wget https://github.com/ComplianceAsCode/content/releases/download/v0.1.76/scap-security-guide-0.1.76.zip
unzip scap-security-guide-0.1.76.zip
cd scap-security-guide-0.1.76
mkdir build && cd build
cmake ..
make -j$(nproc)

echo "[*] Installing OpenSCAP scanner..."
sudo yum install -y openscap-scanner

echo "[*] Preparing SCAP content for Amazon Linux 2..."
sudo mkdir -p /usr/share/xml/scap/ssg/content/
sudo cp ../build/ssg-amazon_linux2-ds.xml /usr/share/xml/scap/ssg/content/

echo "[*] Running CIS Benchmark Audit..."
sudo oscap xccdf eval --profile xccdf_org.ssgproject.content_profile_cis \
    --results /tmp/amazon2-cis-results.xml \
    --report /tmp/amazon2-cis-report.html \
    /usr/share/xml/scap/ssg/content/ssg-amazon_linux2-ds.xml

echo "[*] Audit Completed!"
echo "-----------------------------------------------------------------"
echo "✅ HTML report generated at: /tmp/amazon2-cis-report.html"
echo "✅ Full XML results saved at: /tmp/amazon2-cis-results.xml"
echo "-----------------------------------------------------------------"
