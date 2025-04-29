#!/bin/bash

# Fully automatic script to clone, chmod, run AL2Script.sh, and move results to /var/log/al2-audits

# Variables
REPO_URL="https://github.com/Soumya14022002/AL2.git"
REPO_NAME="AL2"
SCRIPT_NAME="AL2Script.sh"
LOG_DIR="/var/log/al2-audits"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
LOG_FILE="$LOG_DIR/full_audit_log_$TIMESTAMP.log"

# 1. Create the log directory if it doesn't exist
echo "[*] Creating log directory at $LOG_DIR..."
sudo mkdir -p "$LOG_DIR"
sudo chown "$USER":"$USER" "$LOG_DIR"

# 2. Clone the repository
echo "[*] Cloning repository..."
git clone "$REPO_URL"

# 3. Check if cloning was successful
if [ $? -ne 0 ]; then
    echo "[!] Failed to clone repository. Exiting."
    exit 1
fi

# 4. Navigate into the cloned repository
cd "$REPO_NAME" || { echo "[!] Failed to cd into $REPO_NAME. Exiting."; exit 1; }

# 5. Make the script executable
echo "[*] Making $SCRIPT_NAME executable..."
chmod +x "$SCRIPT_NAME"

# 6. Run the script and save full terminal output
echo "[*] Running $SCRIPT_NAME..."
sudo ./"$SCRIPT_NAME" | tee "$LOG_FILE"

# 7. Move all .csv and .txt results to the log directory
echo "[*] Moving result files (.csv, .txt) to $LOG_DIR..."
for file in *.csv *.txt; do
    if [ -e "$file" ]; then
        mv "$file" "$LOG_DIR/"
    fi
done

# 8. Final message
echo "[✔] Audit complete."
echo "[✔] Terminal log saved at: $LOG_FILE"
echo "[✔] CSV and TXT results saved at: $LOG_DIR/"
