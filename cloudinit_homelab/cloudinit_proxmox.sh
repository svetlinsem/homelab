#!/bin/bash

# Check if script is run as root
if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root" 1>&2
    exit 1
fi

# Check if script is run in Proxmox environment
if [ ! -d "/etc/pve" ]; then
    echo "This script must be run in a Proxmox environment" 1>&2
    exit 1
fi

# Function to validate numeric input
validate_number() {
    if [[ ! "$1" =~ ^[0-9]+$ ]]; then
        echo "$2 must be a number" 1>&2
        return 1
    fi
}

# Function to validate alphanumeric input
validate_alphanumeric() {
    if [[ ! "$1" =~ ^[[:alnum:]]+$ ]]; then
        echo "$2 must be alphanumeric" 1>&2
        return 1
    fi
}


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


# Function to download OS
download_os() {
    case $os_choice in
        "Debian")
            wget https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2 -O debian-12-generic-amd64.qcow2 || { echo "Error downloading Debian ISO"; exit 1; }
            selected_os="debian-12-generic-amd64.qcow2"
            ;;
        "Ubuntu")
            wget https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64.img -O ubuntu-22.04-server-cloudimg-amd64.img || { echo "Error downloading Ubuntu ISO"; exit 1; }
            selected_os="ubuntu-22.04-server-cloudimg-amd64.img"
            ;;
        "Custom")
            custom_iso_url=$(whiptail --inputbox "Enter Custom ISO URL:" 8 39 --title "Custom OS URL" 3>&1 1>&2 2>&3)
            if [[ -n "$custom_iso_url" ]]; then
                wget "$custom_iso_url" -O custom.iso || { echo "Error downloading custom ISO"; exit 1; }
                selected_os="custom.iso"
            else
                echo "Custom ISO URL not provided. Exiting."
                exit 1
            fi
            ;;
        *)
            echo "Invalid OS choice."
            exit 1
            ;;
    esac
}

# Prompt user to choose OS
os_choice=$(whiptail --title "Please choose your OS" --radiolist \
"Select OS" 20 78 4 \
"Debian" "Debian 12" ON \
"Ubuntu" "Ubuntu 22.04" OFF \
"Custom OS" "Custom OS Example Router OS etc.." OFF \
3>&1 1>&2 2>&3) || exit 1

# Prompt user to enter VM number
while true; do
    vm_number=$(whiptail --inputbox "Enter VM number:" 8 78 --title "VM Configuration" 3>&1 1>&2 2>&3)
    if ! validate_number "$vm_number" "VM number"; then
        continue
    fi
    break
done

# Prompt user to enter VM name
while true; do
    name=$(whiptail --inputbox "Enter VM name:" 8 78 --title "VM Configuration" 3>&1 1>&2 2>&3)
    if ! validate_alphanumeric "$name" "VM name"; then
        continue
    fi
    break
done

# Prompt user to enter storage pool
storage_pool=$(whiptail --inputbox "Enter storage pool (local-lvm/zfs):" 8 78 "$storage_pool" --title "Storage Pool" 3>&1 1>&2 2>&3) || exit 1

# Prompt user to enter memory
while true; do
    memory=$(whiptail --inputbox "Enter memory (MB):" 8 78 "$memory" --title "Memory" 3>&1 1>&2 2>&3)
    if ! validate_number "$memory" "Memory"; then
        continue
    fi
    break
done

# Prompt user to enter network bridge
network_bridge=$(whiptail --inputbox "Enter network bridge (vmbr0):" 8 78 "$network_bridge" --title "Network Bridge" 3>&1 1>&2 2>&3) || exit 1

# Prompt user to enter disk size
while true; do
    disk_size=$(whiptail --inputbox "Enter disk size (GB):" 8 78 "$disk_size" --title "Disk Size" 3>&1 1>&2 2>&3)
    if ! validate_number "$disk_size" "Disk size"; then
        continue
    fi
    break
done

# Download OS if needed
download_os


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
whiptail --yesno "Do you want to create a template?" 8 78 
create_template=$
# If user wants to create a template, modify the script accordingly
if [[ "$create_template" == -eq 0 ]]; then
    # Add template creation logic here
    echo "Creating template..."
    qm template "$vm_number"
    rm -f "$selected_os"
fi
