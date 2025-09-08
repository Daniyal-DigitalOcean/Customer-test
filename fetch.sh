#!/bin/bash

# Server Inventory Assessment Script
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
safe_exec "lsb_release -a" "LSB Release"

# Virtualization Detection
safe_exec "systemd-detect-virt" "Virtualization Type"
safe_exec "lspci | grep -i virtio" "VirtIO Devices"
safe_exec "lspci | grep -i vmware" "VMware Detection"
safe_exec "lspci | grep -i microsoft" "Microsoft/Hyper-V Detection"
safe_exec "dmidecode -s system-manufacturer" "System Manufacturer"
safe_exec "dmidecode -s system-product-name" "System Product"

# Hardware Information
safe_exec "lscpu" "CPU Information"
safe_exec "free -h" "Memory Information"
safe_exec "df -h" "Disk Usage"
safe_exec "lsblk" "Block Devices"
safe_exec "lspci" "PCI Devices"

# Container and Virtualization Platforms (only if installed)
if command -v docker >/dev/null 2>&1; then
    safe_exec "docker --version" "Docker"
    safe_exec "systemctl status docker" "Docker Service"
fi

if command -v kubectl >/dev/null 2>&1; then
    safe_exec "kubectl version --client" "Kubernetes"
fi

if command -v virsh >/dev/null 2>&1; then
    safe_exec "virsh version" "KVM/Libvirt"
fi

if command -v vmware-toolbox-cmd >/dev/null 2>&1; then
    safe_exec "vmware-toolbox-cmd -v" "VMware Tools"
fi

# Additional Detection
safe_exec "cat /proc/cpuinfo | grep hypervisor" "Hypervisor CPU Flag"
safe_exec "dmesg | grep -i hypervisor | head -5" "Boot Hypervisor Detection"

# Network Services Summary
safe_exec "ss -tuln | grep LISTEN | head -10" "Listening Services (Top 10)"

# CSV-Ready Summary for Excel
echo "=== CSV SUMMARY FOR EXCEL ==="
HOSTNAME=$(hostname)
OS_NAME=$(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d'"' -f2 | tr ',' ';' || echo 'Unknown')
OS_VERSION=$(grep VERSION= /etc/os-release 2>/dev/null | grep -v VERSION_ID | cut -d'"' -f2 | tr ',' ';' || echo 'Unknown')
KERNEL=$(uname -r 2>/dev/null || echo 'Unknown')
VIRT_TYPE=$(systemd-detect-virt 2>/dev/null || echo 'Unknown')
CPU_CORES=$(nproc 2>/dev/null || echo 'Unknown')
MEMORY=$(free -h 2>/dev/null | awk '/^Mem:/ {print $2}' || echo 'Unknown')
ROOT_DISK=$(df -h / 2>/dev/null | awk 'NR==2 {print $2}' || echo 'Unknown')
VIRTIO_COUNT=$(lspci 2>/dev/null | grep -ic virtio || echo '0')
VMWARE_DETECTED=$(lspci 2>/dev/null | grep -qi vmware && echo 'Yes' || echo 'No')
HYPERV_DETECTED=$(lspci 2>/dev/null | grep -qi microsoft && echo 'Yes' || echo 'No')
DOCKER_INSTALLED=$(echo 'No')
PHYSICAL_OR_VIRTUAL=$(cat /proc/cpuinfo 2>/dev/null | grep -q hypervisor && echo 'Virtual' || echo 'Physical/Unknown')

echo "CSV_DATA: $HOSTNAME,$OS_NAME,$OS_VERSION,$KERNEL,$VIRT_TYPE,$CPU_CORES,$MEMORY,$ROOT_DISK,$VIRTIO_COUNT,$VMWARE_DETECTED,$HYPERV_DETECTED,$DOCKER_INSTALLED,$PHYSICAL_OR_VIRTUAL,$(date)"

echo ""
echo "Assessment completed at: $(date)"
