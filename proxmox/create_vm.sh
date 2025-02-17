apt-get update
apt-get install -y cloud-init

storage='ZFS'
image='noble-server-cloudimg-amd64'
net='vmbr0'
size='32G'
id='8002'
pass='Haslo'
name='ubuntu-2404-cloudinit-templatev2'

if [ ! -f ${image}.img ]; then
    wget -q https://cloud-images.ubuntu.com/noble/current/${image}.img
fi
qemu-img resize ${image}.img ${size}

qm create ${id} --name ${name} --memory 2048 --cores 2 --net0 virtio,bridge=${net}

# Importowanie dysku do Proxmox
qm importdisk ${id} ${image}.img ${storage}

# Konfiguracja VM
qm set ${id} --scsihw virtio-scsi-pci --scsi0 ${storage}:vm-${id}-disk-0
qm set ${id} --ide2 ${storage}:cloudinit
qm set ${id} --boot c --bootdisk scsi0
qm set ${id} --agent enabled=1

mkdir -p /var/lib/vz/snippets
cat << EOF | tee /var/lib/vz/snippets/vendor.yaml
#cloud-config
# Update timezone
timezone: "Europe/Warsaw"

# These might not be needed as cloud-init updates the packages
package_update: true
package_upgrade: true
package_reboot_if_required: true

# Install packages
packages:
    - qemu-guest-agent
    - isc-dhcp-client

# Make sure qemu-guest-agent is running
runcmd:
    - systemctl start qemu-guest-agent
    - echo 'PasswordAuthentication yes' > /etc/ssh/sshd_config.d/60-cloudimg-settings.conf
    - systemctl restart ssh
    - dhclient
    - systemctl stop systemd-resolved
	- systemctl disable systemd-resolved
	- rm -f /etc/resolv.conf
	- echo "nameserver 1.1.1.3" | sudo tee /etc/resolv.conf
EOF

qm set ${id} --cicustom "vendor=local:snippets/vendor.yaml"
qm set ${id} --tags ubuntu,24,cloudinit
qm set ${id} --ciuser ubuntu
qm set ${id} --cipassword $(openssl passwd -6 ${pass})
qm set ${id} --sshkeys ~/.ssh/authorized_keys
qm set ${id} --ipconfig0 ip=dhcp

qm template 8888