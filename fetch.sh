#!/bin/bash

# Server Inventory Assessment Script for AWS EC2 and DigitalOcean Droplets
# Usage: ./server_inventory.sh > server_$(hostname)_inventory.txt

echo "=========================================="
echo "SERVER INVENTORY ASSESSMENT"
echo "=========================================="
echo "Server: $(hostname)"
echo "Assessment Date: $(date)"
echo "IP Address: $(hostname -I | awk '{print $1}' 2>/dev/null || echo 'Unknown')"
echo ""

# Function to safely execute commands and handle errors
safe_exec() {
    local cmd="$1"
    local description="$2"
    echo "=== $description ==="
    if command -v $(echo $cmd | awk '{print $1}') >/dev/null 2>&1; then
        eval "$cmd" 2>/dev/null || echo "Command failed or no output"
    else
        echo "Command not available: $(echo $cmd | awk '{print $1}')"
    fi
    echo ""
}

# Operating System Information
safe_exec "cat /etc/os-release" "Operating System"
safe_exec "uname -a" "Kernel Information"
safe_exec "hostnamectl" "System Information"

# Cloud Platform Detection
echo "=== Cloud Platform Detection ==="
# Check Ansible facts file first
if [ -f /etc/ansible/facts.d/cloud_provider.fact ]; then
    echo "Cloud Provider Info from Ansible Facts:"
    cat /etc/ansible/facts.d/cloud_provider.fact
    CLOUD_PROVIDER=$(grep "cloud=" /etc/ansible/facts.d/cloud_provider.fact | cut -d'=' -f2)
    echo "Detected Provider: $CLOUD_PROVIDER"
# AWS Detection via metadata
elif curl -s --connect-timeout 2 http://169.254.169.254/latest/meta-data/instance-id >/dev/null 2>&1; then
    echo "Cloud Provider: Amazon Web Services (AWS)"
    echo "Instance ID: $(curl -s http://169.254.169.254/latest/meta-data/instance-id 2>/dev/null || echo 'Unknown')"
    echo "Instance Type: $(curl -s http://169.254.169.254/latest/meta-data/instance-type 2>/dev/null || echo 'Unknown')"
    echo "Availability Zone: $(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone 2>/dev/null || echo 'Unknown')"
    echo "Region: $(curl -s http://169.254.169.254/latest/meta-data/placement/region 2>/dev/null || echo 'Unknown')"
# DigitalOcean Detection via metadata
elif curl -s --connect-timeout 2 http://169.254.169.254/metadata/v1/id >/dev/null 2>&1; then
    echo "Cloud Provider: DigitalOcean"
    echo "Droplet ID: $(curl -s http://169.254.169.254/metadata/v1/id 2>/dev/null || echo 'Unknown')"
    echo "Region: $(curl -s http://169.254.169.254/metadata/v1/region 2>/dev/null || echo 'Unknown')"
# AWS Detection via PCI devices (fallback)
elif lspci 2>/dev/null | grep -q "Amazon.com"; then
    echo "Cloud Provider: Amazon Web Services (AWS) - detected via hardware"
# DigitalOcean Detection via hostname pattern
elif hostname | grep -q "cloudwaysapps.com"; then
    echo "Cloud Provider: DigitalOcean/Cloudways - detected via hostname"
# Generic Cloud Detection
else
    echo "Cloud Provider: Unknown or On-Premises"
    if systemd-detect-virt >/dev/null 2>&1; then
        echo "Virtualization: $(systemd-detect-virt)"
    fi
fi
echo ""

# Virtualization Detection
safe_exec "systemd-detect-virt" "Virtualization Type"

# Hardware/Instance Information
safe_exec "lscpu" "CPU Information"
safe_exec "free -h" "Memory Information"
safe_exec "df -h" "Disk Usage"
safe_exec "lsblk" "Block Devices"

# PCI Devices (always useful for cloud identification)
safe_exec "lspci" "PCI Devices"

# AWS/EC2 Specific Tools
if command -v aws >/dev/null 2>&1; then
    safe_exec "aws --version" "AWS CLI"
fi

if command -v ec2-metadata >/dev/null 2>&1; then
    safe_exec "ec2-metadata --instance-type" "EC2 Instance Type"
fi

# DigitalOcean Specific Detection
if command -v doctl >/dev/null 2>&1; then
    safe_exec "doctl version" "DigitalOcean CLI"
fi

# Additional Detection
safe_exec "cat /proc/cpuinfo | grep hypervisor" "Hypervisor CPU Flag"
safe_exec "dmesg | grep -i hypervisor | head -5" "Boot Hypervisor Detection"

# Network Services Summary
safe_exec "ss -tuln | grep LISTEN | head -10" "Listening Services (Top 10)"

# Instance Summary
echo "=== INSTANCE SUMMARY ==="
echo "Hostname: $(hostname)"
echo "OS: $(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d'"' -f2 || echo 'Unknown')"
echo "Kernel: $(uname -r 2>/dev/null || echo 'Unknown')"
echo "Virtualization: $(systemd-detect-virt 2>/dev/null || echo 'Unknown')"
echo "CPU Cores: $(nproc 2>/dev/null || echo 'Unknown')"
echo "Memory: $(free -h 2>/dev/null | awk '/^Mem:/ {print $2}' || echo 'Unknown')"
echo "Root Disk: $(df -h / 2>/dev/null | awk 'NR==2 {print $2}' || echo 'Unknown')"

# Cloud-specific summary
if [ -f /etc/ansible/facts.d/cloud_provider.fact ]; then
    CLOUD_PROVIDER=$(grep "cloud=" /etc/ansible/facts.d/cloud_provider.fact | cut -d'=' -f2)
    echo "Cloud Platform: $CLOUD_PROVIDER (from Ansible facts)"
elif curl -s --connect-timeout 2 http://169.254.169.254/latest/meta-data/instance-id >/dev/null 2>&1; then
    echo "Cloud Platform: AWS EC2"
    echo "Instance Type: $(curl -s http://169.254.169.254/latest/meta-data/instance-type 2>/dev/null || echo 'Unknown')"
    echo "Region/AZ: $(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone 2>/dev/null || echo 'Unknown')"
elif curl -s --connect-timeout 2 http://169.254.169.254/metadata/v1/id >/dev/null 2>&1; then
    echo "Cloud Platform: DigitalOcean Droplet"
    echo "Region: $(curl -s http://169.254.169.254/metadata/v1/region 2>/dev/null || echo 'Unknown')"
elif lspci 2>/dev/null | grep -q "Amazon.com"; then
    echo "Cloud Platform: AWS EC2 (detected via hardware)"
elif hostname | grep -q "cloudwaysapps.com"; then
    echo "Cloud Platform: DigitalOcean/Cloudways (detected via hostname)"
else
    echo "Cloud Platform: Unknown/On-Premises"
fi

echo ""
echo "Assessment completed at: $(date)"
