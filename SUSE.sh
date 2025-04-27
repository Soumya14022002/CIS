#!/bin/bash

# Exit immediately if a command fails
set -e

# Variables for the SCAP content and result paths
SCAP_CONTENT="/usr/share/xml/scap/ssg/content/ssg-sle15-ds.xml"
RESULTS_XML="/tmp/results.xml"
REPORT_HTML="/tmp/report.html"

# Function to install required packages
install_prerequisites() {
    echo "Installing required packages..."

    # Install necessary SCAP tools and guides
    sudo zypper install -y openscap openscap-utils scap-security-guide scap-workbench scap-workbench-doc ssg-apply

    # Verify that the required packages are installed
    if ! command -v oscap &> /dev/null; then
        echo "oscap could not be found, exiting."
        exit 1
    fi

    echo "Required packages installed successfully."
}

# Function to check if the SCAP content file exists
check_scap_content() {
    echo "Checking SCAP content file..."

    if [ ! -f "$SCAP_CONTENT" ]; then
        echo "SCAP content file not found at $SCAP_CONTENT. Please install the appropriate package."
        exit 1
    fi

    echo "SCAP content file found: $SCAP_CONTENT"
}

# Function to check system resources
check_system_resources() {
    echo "Checking system resources..."

    # Check disk space
    if ! df -h /tmp | grep -q 'tmpfs\|/dev/sda'; then
        echo "Insufficient disk space on /tmp. Please free up some space."
        exit 1
    fi

    # Check if there's enough memory
    if ! free -m | grep -q 'Mem'; then
        echo "Insufficient memory. Please ensure your system has enough RAM."
        exit 1
    fi

    echo "System resources are sufficient."
}

# Function to run SCAP evaluation and generate the report
run_scap_evaluation() {
    echo "Running SCAP evaluation with profile '$PROFILE'..."

    # Run SCAP evaluation with results in XML and HTML format
    sudo oscap xccdf eval --profile "$PROFILE" --fetch-remote-resources --results "$RESULTS_XML" --report "$REPORT_HTML" --verbose "$SCAP_CONTENT"

    echo "SCAP evaluation completed. Results saved to:"
    echo "XML results: $RESULTS_XML"
    echo "HTML report: $REPORT_HTML"
}

# Function to prompt the user for the profile choice
choose_profile() {
    echo "Please choose the level to scan:"
    echo "1. Level 1 Workstation"
    echo "2. Level 2 Workstation"
    echo "3. Level 1 Server"
    echo "4. Level 2 Server"

    read -p "Enter your choice (1-4): " choice

    case $choice in
        1)
            PROFILE="xccdf_org.ssgproject.content_profile_cis_workstation_l1"
            ;;
        2)
            PROFILE="xccdf_org.ssgproject.content_profile_cis_workstation_l2"
            ;;
        3)
            PROFILE="xccdf_org.ssgproject.content_profile_cis_server_l1"
            ;;
        4)
            PROFILE="xccdf_org.ssgproject.content_profile_cis"
            ;;
        *)
            echo "Invalid choice. Exiting."
            exit 1
            ;;
    esac

    echo "You selected: $PROFILE"
}

# Main function to execute all tasks
main() {
    # Install prerequisites
    install_prerequisites

    # Check if the SCAP content exists
    check_scap_content

    # Check system resources (disk space and memory)
    check_system_resources

    # Ask the user to select the profile
    choose_profile

    # Run SCAP evaluation and generate the report
    run_scap_evaluation
}

# Call the main function to start the process
main
