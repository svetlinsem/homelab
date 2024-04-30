#!/bin/bash

# Prompt user to choose OS
read -p "Choose OS (debian/ubuntu): " os_choice

# Set a variable to track the selected OS
selected_os=""

Download the selected OS image
if [[ "$os_choice" == "debian" ]]; then
    wget https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2 -O debian-12-generic-amd64.qcow2
    selected_os="Debian"
elif [[ "$os_choice" == "ubuntu" ]]; then
    wget https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64.img -O ubuntu-22.04-server-cloudimg-amd64.img
    selected_os="Ubuntu"
else
    echo "Invalid choice. Exiting."
    exit 1
fi

# Prompt user if they want to add a guest agent
read -p "Do you want to add a guest agent? (y/n): " add_guest_agent

# Install the guest agent if requested
if [[ "$add_guest_agent" == "y" ]]; then
    # Add your installation command here
    echo "Installing guest agent..."
    apt-get install -y libguestfs-tools
    virt-customize -a $selected_os --install qemu-guest-agent
fi

# Prompt user for VM configuration
read -p "Enter VM Name" name
read -p "Enter memory (MB): " memory
read -p "Enter disk size (GB): " disk_size
read -p "Enter storage pool (local-lvm): " storage_pool
read -p "Enter network bridge (vmbr0): " network_bridge
read -p "Enter VM number: " vm_number

# Create cloud-init template
qm create $vm_number --name my-vm --memory $memory --net0 virtio,bridge=$network_bridge
qm importdisk $vm_number debian-cloud-image.qcow2 $storage_pool
qm set $vm_number --scsihw virtio-scsi-pci --scsi0 $storage_pool:vm-$vm_number-disk-0
qm set $vm_number --ide2 $storage_pool:cloudinit
qm set $vm_number --boot c --bootdisk scsi0
qm template $vm_number
rm -f debian-12-generic-amd64.qcow2 ubuntu-22.04-server-cloudimg-amd64.img