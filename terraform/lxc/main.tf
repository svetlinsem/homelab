resource "proxmox_lxc" "hostname" {
  target_node  = var.target_node
  count        = var.counts 
  hostname     = var.hostname
  vmid         = var.vmid
  cores        = var.cores
  memory       = var.memory
  onboot       = false
  tags         = "terraform"
  arch         = "amd64"
  ostemplate   = "local:vztmpl/debian-12-standard_12.2-1_amd64.tar.zst"
  ostype       = var.ostype
  unprivileged = var.unprivileged


  ssh_public_keys = var.ssh_public_keys


  // Terraform will crash without rootfs defined
  rootfs {
    storage = var.storage
    size    = var.size
  }
  

  network {
    name   = "eth0"
    bridge = "vmbr0"
    ip     = "192.168.1.70/24"
    gw     = "192.168.1.1"
  }
}