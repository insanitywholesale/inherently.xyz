---
title: "Ansible, Terraform and Proxmox"
date: 2022-06-24T23:24:57+03:00
draft: false
tags: ["ansible", "terraform", "proxmox", "devops", "homelab"]
---

In the continuing quest to improve my homelab I've written a few ansible playbooks as well as terraform configuration to automate a lot of tasks.
The initial setup of proxmox is handled by ansible, the provisioning of virtual machines is handled by terraform and the installation of k3s on the VMs is done by ansible.

## Proxmox Setup with Ansible
Before getting to use all the shiny devops with a selfhosted solution, we need to do a bit of setup first.
This isn't perfect since it's just ansible running a bash script but it gets the job done.
The other issue,, is that a lot of cloud images don't include qemu-guest-agent and other packages by default.
I have a few ideas how to solve that (check out this [TODO.md](https://github.com/insanitywholesale/home-infra/blob/master/TODO.md) for more info) but haven't tested out anything yet.
Since qemu-guest-agent and things like nfs-common are required on most VMs, a lot of redundant package installation happens but such is life for now.
With that out of the way, let's start with how I configure proxmox.

### Host
While proxmox has a lot of things ready to go out of the box, a bit of configuration is always required and even more so in this case.
The goal of the following steps is to turn our hosts into capable, cloud-like, targets for provisioning resources using terraform.

#### Repository
Initially the enterprise repository which we don't have a license to access is enabled.
To fix this, I delete the file in `/etc/apt/sources.list.d` that contains it and add a file with the no-subscription repository.
This might not be necessary since the [lae.proxmox](https://github.com/lae/ansible-role-proxmox) ansible role can do essentially the same thing and many more.
Here are the ansible tasks:

```yml
    - name: remove enterprise repo
      file:
        path: /etc/apt/sources.list.d/pve-enterprise.list
        state: absent

    - name: add no-subscription repo
      copy:
        src: pve-no-sub.list
        dest: /etc/apt/sources.list.d/pve-no-subscription.list
        mode: '0644'
        owner: root
        group: root
```

### Template VM
The terraform provider for proxmox can work with cloud-init which is a great vendor-agnostic way of configuring the basics (username, password, IP addressing, DNS, SSH keys) in a virtualized environment.
This is achieved by having a virtual disk or virtual cd-rom that mounts inside the VM and provides this information to the guest.

#### VM Image 
Since software is not always compatible with the latest version of a linux distribution, in this case debian, I keep the last two versions around.
The first step is to download the images:
```yml
    - name: get debian 10 cloud image
      get_url:
        url: https://cloud.debian.org/images/cloud/buster/20211011-792/debian-10-generic-amd64-20211011-792.qcow2
        dest: /root/debian-10-openstack-amd64.qcow2
        checksum: sha512:f3dac13104b4e28eb62c46cbbb1e30fc9c792834500f9101d477c19c258c31ff04850933ee0b3e63236eca38c854447d95a0ab45163c4a3fccf05f9dd95601a5
        mode: '0644'
        owner: root
        group: root

    - name: get debian 11 cloud image
      get_url:
        url: https://cloud.debian.org/images/cloud/bullseye/20220121-894/debian-11-generic-amd64-20220121-894.qcow2
        dest: /root/debian-11-openstack-amd64.qcow2
        checksum: sha512:0948dc56b4834a7755e4eae7d5532e138b90484a949161ffe9fc6894c7a14b1bd32ebf96fa3f3d03d498fe7ee125f8014f31bfab5825915a93de9330df814f7b
        mode: '0644'
        owner: root
        group: root
```

#### Template Script
As mentioned in the beginning I'd like to automate this with ansible but this is what I have for now:
```bash
if [ -z "$1" ]; then
    VMID=9001
else
    VMID="$1"
fi

if [ -z "$2" ]; then
    VMNAME="debian-tmpl"
else
    VMNAME="$2"
fi

VMEXISTS="$(qm list | grep $VMID)"

if [ "$VMEXISTS" ]; then
    echo "VM with ${VMID} already exists"
else
    qm create "${VMID}" -name "${VMNAME}" -memory 1024 -net0 virtio,bridge=vmbr0 -cores 1 -sockets 1 -cpu cputype=kvm64 -description "debbie image" -kvm 1 -numa 1
    qm importdisk "${VMID}" debian-10-openstack-amd64.qcow2 local-zfs
    qm set "${VMID}" -scsihw virtio-scsi-pci -virtio0 local-zfs:vm-"${VMID}"-disk-0
    qm set "${VMID}" -serial0 socket
    qm set "${VMID}" -boot c -bootdisk virtio0
#   qm set "${VMID}" -agent 1 #disabled since VM does not initially have qga installed
    qm set "${VMID}" -hotplug disk,network,usb,memory,cpu
    qm set "${VMID}" -vcpus 1
    qm set "${VMID}" -vga qxl
    qm set "${VMID}" -name "${VMNAME}"
    qm set "${VMID}" -ide2 local-zfs:cloudinit
    qm template "${VMID}"
fi
```

This works well enough for first-time setup and with a few additions could become idempotent.
The above script and its debian 11 equivalent are copied over to the proxmox hosts and executed by the following ansible tasks:
```yml
    - name: get debian 10 template vm script
      copy:
        src: setup-debian-10-cloudinit.sh
        dest: /root/setup-debian-10-template.sh
        mode: '0755'
        owner: root
        group: root

    - name: run debian 10 template vm script
      shell:
        cmd: /root/setup-debian-10-template.sh

    - name: get debian 11 template vm script
      copy:
        src: setup-debian-11-cloudinit.sh
        dest: /root/setup-debian-11-template.sh
        mode: '0755'
        owner: root
        group: root

    - name: run debian 11 template vm script
      shell:
        cmd: /root/setup-debian-11-template.sh
```

## Terraform Setup
With proxmox ready, let's move on to the terraform setup.
If you haven't used it before, terraform is a declarative way of describing our infrastructure.
It can manage virtual machines, DNS records, object storage buckets, kubernetes resources and many more things with the appropriate providers.

### Provider
Providers in terraform are plugins that enable terraform to manage resources that it doesn't support out of the box.
In this case, we want to manage proxmox virtual machines and containers but it could be other things like a router running pfsense or vyos.
In previous versions, the provider would need to be installed manually but nowadays we only need to create a `main.tf` with the provider listed and upon running `terraform init`, the provider will be downloaded automatically.

### Basic `main.tf`
Let's create that file then.
Open your favorite editor, paste the following and replace the IP as well as the password with the ones applicable to your setup:
```hcl
terraform {
	required_providers {
		proxmox = {
			source = "Telmate/proxmox"
			version = ">=2.9.5"
		}
	}
}

provider "proxmox" {
	alias = "pve"
	pm_tls_insecure = true
	pm_api_url = "https://192.168.70.1:8006/api2/json" #Replace IP
	pm_password = "password123" #Replace password
	pm_user = "root@pam"
}
```

Save the file and then run `terraform init`.
You should see the following output (the version might be different):
```
Initializing the backend...

Initializing provider plugins...
- Finding telmate/proxmox versions matching ">= 2.9.5"...
- Installing telmate/proxmox v2.9.10...
- Installed telmate/proxmox v2.9.10 (self-signed, key ID A9EBBE091B35AFCE)

Partner and community providers are signed by their developers.
If you'd like to know more about provider signing, you can read about it here:
https://www.terraform.io/docs/cli/plugins/signing.html

Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```

And ta-da! We've installed the provider and are ready to start creating resources.

### Creating a test VM
The above file won't do anything so we'll declare a virtual machine and then tell terraform to create it.
The example below is specific to my setup so you probably want to modify it before using but here it is:
```hcl
terraform {
	required_providers {
		proxmox = {
			source = "Telmate/proxmox"
			version = ">=2.9.5"
		}
	}
}

provider "proxmox" {
	alias = "pve"
	pm_tls_insecure = true
	pm_api_url = "https://192.168.70.1:8006/api2/json" #Replace IP
	pm_password = "password123" #Replace password
	pm_user = "root@pam"
}

resource "proxmox_vm_qemu" "proxmox_test_vm" {
	provider = proxmox.pve
	name = "deb-10-test"
	target_node = "pve"

	/* change to debian-templ for 11 */
	clone = "debian-tmpl"
	os_type = "cloud-init"
	cores = 2
	sockets = 1
	cpu = "host"
	memory = 2048
	scsihw = "virtio-scsi-pci"
	bootdisk = "virtio0"
	agent = 0

	disk {
		size = "30G"
		type = "virtio"
		storage = "local-zfs"
	}

	network {
		model = "virtio"
		bridge = "vmbr0"
	}

	ipconfig0 = "ip=192.168.50.25/16,gw=192.168.0.1"

	/*workstation SSH key*/
	sshkeys = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC5jzKi37jm3517bqThbw+7LR/GXm3qC6Az5F+ZUa36vYM7Ygk2K5bWcFIL2YUCrkL5jfSsvoowONjCAxyuoyxtW4MJxnQLyq4u4yDsRC7YvBPAKZUYaHwnbkCfDs5a75dEFOoDxCA0DY2GrhqzBndaTcCfl0fZ4vN+9LcKOb1dSKiHeHvsh35YNtwntbL21meo+hiycUEgGwNe9/4kxKpdGTr7HvbeX2Fjm/UZBZIJKVcGop/3gCHXYnKH+OY5zc8cmt9Jg4CIwEqrSKeOX0bE8LSPRpVRXH4v8OcMaMei/HQejlH8NBwybEdJ4mhl8vHaFEjDbIWoOujmiRQF2263 angle@puddle"

	/*required otherwise the state always appears modified*/
	lifecycle {
		ignore_changes = [
			cipassword,
			network,
			desc,
		]
	}
}
```

After saving the file, we can run `terraform plan -out create-test-vm.plan` to calculate the changes required and save them to a file.
Following that, we can run `terraform apply create-test-vm.plan` to apply the changes to our infrastructure.
Some output will appear while the template is cloned, the VM settings are adjusted and the cloud-init configuration is put into the drive.
In the end, you should have a brand new VM created by terraform!

### Creating VMs for k3s
The above example is realistic but what if we need 5 similar VMs that could be used as kubernetes nodes?
Conveniently, terraform provides a `count` variable that we can use to slightly differ settings where needed.
Here is the resource that provisions the virtual machines that I run a k3s cluster on:
```hcl
resource "proxmox_vm_qemu" "proxmox_vm_k3s" {
	provider = proxmox.pve
	count = 5
	name = "deb-k3s-${count.index + 1}"
	target_node = "pve"

	clone = "debian-tmpl"
	os_type = "cloud-init"
	cores = 2
	sockets = 1
	cpu = "host"
	memory = 3084
	scsihw = "virtio-scsi-pci"
	bootdisk = "virtio0"
	agent = 0
	onboot = true

	disk {
		size = "30G"
		type = "virtio"
		storage = "local-zfs"
	}

	network {
		model = "virtio"
		bridge = "vmbr0"
	}

	ipconfig0 = "ip=192.168.15.5${count.index + 1}/16,gw=192.168.0.1"

	sshkeys = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC5jzKi37jm3517bqThbw+7LR/GXm3qC6Az5F+ZUa36vYM7Ygk2K5bWcFIL2YUCrkL5jfSsvoowONjCAxyuoyxtW4MJxnQLyq4u4yDsRC7YvBPAKZUYaHwnbkCfDs5a75dEFOoDxCA0DY2GrhqzBndaTcCfl0fZ4vN+9LcKOb1dSKiHeHvsh35YNtwntbL21meo+hiycUEgGwNe9/4kxKpdGTr7HvbeX2Fjm/UZBZIJKVcGop/3gCHXYnKH+OY5zc8cmt9Jg4CIwEqrSKeOX0bE8LSPRpVRXH4v8OcMaMei/HQejlH8NBwybEdJ4mhl8vHaFEjDbIWoOujmiRQF2263 angle@puddle"

	lifecycle {
		ignore_changes = [
			cipassword,
			network,
			desc,
		]
	}
}
```

There aren't many changes from the previous example, the name and the IP address use the index in order to avoid 5 VMs having the same name and IP address and that's it!

## Conclusion
Hopefully this gives you inspiration for some awesome things you can do to automate your infrastructure and make working in a virtualized environment easier.
Thank you for reading.
