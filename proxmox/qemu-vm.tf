variable "vm_configs" {
  type = map(object({
    node = string
    template = string
    vm_id = number
    name = string
    cores = number
    memory = number
    size = string
    storage = string
    network = string
    vm_state = string
  }))
  default = {
    "master" = { node = "pve-tst", template = "ubuntu-2404-cloudinit-templatev2", vm_id = 201, name = "master", cores = 2, memory = 4096, size = "40G", storage = "ZFS", network = "vmbr0", vm_state = "running" }
    "worker" = { node = "pve-tst", template = "ubuntu-2404-cloudinit-templatev2", vm_id = 202, name = "worker", cores = 2, memory = 4096, size = "40G", storage = "ZFS", network = "vmbr0", vm_state = "running" }

    # "prod-1" = { node = "pve-tst", template = "debian12-templatev2", vm_id = 201, name = "Prod-1", cores = 2, memory = 4096, size = "50G", storage = "ZFS", network = "vmbr0", vm_state = "running" }
    # "prod-2" = { node = "pve-tst", template = "debian12-templatev2", vm_id = 202, name = "Prod-2", cores = 2, memory = 4096, size = "50G", storage = "ZFS", network = "vmbr0", vm_state = "stopped" }
    # "dev-1" = { node = "pve-tst", template = "debian12-templatev2", vm_id = 203, name = "Dev-1", cores = 1, memory = 2048, size = "50G", storage = "ZFS", network = "vmbr0", vm_state = "running" }
    # "dev-2" = { node = "pve-tst", template = "debian12-templatev2", vm_id = 204, name = "Dev-2", cores = 1, memory = 2048, size = "50G", storage = "ZFS", network = "vmbr0", vm_state = "stopped" }
    }
}

variable "ans_pass" {
    type = string
}

resource "proxmox_vm_qemu" "qemu-vm" {
  for_each = var.vm_configs

  name = each.value.name
  vmid = each.value.vm_id
  target_node = each.value.node

  clone = each.value.template
  full_clone = true
  agent = 1

  vm_state = each.value.vm_state
  scsihw = "virtio-scsi-pci"

    cores = each.value.cores
    memory = each.value.memory

   # Setup the disk
    disks {
        ide {
            ide2 {
                cloudinit {
                    storage = each.value.storage
                }
            }
        }
        scsi {
            scsi0 {
                disk {
                    size            = each.value.size
                    cache           = "writeback"
                    storage         = each.value.storage
                    replicate       = true
                }
            }
        }
    }

  network {
    id    = 0
    model  = "virtio"
    bridge = each.value.network
  }
  boot = "order=scsi0"
  os_type = "cloud-init"
  # Cloud-Init
  ipconfig0 = "ip=dhcp"

  ciuser = "ubuntu"
  cipassword = var.ans_pass

}

resource "null_resource" "generate_ansible_inventory" {
  depends_on = [proxmox_vm_qemu.qemu-vm]

  provisioner "local-exec" {
    command = <<EOT
      echo "[k3s]" > inventory.ini
      %{for idx, qemu-vm in proxmox_vm_qemu.qemu-vm ~}
      echo "${qemu-vm.name} ansible_host=${qemu-vm.default_ipv4_address} ansible_port=22 ansible_user=ubuntu ansible_ssh_pass=${var.ans_pass}" >> inventory.ini
      %{endfor~}
    EOT
  }
}

resource "null_resource" "ansible_playbook" {
  depends_on = [null_resource.generate_ansible_inventory]

  provisioner "local-exec" {
    command = "ansible-playbook -i inventory.ini ansible/main.yml"
  }
}