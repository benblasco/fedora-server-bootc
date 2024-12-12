FROM quay.io/fedora/fedora-bootc:41

# RUN dnf -y golang && dnf clean all
# RUN ln -sfr /usr/lib/golang/bin/go /usr/bin/go

# Timezone

# Enable RPMfusion repos
RUN dnf install -y http://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm http://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
RUN dnf update -y

# Add bblasco user

# Create media group gid 1001 user uid 1001

# Add media group as secondary group for bblasco

# Install common packages
RUN dnf install -y \
    p7zip p7zip-plugins unrar \
    vim-enhanced htop openssh-server grubby git \
    wpa_supplicant screen mc smartmontools \
    ansible ansible-lint \
    python3-requests-oauthlib \
    lm_sensors lm_sensors-sensord \
    java-11-openjdk dnf-utils \
    setools-console setroubleshoot-server \
    strace ncdu python3-pip \
    hdparm sdparm lshw \
    tuned cockpit* firewalld

ADD files/journald.conf.d/persistentlogs.conf /etc/systemd/journald.conf.d/
ADD files/sudoers.d/wheel-passwordless-sudo /etc/sudoers.d/
ADD files/registries.conf.d/001-micro-lan.conf /etc/registries.conf.d/

RUN mkdir -p /var/log/journal && chown root:systemd-journal /var/log/journal

RUN systemctl enable tuned.service && systemctl disable bootc-fetch-apply-updates.timer

# Run timesync role WHICH WORKS
# Run cockpit role WHICH WORKS IF YOU ALREADY HAVE THE RIGHT PACKAGES INSTALLED
# Run podman role WHICH WORKS IF YOU ALREADY HAVE THE RIGHT PACKAGES INSTALLED
# Run tmux role WORKS IF TMUX ALREADY INSTALLED --skip-tags=install-tmux
# Run librespot role
# Install virtualisation stack
# LVM Partitioning
