%pre

mkdir -p /etc/containers/registries.conf.d/
cat > /etc/containers/registries.conf.d/001-micro-lan.conf << 'EOF'
# Allow use of micro.lan as an insecure registry
# https://containers.github.io/bootc/registries-and-offline.html
[[registry]]
location="micro.lan:5000"
insecure=true
EOF

cat > /etc/containers/registries.conf.d/002-nuc-lan.conf << 'EOF'
# Allow use of nuc.lan as an insecure registry
# https://containers.github.io/bootc/registries-and-offline.html
[[registry]]
location="nuc.lan:5000"
insecure=true
EOF

%end

text --non-interactive
network --bootproto=dhcp --device=link --activate --onboot=on
zerombr
# For the command below it is critical to specify the disk otherwise it will erase ALL disks attached to the system
clearpart --drives=sda --all --initlabel --disklabel=gpt
reqpart --add-boot
#autopart --noswap --type=lvm

# Disable kernel mitigations
# Disable graphics driver loading until after boot (Microserver only)
# What is "nomodeset" kernel parameter and is it safe to use?
# https://access.redhat.com/solutions/81623
bootloader --append="mitigations=off nomodeset"

# Add the container image to install
#ostreecontainer --url nuc.lan:5000/fedora-bootc-testserver:latest --no-signature-verification --transport=registry
# Colin Walters: "You don't need --no-signature-verification anymore, it does nothing"
ostreecontainer --url nuc.lan:5000/fedora-bootc-testserver:latest --transport=registry

# Disk partitioning information
# https://developers.redhat.com/articles/2024/08/20/bare-metal-deployments-image-mode-rhel?source=sso#example_kickstart
part pv.01 --size=40208 --grow --ondisk=sda
volgroup vg_fedora pv.01
logvol / --vgname=vg_fedora --size=25200 --name=lv_root --fstype=xfs
logvol /var --vgname=vg_fedora --size=10240 --name=lv_var --fstype=xfs
logvol /var/log --vgname=vg_fedora --size=10240 --name=lv_varlog --fstype=xfs
logvol /var/home --vgname=vg_fedora --size=20480 --name=lv_home --fstype=xfs
logvol /var/lib/containers/storage --vgname=vg_fedora --size=20480 --name=lv_root_containers --fstype=xfs
logvol /var/mnt/containers --vgname=vg_fedora --size=40960 --name=lv_user_containers --fstype=xfs
logvol /var/lib/libvirt/vm-pool --vgname=vg_fedora --size=40960 --name=lv_vm_pool --fstype=xfs
logvol swap --vgname vg_fedora --recommended --name=lv_swap --fstype=swap

# https://docs.fedoraproject.org/en-US/fedora/f36/install-guide/appendixes/Kickstart_Syntax_Reference/#sect-kickstart-commands-users-groups
# Generate an ssh key using the command `openssl passwd -6`
group --name=media --gid=1001
user --name=media --uid=1001 --gid=1001 --homedir=/var/home/media
group --name=bblasco --gid=1000
user --name=bblasco --uid=1000 --gid=1000 --homedir=/var/home/bblasco --shell=/bin/bash --groups=wheel,media,libvirt --iscrypted --password=$6$ArTIFqSrXLP8FNs6$bRAmZtJduALiKsZOSMo28mnW8nlNKqPw7zTf5YMdaTgsqjLHqGNYS4zoGRd1v43rF8P16araFnQabBuFxyNfL.
sshkey --username bblasco "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCY9P2Hh1ultuvNlBGHxQGNYlDkB35Z/kPQNR+tfsYaO2gGLhbtkVI0uoXf5SewEz5ecH+u8jHIPElXZz227h5PpxhZFzfokqUJ/U3mbEpu1/Krf4/eERCqIgz2nmXoGLlOJHgMk4MpK6LA6eb6SXZHLpxFicbEcCxUU3A9hbzhWUGDaMFG7CcExT5JAD/7VcniONxZhlJxUzyL1xmbmAN13DQpiUkew25VtuNHby1fYTgMxVaezUMfMwZn6qpNJUDXGCKX1NWv5kqB9yFxRIQbFS4zAkQPXH6w7eksNyknexRDwM1zghnaspSvE1Kn2RWIaKt5hmaoKozJuC9YnCwJ bblasco@localhost.localdomain"

%post --log=/root/ks-post.log

# Note we are setting the path to /mnt/containers because there's already
# an SELinux equivalency rule between /var/mnt and /mnt
# See the output of `semanage fcontext --list | grep mnt`
# The commands wouldn't work on /var/mnt/containers
# See examples here:
# https://linux.die.net/man/8/semanage
# https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/6/html/security-enhanced_linux/sect-security-enhanced_linux-selinux_contexts_labeling_files-persistent_changes_semanage_fcontext#sect-Security-Enhanced_Linux-SELinux_Contexts_Labeling_Files-Persistent_Changes_semanage_fcontext
# https://www.redhat.com/en/blog/semanage-keep-selinux-enforcing
#semanage fcontext -a -e /var/lib/containers /mnt/containers
semanage fcontext -a -e /var/lib/containers '/mnt/containers(/.*)?'
restorecon -Rv /mnt/containers
chmod 777 /var/mnt/containers

cat >> /etc/fstab<<EOF
LABEL=SEAGATE1 /var/mnt/sg1 ext4 defaults,nofail 0 0
LABEL=WD_SG3 /var/mnt/sg3 ext4 defaults,nofail 0 0
LABEL=WD_XFS1 /var/mnt/wd_xfs1 xfs defaults,nofail 0 0
LABEL=WD_MARTIN /var/mnt/martinbackup ext4 defaults,nofail 0 0
LABEL=WD_SPARE /var/mnt/spare xfs defaults,nofail 0 0
nuc.lan:/var/mnt/sg2 /mnt/sg2 nfs x-systemd.after=network-online.target 0 0
nuc.lan:/var/mnt/vm_images /mnt/vm_images nfs x-systemd.after=network-online.target 0 0
EOF

%end

reboot
