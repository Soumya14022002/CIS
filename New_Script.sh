#!/bin/bash

# Define report location
REPORT_DIR="$HOME/lynis_reports"
HTML_REPORT="$REPORT_DIR/lynis_report.html"
XLSX_REPORT="$REPORT_DIR/lynis_report.xlsx"

# Check if the report directory exists, if not create it
if [ ! -d "$REPORT_DIR" ]; then
    echo "Creating report directory: $REPORT_DIR"
    mkdir -p "$REPORT_DIR"
fi

# Step 1: Install Prerequisites
echo "Installing prerequisites..."

# Update package lists
sudo yum update -y

# Install necessary dependencies
sudo yum install -y git curl python3-pip

# Step 2: Install Lynis (if not already installed)
if ! command -v lynis &> /dev/null
then
    echo "Lynis not found, installing..."
    git clone https://github.com/CISOfy/lynis.git "$HOME/lynis"
    cd "$HOME/lynis"
    sudo ./lynis install
else
    echo "Lynis is already installed."
fi

# Step 3: Run the Lynis Audit
echo "Running Lynis audit..."

# Run the audit
cd "$HOME/lynis"
sudo ./lynis audit system --report-file "$HTML_REPORT"

# Check if the audit was successful
if [ -f "$HTML_REPORT" ]; then
    echo "Lynis audit completed successfully. Report saved to $HTML_REPORT"
else
    echo "Error: Lynis audit failed."
    exit 1
fi

# Step 4: Convert HTML Report to XLSX (using Python)
echo "Converting HTML report to XLSX..."

# Install the required Python libraries
pip3 install pandas openpyxl

# Python script to convert HTML to XLSX
python3 - <<EOF
import pandas as pd

# Read the HTML report
html_file = "$HTML_REPORT"
dfs = pd.read_html(html_file)

# Convert to XLSX
with pd.ExcelWriter("$XLSX_REPORT") as writer:
    for i, df in enumerate(dfs):
        df.to_excel(writer, sheet_name=f'Sheet{i+1}', index=False)

print("Report successfully converted to XLSX format.")
EOF

# Step 5: Final Output
if [ -f "$XLSX_REPORT" ]; then
    echo "Conversion successful! XLSX report saved to $XLSX_REPORT"
else
    echo "Error: Conversion to XLSX failed."
    exit 1
fi

# Done
echo "Audit completed. You can find the HTML report at: $HTML_REPORT"
echo "You can find the XLSX report at: $XLSX_REPORT"
echo "Script execution finished."
