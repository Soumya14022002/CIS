#!/bin/bash

# Install necessary packages
sudo zypper install -y openscap openscap-utils scap-security-guide

# Run SCAP evaluation with Level 2 Workstation profile and generate HTML report
sudo oscap xccdf eval --profile xccdf_org.ssgproject.content_profile_cis_workstation_l2 \
--results /tmp/results.xml --report /tmp/report.html \
/usr/share/xml/scap/ssg/content/ssg-sle15-ds.xml

echo "SCAP evaluation completed. Results saved to /tmp/results.xml and /tmp/report.html."
