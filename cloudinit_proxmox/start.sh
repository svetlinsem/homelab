#!/bin/bash

# Set dialog menu title
TITLE="Select OS"

# Initialize os_choice
os_choice=""

# Prompt user to choose OS
items=(1 "Debian 12"
       2 "Ubuntu 22.04"
       3 "Custom OS")

while choice=$(dialog --title "$TITLE" \
                 --menu "Please select" 10 40 3 "${items[@]}" \
                 2>&1 >/dev/tty)
do
  case $choice in
     1) os_choice="Debian 12"; selected_os="debian-12-generic-amd64.qcow2";;
     2) os_choice="Ubuntu 22.04"; selected_os="ubuntu-22.04-server-cloudimg-amd64.img";;
     3) read -p "Enter custom ISO URL (leave empty to proceed without custom ISO): " custom_iso_url
       if [[ -n "$custom_iso_url" ]]; then
         wget "$custom_iso_url" -O custom.iso
         selected_os="custom.iso"
       else
         echo "ISO already exists. Proceeding."
       fi
       ;;
    esac
  done
clear # Clear after user pressed Cancel


# Set a variable to track the selected OS
selected_os=""

# Check if the ISO file exists or allow custom ISO
if [[ "$os_choice" == "Debian 12" && ! -f "debian-12-generic-amd64.qcow2" ]]; then
    wget https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2 -O debian-12-generic-amd64.qcow2
    selected_os="debian-12-generic-amd64.qcow2"
elif [[ "$os_choice" == "Ubuntu 22.04" && ! -f "ubuntu-22.04-server-cloudimg-amd64.img" ]]; then
    wget https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64.img -O ubuntu-22.04-server-cloudimg-amd64.img
    selected_os="ubuntu-22.04-server-cloudimg-amd64.img"
else
    read -p "Enter custom ISO URL (leave empty to proceed without custom ISO): " custom_iso_url
    if [[ -n "$custom_iso_url" ]]; then
        wget "$custom_iso_url" -O custom.iso
        selected_os="custom.iso"
    else
        echo "ISO already exists. Proceeding."
    fi
fi

# Prompt user if they want to add a guest agent
read -p "Do you want to add a guest agent? (y/n): " add_guest_agent

# Install the guest agent if requested
if [[ "$add_guest_agent" == "y" ]]; then
    # Add your installation command here
    echo "Installing guest agent..."
    apt install -y libguestfs-tools
    virt-customize --install qemu-guest-agent -a $selected_os
fi

# Prompt user for VM configuration
read -p "Enter VM number:" vm_number
read -p "Enter VM Name:" name
read -p "Enter memory (MB):" memory
read -p "Enter network bridge (vmbr0):" network_bridge
read -p "Enter disk size (GB):" disk_size
read -p "Enter storage pool (local-lvm):" storage_pool




# Create cloud-init template
qm create $vm_number --name $name --memory $memory --net0 virtio,bridge=$network_bridge
qm importdisk $vm_number $selected_os $storage_pool
qm set $vm_number --scsihw virtio-scsi-pci --scsi0 $storage_pool:vm-$vm_number-disk-0
qm set $vm_number --ide2 $storage_pool:cloudinit
qm set $vm_number --boot c --bootdisk scsi0
qm set $vm_number --ipconfig0 ip=dhcp
qm resize $vm_number scsi0 $disk_size 


# Prompt user if they want to create a template
read -p "Do you want to create a template? (y/n): " create_template

# If user wants to create a template, modify the script accordingly
if [[ "$create_template" == "y" ]]; then
    # Add template creation logic here
    echo "Creating template..."
    # Modify the script as needed
fi
qm template $vm_number

rm -f $selected_os