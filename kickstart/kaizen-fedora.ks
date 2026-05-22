# Kaizen Linux Fedora Kickstart Prototype
#
# Goal:
# Create a Fedora-based Hyprland install target that can later become
# a proper live/remix ISO.
#
# This is an early prototype. The post-install script is still the source of truth.

lang en_GB.UTF-8
keyboard --vckeymap=gb --xlayouts='gb'
timezone Europe/London --utc

network --bootproto=dhcp --device=link --activate
url --url="https://download.fedoraproject.org/pub/fedora/linux/releases/44/Everything/x86_64/os/"
rootpw --lock
user --name=kaizen --groups=wheel --gecos="Kaizen User" --password=kaizen

firewall --enabled
selinux --enforcing
firstboot --disable

bootloader --location=mbr
clearpart --all --initlabel
part / --fstype=ext4 --size=10000

reboot

%packages
@core
@standard
git
curl
wget
bash-completion
dnf-plugins-core
flatpak
dracut-live
grub2-pc
grub2-pc-modules
grub2-efi-x64
shim-x64

grub2-efi-x64-cdboot
grub2-efi-x64-modules
grub2-tools
grub2-tools-efi
grub2-tools-extra
efibootmgr%end

%post --log=/root/kaizen-post.log
set -eux

cat > /etc/motd <<'MOTD'
Kaizen Linux Fedora Remix Prototype

This system was installed from the early Kickstart prototype.
Run the Kaizen installer after first login to complete the desktop setup.
MOTD

%end
