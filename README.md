# fedora-server-bootc
Configs and automation for deploying Fedora bootc based servers in my home lab

# Links

Bootc docs
https://osbuild.org/docs/bootc/

config.toml file
https://github.com/osbuild/bootc-image-builder/?tab=readme-ov-file#-build-config

Blueprint reference
https://osbuild.org/docs/user-guide/blueprint-reference

# Build the container

```
sudo podman build --squash -t fedora-bootc-testserver:latest . 
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
--local \
localhost/fedora-bootc-testserver:latest
```

# Push to my local registry

```
sudo podman push --tls-verify=false localhost/fedora-bootc-testserver:latest <registry host>:5000/fedora-bootc-testserver:latest
```

# Switch running image to my local registry

```
sudo bootc switch <registry host>:5000/fedora-bootc-testserver:latest
```

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


