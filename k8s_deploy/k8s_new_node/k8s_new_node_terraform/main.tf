resource "proxmox_vm_qemu" "k8sworkertest" {
  target_node       = var.target_node
  name              = "k8sworker.new.node${count.index + 1}"
  vmid              = "740"
  count             = 1
  clone             = "debian12"
  os_type           = "cloud-init"
  scsihw            = "virtio-scsi-pci"
  boot              = "order=scsi0;ide2"
  cpu               = "host"
  cores             = 2
  memory            = 4000
  vm_state          = "running"
  agent             = 1
  onboot            = true

  disks {   
    scsi  {
      scsi0  {
        disk {
          size            = 25
          cache           = "writeback"
          storage         = "apps"
        }
      }
    }
  }
  network {         
    model           = "virtio"
    bridge          = "vmbr0"
  }

  # Cloud Init Settings
  # Reference: https://pve.proxmox.com/wiki/Cloud-Init_Support
  cloudinit_cdrom_storage = var.storage_backend
  ipconfig0 = "ip=192.168.1.74${count.index + 2}/24,gw=192.168.1.1"
  nameserver = var.nameservers
} 
