#!/bin/bash

# Set dialog menu title
whiptail --title "Homelab Toolbox" --msgbox "Homelab Tool is an easy way to create cloudinit VMs in Proxmox" 8 78

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

# Prompt user to choose mode
mode=$(whiptail --title "Select Mode" --menu "Choose between default and advanced mode:" 15 60 4 \
"Default" "Default Mode" \
"Advanced" "Advanced Mode" 3>&1 1>&2 2>&3)

# Check mode and set variables accordingly
case $mode in
    "Default")
        # Set default values
        storage_pool="local-zfs"
        memory="512"
        network_bridge="vmbr0"
        disk_size="10"
        ;;
    "Advanced")
        # Prompt user to choose OS
        choice=$(whiptail --title "Please choose your OS" --radiolist \
        "Select OS" 20 78 4 \
        "Debian" "Debian 12" ON \
        "Ubuntu" "Ubuntu 22.04" OFF \
        "Custom OS" "Custom OS Example Router OS etc.." OFF \
        3>&1 1>&2 2>&3)

        case $choice in
            "Debian") os_choice="debian";;
            "Ubuntu") os_choice="ubuntu";;
            "Custom OS") 
                custom_iso_url=$(whiptail --inputbox "Enter Custom ISO URL:" 8 39 --title "Custom OS URL" 3>&1 1>&2 2>&3)
                if [[ -n "$custom_iso_url" ]]; then
                    wget "$custom_iso_url" -O custom.iso || { echo "Error downloading custom ISO"; exit 1; }
                    selected_os="custom.iso"
                else
                    echo "ISO already exists. Proceeding."
                fi
                ;;
        esac

        # Prompt user to configure other settings
        vm_number=$(whiptail --inputbox "Enter VM number:" 8 78 --title "VM Configuration" 3>&1 1>&2 2>&3) || exit 1
        name=$(whiptail --inputbox "Enter VM name:" 8 78 --title "VM Configuration" 3>&1 1>&2 2>&3) || exit 1
        storage_pool=$(whiptail --inputbox "Enter storage pool:" 8 78 "" --title "Storage Pool" 3>&1 1>&2 2>&3) || exit 1
        memory=$(whiptail --inputbox "Enter memory (MB):" 8 78 "" --title "Memory" 3>&1 1>&2 2>&3) || exit 1
        network_bridge=$(whiptail --inputbox "Enter network bridge:" 8 78 "" --title "Network Bridge" 3>&1 1>&2 2>&3) || exit 1
        disk_size=$(whiptail --inputbox "Enter disk size (GB):" 8 78 "" --title "Disk Size" 3>&1 1>&2 2>&3) || exit 1
        ;;
    *)
        # Handle Cancel button or other unexpected input
        exit 1
        ;;
esac

clear # Clear after user pressed Cancel

# Check if the ISO file exists or allow custom ISO
if [[ "$os_choice" == "debian" && ! -f "debian-12-generic-amd64.qcow2" ]]; then
    wget https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2 -O debian-12-generic-amd64.qcow2 || { echo "Error downloading Debian ISO"; exit 1; }
    selected_os="debian-12-generic-amd64.qcow2"
elif [[ "$os_choice" == "ubuntu" && ! -f "ubuntu-22.04-server-cloudimg-amd64.img" ]]; then
    wget https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64.img -O ubuntu-22.04-server-cloudimg-amd64.img || { echo "Error downloading Ubuntu ISO"; exit 1; }
    selected_os="ubuntu-22.04-server-cloudimg-amd64.img"
fi

# Prompt user if they want to add a guest agent
whiptail --yesno "Do you want to add a guest agent?" 8 78
add_guest_agent=$?
if [[ $add_guest_agent -eq 0 ]]; then
    # Add your installation command here
    echo "Installing guest agent..."
    apt install -y libguestfs-tools
    virt-customize --install qemu-guest-agent -a "$selected_os" || { echo "Error installing guest agent"; exit 1; }
fi

# Wait for user to press Enter before proceeding
read -rp "Press Enter to continue..."

# Create cloud-init template
qm create "$vm_number" --name "$name" --memory "$memory" --net0 virtio,bridge="$network_bridge" || { echo "Error creating VM"; exit 1; }
qm importdisk "$vm_number" "$selected_os" "$storage_pool" || { echo "Error importing disk"; exit 1; }
qm set "$vm_number" --scsihw virtio-scsi-pci --scsi0 "$storage_pool":vm-"$vm_number"-disk-0 || { echo "Error setting SCSI"; exit 1; }
qm set "$vm_number" --ide2 "$storage_pool":cloudinit || { echo "Error setting IDE"; exit 1; }
qm set "$vm_number" --boot c --bootdisk scsi0 || { echo "Error setting boot disk"; exit 1; }
qm set "$vm_number" --ipconfig0 ip=dhcp
qm set "$vm_number" --agent enabled=1



# Prompt user if they want to create a template
create_template=$(whiptail --yesno "Do you want to create a template?" 8 78 --title "Template Creation" 3>&1 1>&2 2>&3)

# If user wants to create a template, modify the script accordingly
if [[ "$create_template" == "true" ]]; then
    # Add template creation logic here
    echo "Creating template..."
    qm template "$vm_number"
    rm -f "$selected_os"
fi