#!/bin/bash

# Set dialog menu title
whiptail --title "Homelab Toolbox" --msgbox "Homelab Tool is easy way to create cloudinit VM in Proxmox" 8 78

# Initialize variables
os_choice=""
selected_os=""
vm_number=""
name=""
storage_pool=""
memory=""
network_bridge=""
disk_size=""
add_guest_agent=""
custom_iso_url=""

# Prompt user to choose OS
whiptail --title "Check list example" --radiolist \
"Select OS" 20 78 4 \
"Debian" "Debian 12" ON \ debian-12-generic-amd64.qcow2
"Ubuntu" "Ubuntu 22.04" OFF \ ubuntu-22.04-server-cloudimg-amd64.img
"Custom OS" "Custom OS Example Router OS etc.." OFF custom_iso_url

    case $choice in
       "Debian") os_choice="Debian 12";;
       "Ubuntu") os_choice="Ubuntu 22.04";;
       "Custom OS") COLOR=$(whiptail --inputbox "What is your favorite Color?" 8 39 Blue --title "Example Dialog" ) custom_iso_url
           if [[ -n "$custom_iso_url" ]]; then
               wget "$custom_iso_url" -O custom.iso
               selected_os="custom.iso"
           else
               echo "ISO already exists. Proceeding."
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
      echo "Enter custom ISO URL (leave empty to proceed without custom ISO): " custom_iso_url
    if [[ -n "$custom_iso_url" ]]; then
        wget "$custom_iso_url" -O custom.iso
        selected_os="custom.iso"
    else
        echo "ISO already exists. Proceeding."
    fi
fi

# Prompt user if they want to add a guest agent
add_guest_agent=$(whiptail --yesno "Do you want to add a guest agent?" 8 78 --title "Guest Agent" 3>&1 1>&2 2>&3)

# Install the guest agent if requested
if [[ "$add_guest_agent" == "true" ]]; then
    # Add your installation command here
    echo "Installing guest agent..."
    apt install -y libguestfs-tools
    virt-customize --install qemu-guest-agent -a $selected_os
fi

# Prompt user for VM configuration
vm_number=$(whiptail --inputbox "Enter VM number:" 8 78 --title "VM Configuration" 3>&1 1>&2 2>&3)
name=$(whiptail --inputbox "Enter VM name:" 8 78 --title "VM Configuration" 3>&1 1>&2 2>&3)
storage_pool=$(whiptail --inputbox "Enter storage pool (local-lvm):" 8 78 --title "VM Configuration" 3>&1 1>&2 2>&3)
memory=$(whiptail --inputbox "Enter memory (MB):" 8 78 --title "VM Configuration" 3>&1 1>&2 2>&3)
network_bridge=$(whiptail --inputbox "Enter network bridge (vmbr0):" 8 78 --title "VM Configuration" 3>&1 1>&2 2>&3)
disk_size=$(whiptail --inputbox "Enter disk size (GB):" 8 78 --title "VM Configuration" 3>&1 1>&2 2>&3)


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
