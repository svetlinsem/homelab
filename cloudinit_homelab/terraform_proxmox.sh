#!/bin/bash

# Function to install Terraform on Debian-based systems
install_terraform_debian() {
    echo "Installing Terraform..."
    sudo apt update
    sudo apt install -y terraform
    if ! command -v terraform &> /dev/null; then
        echo "Error: Failed to install Terraform. Please install Terraform manually."
        exit 1
    fi
    echo "Terraform installed successfully."
}

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    echo "Terraform is not installed."
    read -p "Do you want to install Terraform? (yes/no): " install_terraform
    if [[ "$install_terraform" =~ ^[Yy][Ee][Ss]$ ]]; then
        if [[ "$(uname -s)" == "Linux" && -f "/etc/debian_version" ]]; then
            install_terraform_debian
        else
            echo "Error: Unsupported operating system. Please install Terraform manually."
            exit 1
        fi
    else
        echo "Aborted. Terraform installation is required to proceed."
        exit 1
    fi
fi

# Function to prompt user for input with error handling
prompt_input() {
    local message="$1"
    local var_name="$2"
    while true; do
        read -p "$message: " input
        if [[ -n "$input" ]]; then
            eval "$var_name=\"$input\""
            break
        else
            echo "Error: Input cannot be empty. Please try again."
        fi
    done
}

# Prompt user for project name
prompt_input "Enter Project Name" project_name

# Prompt user for Proxmox API parameters
prompt_input "Enter Proxmox API URL" pm_api_url
prompt_input "Enter Proxmox API Token ID" pm_api_token_id
prompt_input "Enter Proxmox API Token Secret" pm_api_token_secret

# Create project directory
echo "Creating project directory..."
project_dir="$project_name"
mkdir -p "$project_dir"
cd "$project_dir" || exit 1

# Prompt user for VM parameters
prompt_input "Enter VM Number" vm_number
prompt_input "Enter Count" count
prompt_input "Enter Clone" clone
prompt_input "Enter OS Type (cloudinit/iso)" os_type
prompt_input "Enter SCSI Hardware" scsihw
prompt_input "Enter Boot Order" boot_order
prompt_input "Enter CPU" cpu
prompt_input "Enter Cores" cores
prompt_input "Enter Memory (in MB)" memory
prompt_input "Enter VM State (running/stopped)" vm_state
prompt_input "Install Guest Agent? (yes/no)" agent
prompt_input "Start VM on boot? (yes/no)" onboot
prompt_input "Enter Disk Storage" disk_storage
prompt_input "Enter Disk Size" disk_size
prompt_input "Enter Network IP Configuration (e.g., ip=192.168.1.6${count.index + 1}/24,gw=192.168.1.1)" network_ip_config

# Terraform provider configuration file
cat <<EOF > providerst.tf
# Terraform provider configuration file

terraform {
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "=3.0.1-rc1"
    }
  }
  required_version = ">= 0.14"
}

# Telmate Proxmox provider
provider "proxmox" {
  pm_api_url         = "${pm_api_url}"
  pm_tls_insecure    = true
  pm_api_token       = "${pm_api_token_id}"
  pm_api_token_secret = "${pm_api_token_secret}"
}
EOF

# Terraform variables file
cat <<EOF > vars.tf
# Terraform variables file

variable "vm_number" {
  description = "VM Number"
  sring     = "${vm_number}"
}

variable "count" {
  description = "Count"
  string     = ${count}
}

variable "clone" {
  description = "Clone"
  string     = "${clone}"
}

variable "os_type" {
  description = "OS Type"
  string     = "${os_type}"
}

variable "scsihw" {
  description = "SCSI Hardware"
  string     = "${scsihw}"
}

variable "boot_order" {
  description = "Boot Order"
  string     = "${boot_order}"
}

variable "cpu" {
  description = "CPU"
  string     = ${cpu}
}

variable "cores" {
  description = "Cores"
  string     = ${cores}
}

variable "memory" {
  description = "Memory"
  string     = ${memory}
}

variable "vm_state" {
  description = "VM State"
  string     = "${vm_state}"
}

variable "agent" {
  description = "Install Guest Agent?"
  string     = "${agent}"
}

variable "onboot" {
  description = "Start VM on boot?"
  string     = "${onboot}"
}

variable "disk_storage" {
  description = "Disk Storage"
  string     = "${disk_storage}"
}

variable "disk_size" {
  description = "Disk Size"
  string     = ${disk_size}
}

variable "network_ip_config" {
  description = "Network IP Configuration"
  string     = "${network_ip_config}"
}
EOF

# Terraform configuration file
cat <<EOF > main.tf
# Terraform configuration file for VM provisioning

# Resource definition for VM
resource "proxmox_vm_qemu" "vm" {
  for_each   = toset(range(var.count))
  name       = "${var.vm_number}-${each.key}"
  clone      = var.clone
  os_type    = var.os_type
  scsihw     = var.scsihw
  boot       = var.boot_order
  cpu        = var.cpu
  cores      = var.cores
  memory     = var.memory
  vm_state   = var.vm_state
  agent      = var.agent
  onboot     = var.onboot

  # Disk configuration
  disks {
    scsi {
      scsi0 {
        disk {
          size    = var.disk_size
          storage = var.disk_storage
        }
      }
    }
  }

  # Network configuration
  network {
    model     = "virtio"
    bridge    = "vmbr0"
    ipconfig0 = var.network_ip_config
  }
}
EOF

echo "Project directory created successfully."
echo "Project files are located in: $(pwd)"

# Initialize Terraform
terraform init

# Apply configuration
terraform plan
