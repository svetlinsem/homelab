#!/bin/bash

# Set dialog menu title
whiptail --title "Homelab Toolbox" --msgbox "Homelab Tool is an easy way to create cloudinit VM in Proxmox" 8 78

# Initialize variables
os_choice=""
selected_os=""

# Prompt user to choose OS
choice=$(whiptail --title "Select OS" --radiolist \
"Select OS" 20 78 4 \
"Debian" "Debian 12" ON \
"Ubuntu" "Ubuntu 22.04" OFF \
"Custom OS" "Custom OS Example Router OS etc.." OFF \
3>&1 1>&2 2>&3)

case $choice in
    "Debian") os_choice="Debian 12";;
    "Ubuntu") os_choice="Ubuntu 22.04";;
    "Custom OS") custom_iso_url=$(whiptail --inputbox "Enter Custom ISO URL:" 8 39 --title "Custom OS URL" 3>&1 1>&2 2>&3)
        if [[ -n "$custom_iso_url" ]]; then
            wget "$custom_iso_url" -O custom.iso
            selected_os="custom.iso"
        else
            echo "No custom ISO provided. Proceeding."
        fi
        ;;
esac

clear # Clear after user pressed Cancel

# Check if the ISO file exists or allow custom ISO
if [[ "$os_choice" == "Debian 12" && ! -f "debian-12-generic-amd64.qcow2" ]]; then
    wget https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2 -O debian-12-generic-amd64.qcow2
    selected_os="debian-12-generic-amd64.qcow2"
elif [[ "$os_choice" == "Ubuntu 22.04" && ! -f "ubuntu-22.04-server-cloudimg-amd64.img" ]]; then
    wget https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64.img -O ubuntu-22.04-server-cloudimg-amd64.img
    selected_os="ubuntu-22.04-server-cloudimg-amd64.img"
else
    if [[ -n "$custom_iso_url" && ! -f "custom.iso" ]]; then
        wget "$custom_iso_url" -O custom.iso
        selected_os="custom.iso"
    else
        echo "ISO already exists. Proceeding."
    fi
fi

echo "Selected OS: $os_choice"
echo "Selected OS file: $selected_os"

# Prompt user for VM configuration
vm_number=$(whiptail --inputbox "Enter VM number:" 8 78 "" --title "VM Configuration" 3>&1 1>&2)
name=$(whiptail --inputbox "Enter VM Name:" 8 78 "" --title "VM Configuration" 3>&1 1>&2)
memory=$(whiptail --inputbox "Enter memory (MB):" 8 78 "" --title "VM Configuration" 3>&1 1>&2)
network_bridge=$(whiptail --inputbox "Enter network bridge (vmbr0):" 8 78 "" --title "VM Configuration" 3>&1 1>&2)
disk_size=$(whiptail --inputbox "Enter disk size (GB):" 8 78 "" --title "VM Configuration" 3>&1 1>&2)
storage_pool=$(whiptail --inputbox "Enter storage pool (local-lvm):" 8 78 "" --title "VM Configuration" 3>&1 1>&2)

# Create cloud-init template
qm create "$vm_number" --name "$name" --memory "$memory" --net0 virtio,bridge="$network_bridge"
qm importdisk "$vm_number" "$selected_os" "$storage_pool"
qm set "$vm_number" --scsihw virtio-scsi-pci --scsi0 "$storage_pool":vm-"$vm_number"-disk-0
qm set "$vm_number" --ide2 "$storage_pool":cloudinit
qm set "$vm_number" --boot c --bootdisk scsi0
qm set "$vm_number" --ipconfig0 ip=dhcp
qm resize "$vm_number" scsi0 "$disk_size"