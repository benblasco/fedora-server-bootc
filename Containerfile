FROM quay.io/fedora/fedora-bootc:41

# RUN dnf -y golang && dnf clean all
# RUN ln -sfr /usr/lib/golang/bin/go /usr/bin/go


# Note: Removed packages ansible and ansible-lint because ansible-lint contains non UTF-8 characters in file names
# https://github.com/containers/bootc/issues/975
# Enable RPMfusion repos, update, install common packages, clean up
RUN <<EOF
    dnf install -y http://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm http://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
    dnf update -y
    dnf install -y \
    p7zip p7zip-plugins unrar rsync \
    vim-enhanced htop openssh-server grubby git \
    wpa_supplicant screen mc smartmontools \
    python3-requests-oauthlib \
    lm_sensors lm_sensors-sensord \
    java-17-openjdk dnf-utils \
    setools-console setroubleshoot-server \
    strace ncdu python3-pip \
    hdparm sdparm lshw \
    tuned cockpit* firewalld \
    python3-blivet stratis-cli stratisd \
    tmux rclone tree \
    genisoimage cloud-utils \
    libgcrypt libgcrypt-devel libvirt libvirt-daemon-kvm qemu-kvm \
    python3-libvirt python3-lxml edk2-ovmf \
    podman buildah skopeo \
    alsa-utils fwupd-efi

    rm -rf /var/{cache,log} /var/lib/{dnf,rhsm}
EOF

# Packages required for each Ansible role
### Command to get the list
# cd /var/home/bblasco/.ansible/collections/ansible_collections/fedora/linux_system_roles/roles
# for i in `echo "storage firewall timesync cockpit podman"`; do echo ROLE $i; $i/.ostree/get_ostree_data.sh packages runtime Fedora-41 raw; done
### storage
# cryptsetup e2fsprogs kpartx libblockdev-crypto libblockdev-dm \
# libblockdev-lvm libblockdev-mdraid libblockdev-swap lvm2 python3-blivet \
# stratis-cli stratisd xfsprogs
### firewall
# firewalld
### timesync
# chrony linuxptp
### cockpit
# certmonger cockpit-* policycoreutils-python-utils python3-cryptography \
# python3-dbus python3-libselinux python3-packaging python3-policycoreutils \
# python3-pyasn1
### podman
# iptables-nft podman policycoreutils-python-utils \
# python3-libselinux python3-policycoreutils shadow-utils-subid

# java-11-openjdk is for Jenkins agent
# alsa-utils is for librespot
# fwupd-efi is for secure firmware updates via fwupdmgw
# libgcrypt libgcrypt-devel libvirt libvirt-daemon-kvm qemu-kvm is for stackhpc-libvirt-host role
# genisoimage cloud-utils is for use cloud-init when launching vms (stackhpc-libvirt-vm role)

# Temporary package addition required for my Lenovo Yoga 370 laptop so I can test over wifi
#RUN dnf install -y \
#    pciutils inxi iwl\*

# Copy persistent config files for:
# - Persistent journal logs
# - sudoers config
# - Private container registry
# - Chrony config
COPY files/etc /etc/

# Create the journal file
RUN <<EOF 
    mkdir -p /var/log/journal 
    chown root:systemd-journal /var/log/journal
EOF

# Enable tuned, podman-podman-auto-update, and disable bootc auto updates
RUN <<EOF 
    systemctl enable tuned.service
    systemctl enable podman-auto-update.timer
    systemctl mask bootc-fetch-apply-updates.timer
EOF

# How to change rootless users' container storage location 
# https://access.redhat.com/solutions/7007159
# The below needs to be repeated post-install if a separate mount point is being created for container storage.
# This can be done through an ansible playbook or via other means
# Note: the sed command is using the "|" character as a delimiter
RUN <<EOF
    mkdir -p -m 777 /var/mnt/containers
    cp -p /usr/share/containers/storage.conf /etc/containers/
    sed -i '\|# rootless_storage_path|a rootless_storage_path = "/var/mnt/containers/$USER/storage"' /etc/containers/storage.conf
    semanage fcontext -a -t container_var_lib_t '/mnt/containers(/.*)?'
    restorecon -Rv /var/mnt/containers
EOF

# Set the timezone
RUN ln -s /usr/share/zoneinfo/Australia/Melbourne /etc/localtime

# Lint the container image
RUN bootc container lint
