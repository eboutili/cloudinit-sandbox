# Cloud-init/Cloud-config

## Intro: 

I'm kinda getting hooked on cloud-init/cloud-config. It's just a Linux tool for
bootstrapping cloud images, but unlike similar tools it's almost always
pre-installed. In other words, it's baked into most Linux images accross most
cloud vendors. That feature alone gives you a lot of leverage right off the
bat.  I've tested the examples below on 6 combinations: Centos and Ubuntu on
DigitalOcean, AWS, and Azure.

## Cloud-Config: 

The **Cloud-config** part is the spec. It's a coding format for user data
(called custom data on Azure). User data lets you programatically control how
a VM gets stood up from an image. 99% of the time that's done with bash
scripting. By contrast, cloud-config is declarative, which I like a lot. 

## Cloud-init:
The **cloud-init** part is the program itself, which (as I said above) is pretty much
pre-installed everywhere now. Cloud-init's job is to process the declarative (yaml) code you wrote.

## Example 1
Suppose you're bootstrapping a VM from a cloud image and want this to happen automatically:

1. Upgrade the packages to the latest versions (reduces potential attack vectors
  that the image you're booting might be behind on)
2. Ensure your favorite command line tools are installed. In this example: `wget, git`, and `jq`
3. Reboot at the end (because eg the kernel might have gotten patched in the 1st step)

```
#cloud-config
package_update: true
package_upgrade: true

packages:
  - wget
  - git
  - jq

power_state:
  mode: reboot
```

## Example 2

For a more comprehensive example, here's a cloud-config manifest I wrote after teaching
myself how to stand up a Kubernetes cluster from scratch. It captures what I learned
as self-documenting code, which I also like a lot.

Here's what it does: 

Everything the first example does, plus:

- Deploy this node as a kubernetes master (or worker):
  1. Configure the canonical kubernetes package repo
  2. Download and install the components (kubeadm, kubectl, docker engine, etc.)
  3. Enable the kubernetes master services

It also creates a consistent login account for ssh access, overriding the
(annoyingly) inconsistent defaults (sometimes "root",
sometimes "ubuntu", etc.). The account in this example is called kubeplay: It
creates the kubeplay user, associates whatever key pair you want (writes the
provided public key to the authorized_keys file); and gives kubeplay sudo
privileges.

```
#cloud-config
package_update: true
package_upgrade: true

packages:
  - kubelet
  - kubeadm
  - kubernetes-cni

runcmd:
  - export VERSION=18.06 && curl -sSL get.docker.com | sh
  - systemctl start docker
  - systemctl enable docker
  - grep -q '^ID=.*centos' /etc/os-release && setenforce 0 && sed -i 's/SELINUX=enforcing/SELINUX=permissive/g' /etc/selinux/config

  - kubeadm init  --pod-network-cidr=10.244.0.0/16 --service-cidr=10.96.0.0/12
  - kubectl apply --kubeconfig /etc/kubernetes/admin.conf -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

apt_sources:
- source: deb http://apt.kubernetes.io/ kubernetes-xenial main
- key: |
       -----BEGIN PGP PUBLIC KEY BLOCK-----

       mQENBFrBaNsBCADrF18KCbsZlo4NjAvVecTBCnp6WcBQJ5oSh7+E98jX9YznUCrN
       rgmeCcCMUvTDRDxfTaDJybaHugfba43nqhkbNpJ47YXsIa+YL6eEE9emSmQtjrSW
       IiY+2YJYwsDgsgckF3duqkb02OdBQlh6IbHPoXB6H//b1PgZYsomB+841XW1LSJP
       YlYbIrWfwDfQvtkFQI90r6NknVTQlpqQh5GLNWNYqRNrGQPmsB+NrUYrkl1nUt1L
       RGu+rCe4bSaSmNbwKMQKkROE4kTiB72DPk7zH4Lm0uo0YFFWG4qsMIuqEihJ/9KN
       X8GYBr+tWgyLooLlsdK3l+4dVqd8cjkJM1ExABEBAAG0QEdvb2dsZSBDbG91ZCBQ
       YWNrYWdlcyBBdXRvbWF0aWMgU2lnbmluZyBLZXkgPGdjLXRlYW1AZ29vZ2xlLmNv
       bT6JAT4EEwECACgFAlrBaNsCGy8FCQWjmoAGCwkIBwMCBhUIAgkKCwQWAgMBAh4B
       AheAAAoJEGoDCyG6B/T78e8H/1WH2LN/nVNhm5TS1VYJG8B+IW8zS4BqyozxC9iJ
       AJqZIVHXl8g8a/Hus8RfXR7cnYHcg8sjSaJfQhqO9RbKnffiuQgGrqwQxuC2jBa6
       M/QKzejTeP0Mgi67pyrLJNWrFI71RhritQZmzTZ2PoWxfv6b+Tv5v0rPaG+ut1J4
       7pn+kYgtUaKdsJz1umi6HzK6AacDf0C0CksJdKG7MOWsZcB4xeOxJYuy6NuO6Kcd
       Ez8/XyEUjIuIOlhYTd0hH8E/SEBbXXft7/VBQC5wNq40izPi+6WFK/e1O42DIpzQ
       749ogYQ1eodexPNhLzekKR3XhGrNXJ95r5KO10VrsLFNd8I=
       =TKuP
       -----END PGP PUBLIC KEY BLOCK-----

yum_repos:
  kubernetes: 
    baseurl: "https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64"
    gpgcheck: true
    name: Kubernetes
    enabled: true
    gpgkey: "https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg"

users:
  - name: kubeplay
    groups: sudo
    shell: /bin/bash
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    ssh_authorized_keys:
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDgziKzVUGbkCohTBchVQgHHjL70mudkwUUX4h1cbW4FT9OvVePD3KsklUqOoLNb6Be11jlRTtmvGcOVBriLBWIhIu+UhQvnwDkePIx0WSwYocGMzttnQulKeCg9kBHGUaS2ofnNGC6bJZwWLC4EVqRW0v5p2eEOFWq70OJKv05V0evLLzDbShuLkVafDv8+5M7rMhd/Ik/4aV9/joQ1JW7EVZNlT89YHv3W3C+qmSlNxYBmyEoCRq82L8MSiYRaPz6DOiURwRYYX24sRUQIoyeKfXkkpbWcDK9JGvHpQ6yu63Z6NXLv0I5A68nUp57oqQCkgT2KI894G36GWEzVcdc4FEqc5AQkTeefq0DwFSvQtAvymg/jZBj9IaCN7vGAHxm+I1S3EFmT1zgQKxmgKXKMRHgmKBHxesiE/DObbOkoAwVNsBc0VhYLSFDwzGrgo1mBMDgUhWQtVHbh81wmpOjU5OnBcG4VbBlclDkLF7kMVSdl04rqu4fdnYbLGfiwfVgMNlZRQQT5X07NEd0d/6VZrTcgPNVsi5BDzCY+h2XWCLkhOykwg+WgnuFF+gU++Mfoq7mlNx53Owcsh5SnSoglvSmI1h5oFkhGaEENWeq0oXDfoi8lM4aid83JUIuBSA6sHoo1XzAFRkMKurg61KatleGn+7RT/+nPGJYSipqpw==
```

