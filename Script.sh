#!/bin/bash

# Define report location in the Home directory
REPORT_DIR="$HOME/lynis_reports"
LOG_REPORT="$REPORT_DIR/lynis_report.log"

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
    ./lynis install
else
    echo "Lynis is already installed."
fi

# Step 3: Install required Python libraries (for JSON output)
echo "Checking and installing required Python libraries..."
pip3 show pandas &> /dev/null
if [ $? -ne 0 ]; then
    echo "Installing pandas..."
    pip3 install pandas
else
    echo "pandas is already installed."
fi

# Step 4: Run the Lynis Audit and save the output in a log format
echo "Running Lynis audit..."
cd "$HOME/lynis"
./lynis audit system > "$LOG_REPORT"

# Check if log report is generated and not empty
if [ ! -s "$LOG_REPORT" ]; then
    echo "Error: Lynis did not produce a valid output."
    exit 1
else
    echo "Lynis audit completed successfully, saving to log file: $LOG_REPORT"
fi

# Step 5: Notify the user
echo "Audit completed. You can find the log report at: $LOG_REPORT"
echo "Script execution finished."
