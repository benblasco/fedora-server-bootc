FROM quay.io/fedora/fedora-bootc:41

# RUN dnf -y golang && dnf clean all
# RUN ln -sfr /usr/lib/golang/bin/go /usr/bin/go

# Enable RPMfusion repos
RUN dnf install -y http://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm http://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
RUN dnf update -y

# Note: Removed packages ansible and ansible-lint because ansible-lint contains non UTF-8 characters in file names
# https://github.com/containers/bootc/issues/975
# Install common packages
RUN dnf install -y \
    p7zip p7zip-plugins unrar \
    vim-enhanced htop openssh-server grubby git \
    wpa_supplicant screen mc smartmontools \
    python3-requests-oauthlib \
    lm_sensors lm_sensors-sensord \
    java-11-openjdk dnf-utils \
    setools-console setroubleshoot-server \
    strace ncdu python3-pip \
    hdparm sdparm lshw \
    tuned cockpit* firewalld \
    python3-blivet stratis-cli stratisd \
    tmux \
    genisoimage cloud-utils \
    libgcrypt libgcrypt-devel libvirt libvirt-daemon-kvm qemu-kvm \
    python3-libvirt python3-lxml edk2-ovmf \
    alsa-utils

# Temporary package addition required for my Lenovo Yoga 370 laptop so I can test over wifi
#RUN dnf install -y \
#    pciutils inxi iwl\*

ADD files/journald.conf.d/persistentlogs.conf /etc/systemd/journald.conf.d/
ADD files/sudoers.d/wheel-passwordless-sudo /etc/sudoers.d/
ADD files/registries.conf.d/001-micro-lan.conf /etc/containers/registries.conf.d/
ADD files/chrony.conf /etc/

RUN mkdir -p /var/log/journal && chown root:systemd-journal /var/log/journal

RUN systemctl enable tuned.service && systemctl disable bootc-fetch-apply-updates.timer

# How to change rootless users' container storage location 
# https://access.redhat.com/solutions/7007159
# The below needs to be repeated post-install if a separate mount point is being created for container storage.
# This can be done through an ansible playbook or via other means
# Note: the sed command is using the "|" character as a delimiter
RUN mkdir -p -m 777 /var/mnt/containers && \
    cp -p /usr/share/containers/storage.conf /etc/containers/ && \
    sed -i '\|# rootless_storage_path|a rootless_storage_path = "/var/mnt/containers/$USER/storage"' /etc/containers/storage.conf && \
    semanage fcontext -a -t container_var_lib_t '/mnt/containers(/.*)?' && \
    restorecon -Rv /var/mnt/containers

# Set the timezone
RUN ln -s /usr/share/zoneinfo/Australia/Melbourne /etc/localtime