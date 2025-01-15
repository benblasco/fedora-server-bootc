# fedora-server-bootc
Configs and automation for deploying Fedora bootc based servers in my home lab

# Links

Bootc docs
https://osbuild.org/docs/bootc/

config.toml file
https://github.com/osbuild/bootc-image-builder/?tab=readme-ov-file#-build-config

Blueprint reference
https://osbuild.org/docs/user-guide/blueprint-reference

Master the art of bare metal deployments with image mode for RHEL
https://developers.redhat.com/articles/2024/08/20/bare-metal-deployments-image-mode-rhel

Jumpstart GitOps with image mode 
https://www.redhat.com/en/blog/jumpstart-gitops-image-mode

# Build the container

```
sudo podman build --squash -t fedora-bootc-testserver:latest . 
```
Note: `--squash` is optional, and possibly not helpful

# Push to my local registry

```
sudo podman push --tls-verify=false localhost/fedora-bootc-testserver:latest <registry host>:5000/fedora-bootc-testserver:latest
```

# Generate the bootable image

```
sudo podman run --rm -it \
--privileged \
--security-opt label=type:unconfined_t  \
--pull=newer \
-v ./config.toml:/config.toml:ro \
-v .:/output \
-v /var/lib/containers/storage:/var/lib/containers/storage \
quay.io/centos-bootc/bootc-image-builder:latest \
--type qcow2 \
--rootfs btrfs \
--progress verbose \
--local \
<registry host>:5000/fedora-bootc-testserver:latest
```

# Switch running image to my local registry

Note: This is only necessary if your bootable image was built using a different location for the container image.

```
sudo bootc switch <registry host>:5000/fedora-bootc-testserver:latest
```

# Alternate baremetal deployment method: use mkksiso

Source: https://weldr.io/lorax/mkksiso.html
Thank you to Achilleas Koutsou from the Image Builder team for his time and help!

1. Put everything you need into a kickstart file, and ensure it contains an `ostreecontainer` directive pointing at the container image, e.g. 
`ostreecontainer --url <registry host>:5000/fedora-bootc-testserver:latest --no-signature-verification --transport=registry`
2. Locally: `dnf install mkksiso`
3. Locally: Download a Fedora netinst iso (the smallest you can find)
4. Use mkksiso to generate an iso using the source iso and the kickstart file, e.g. 
`mkksiso --ks config-nuc-kickstart.ks Fedora-Server-netinst-x86_64-41-1.4.iso nuc-kickstart.iso`
5. Write the iso to usb and insert into the system you are installing

# If you want to watch a text based automated install of an iso image in a KVM deployment

Edit the bootloader entry at boot time by:
1. Pressing `e` to edit
2. Navigating to the end of the `linux` line
3. Adding `console=ttyS0,9600` to the line
4. Pressing ctrl+x to resume booting the iso

Note: Do not use the delete key to delete characters, and also note that the backspace key acts like the delete key in that it deletes forward, but not backward!

# Tasks to complete

 - [ ] Set the hostname ANSIBLE (not yet supported by blueprints for bootc)
 - [ ] Set the time zone and NTP servers (not yet supported by blueprints for bootc)
 - [ ] Set the time zone ANSIBLE
 - [ ] Run timesync role WHICH WORKS SHOULD I USE THIS INSTEAD?
 - [ ] Run cockpit role WHICH WORKS IF YOU ALREADY HAVE THE RIGHT PACKAGES INSTALLED
 - [ ] Test cockpit WORKS FINE
 - [ ] Run podman role WHICH WORKS IF YOU ALREADY HAVE THE RIGHT PACKAGES INSTALLED
 - [ ] Test a podman container BOTH ROOTFUL AND ROOTLESS WORK
 - [ ] Run tmux role WORKS IF TMUX ALREADY INSTALLED --skip-tags=install-tmux
 - [ ] Run librespot role
 - [ ] Install virtualisation stack
 - [ ] LVM Partitioning via storage role WORKS IF YOU ALREADY HAVE THE RIGHT PACKAGES INSTALLED
 - [ ] NFS Mounts via storage role WORKS IF YOU ALREADY HAVE THE RIGHT PACKAGES INSTALLED
 - [ ] Container storage.conf DOES NOT WORK BECAUSE IT'S IN READ ONLY FS /usr/share/containers/storage.conf FIXED BY RUN COMMAND IN CONTAINERFILE
 - [ ] Container storage volume needs to be created for /var/lib/containers

## Ansible roles/playbooks to test
 - [x] Set the hostname


