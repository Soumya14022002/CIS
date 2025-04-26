#!/bin/bash

# Amazon Linux 2 - CIS Benchmark Automated Script

echo "==== Starting CIS Benchmark Audit Setup ===="

# Update the system
sudo yum update -y

# Install required packages
sudo yum install -y git python3 unzip wget

# Install pip3 if not installed
if ! command -v pip3 &>/dev/null; then
    sudo yum install -y python3-pip
fi

# Install AWS CLI using pip3
python3 -m pip install awscli --upgrade --user

# Ensure AWS CLI is in PATH
export PATH=$PATH:$HOME/.local/bin

# Install OpenSCAP
sudo yum install -y openscap-scanner scap-security-guide

# Clone the AWS Compliance as Code content
cd /tmp
if [ ! -d "content" ]; then
    git clone https://github.com/ComplianceAsCode/content.git
fi

cd content

# Build the datastream (takes a minute)
mkdir -p build
cd build
cmake ..
make -j$(nproc)

# Find the Amazon Linux 2 SCAP DataStream
DATastream_FILE=$(find . -name "ssg-amazon_linux2-ds.xml" | head -n 1)

if [[ -z "$DATastream_FILE" ]]; then
    echo "Error: SCAP DataStream for Amazon Linux 2 not found!"
    exit 1
fi

# Run the OpenSCAP scan
REPORT_HTML="/tmp/amazon_cis_report.html"
echo "Running OpenSCAP CIS Benchmark Scan..."
sudo oscap xccdf eval --profile xccdf_org.ssgproject.content_profile_cis \
--results-arf /tmp/arf.xml \
--report $REPORT_HTML \
$DATastream_FILE

echo "==== CIS Benchmark Audit Completed ===="
echo "Report generated at: $REPORT_HTML"
