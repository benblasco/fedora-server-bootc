%pre
mkdir -p /etc/containers/registries.conf.d/
cat > /etc/containers/registries.conf.d/local-registry.conf << 'EOF'
# Allow use of micro.lan as an insecure registry
# https://containers.github.io/bootc/registries-and-offline.html
[[registry]]
location="micro.lan:5000"
insecure=true
EOF
%end

text --non-interactive
network --bootproto=dhcp --device=link --activate --onboot=on
zerombr
# For the command below it is critical to specify the disk otherwise it will erase ALL disks attached to the system
clearpart --drives=sda3 --all --initlabel --disklabel=gpt
reqpart --add-boot
#autopart --noswap --type=lvm

# Add the container image to install
ostreecontainer --url micro.lan:5000/fedora-bootc-testserver:latest --no-signature-verification --transport=registry

# Disk partitioning information
# https://developers.redhat.com/articles/2024/08/20/bare-metal-deployments-image-mode-rhel?source=sso#example_kickstart
part pv.01 --size=40208 --grow --ondisk=nvme0n1
volgroup vg_fedora pv.01
logvol / --vgname=vg_fedora --size=25200 --name=lv_root --fstype=xfs
logvol /var --vgname=vg_fedora --size=10240 --name=lv_var --fstype=xfs
logvol /var/log --vgname=vg_fedora --size=10240 --name=lv_varlog --fstype=xfs
logvol /var/home --vgname=vg_fedora --size=20480 --name=lv_home --fstype=xfs
logvol /var/lib/containers/storage --vgname=vg_fedora --size=10240 --name=lv_root_containers --fstype=xfs
logvol /var/mnt/containers/storage --vgname=vg_fedora --size=10240 --name=lv_user_containers --fstype=xfs
logvol /var/lib/libvirt/vm-pool --vgname=vg_fedora --size=204800 --name=lv_vm_pool --fstype=xfs

# https://docs.fedoraproject.org/en-US/fedora/f36/install-guide/appendixes/Kickstart_Syntax_Reference/#sect-kickstart-commands-users-groups
# Generate an ssh key using the command `openssl passwd -6`
group --name=media --gid=1001
user --name=media --uid=1001 --gid=1001 --homedir=/var/home/media
group --name=bblasco --gid=1000
user --name=bblasco --uid=1000 --gid=1000 --homedir=/var/home/bblasco --shell=/bin/bash --groups=wheel,media,libvirt --iscrypted --password=$6$ArTIFqSrXLP8FNs6$bRAmZtJduALiKsZOSMo28mnW8nlNKqPw7zTf5YMdaTgsqjLHqGNYS4zoGRd1v43rF8P16araFnQabBuFxyNfL.
sshkey --username bblasco "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCY9P2Hh1ultuvNlBGHxQGNYlDkB35Z/kPQNR+tfsYaO2gGLhbtkVI0uoXf5SewEz5ecH+u8jHIPElXZz227h5PpxhZFzfokqUJ/U3mbEpu1/Krf4/eERCqIgz2nmXoGLlOJHgMk4MpK6LA6eb6SXZHLpxFicbEcCxUU3A9hbzhWUGDaMFG7CcExT5JAD/7VcniONxZhlJxUzyL1xmbmAN13DQpiUkew25VtuNHby1fYTgMxVaezUMfMwZn6qpNJUDXGCKX1NWv5kqB9yFxRIQbFS4zAkQPXH6w7eksNyknexRDwM1zghnaspSvE1Kn2RWIaKt5hmaoKozJuC9YnCwJ bblasco@localhost.localdomain"

reboot
