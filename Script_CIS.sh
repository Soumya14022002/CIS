#!/bin/bash

# FINAL SCRIPT: Amazon Linux 2 CIS Audit with HTML report
# Author: [Your Name]
# Date: [Today's Date]
# Purpose: Automate CIS Benchmark Audit for Amazon Linux 2
# Output: HTML Report

set -e

echo "[*] Updating system packages..."
sudo yum update -y

echo "[*] Installing required packages..."
sudo yum install -y python3 unzip wget git gcc gcc-c++ make openssl-devel

# Install AWS CLI if not installed
if ! command -v aws &> /dev/null; then
    echo "[*] Installing AWS CLI..."
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    rm -rf aws awscliv2.zip
else
    echo "[*] AWS CLI already installed."
fi

# Install Goss if not present
if [ ! -f /usr/local/bin/goss ]; then
    echo "[*] Installing Goss..."
    curl -fsSL https://goss.rocks/install | sudo sh
else
    echo "[*] Goss already installed."
fi

# Check if CMake 3.16+ is installed
INSTALL_CMAKE=false
if command -v cmake >/dev/null 2>&1; then
    INSTALLED_CMAKE_VERSION=$(cmake --version | head -n1 | awk '{print $3}')
    if [ "$(printf '%s\n' "3.16.0" "$INSTALLED_CMAKE_VERSION" | sort -V | head -n1)" = "3.16.0" ]; then
        echo "[*] CMake version $INSTALLED_CMAKE_VERSION found, skipping build..."
    else
        echo "[*] CMake version too old ($INSTALLED_CMAKE_VERSION), building latest..."
        INSTALL_CMAKE=true
    fi
else
    echo "[*] CMake not found, building latest..."
    INSTALL_CMAKE=true
fi

# Install CMake if needed
if [ "$INSTALL_CMAKE" = true ]; then
    cd /tmp
    wget https://github.com/Kitware/CMake/releases/download/v3.27.9/cmake-3.27.9.tar.gz
    tar -zxvf cmake-3.27.9.tar.gz
    cd cmake-3.27.9
    ./bootstrap
    make -j$(nproc)
    sudo make install
fi

# Clone the SCAP Security Guide content
cd /tmp
if [ ! -d "scap-security-guide-0.1.76" ]; then
    echo "[*] Cloning SCAP Security Guide..."
    git clone https://github.com/ComplianceAsCode/content.git scap-security-guide-0.1.76
fi

# Go to the directory and prepare the build
cd scap-security-guide-0.1.76
mkdir -p build
cd build

# Run CMake to generate and build the SCAP content for Amazon Linux 2
echo "[*] Building SCAP content for Amazon Linux 2..."
cmake ..
make -j$(nproc)

# Copy the SCAP content to the correct directory
echo "[*] Copying SCAP data to system directory..."
sudo cp /tmp/scap-security-guide-0.1.76/build/ssg-amazon_linux2-ds.xml /usr/share/xml/scap/ssg/content/

# Download Amazon2 COS Audit Scripts
cd /var/tmp
if [ ! -d "/var/tmp/AMAZON2-COS-Audit" ]; then
    echo "[*] Downloading Amazon2 COS Audit scripts..."
    sudo git clone https://github.com/awslabs/amazon-linux-2-cis-benchmark.git AMAZON2-COS-Audit
fi

# Move to audit directory
cd /var/tmp/AMAZON2-COS-Audit

# Run the audit using Goss
echo "[*] Running Goss tests..."
sudo goss validate --format junit > /var/tmp/goss-report.xml

# Convert the Goss XML report to HTML
if ! command -v xsltproc &> /dev/null; then
    echo "[*] Installing xsltproc for report conversion..."
    sudo yum install -y libxslt
fi

echo "[*] Converting Goss XML report to HTML..."
xsltproc goss.xslt /var/tmp/goss-report.xml > /var/tmp/goss-report.html

echo "[✔] Audit completed successfully!"
echo "[✔] HTML Report available at: /var/tmp/goss-report.html"
