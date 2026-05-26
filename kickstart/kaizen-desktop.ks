# Kaizen Linux Desktop ISO Kickstart Prototype

lang en_GB.UTF-8
keyboard --vckeymap=gb --xlayouts='gb'
timezone Europe/London --utc

network --bootproto=dhcp --device=link --activate
url --url="https://download.fedoraproject.org/pub/fedora/linux/releases/44/Everything/x86_64/os/"

rootpw --lock
user --name=kaizen --groups=wheel --gecos="Kaizen User" --password=kaizen --plaintext --plaintext

firewall --enabled
selinux --enforcing
firstboot --disable

bootloader --location=mbr
clearpart --all --initlabel
part / --fstype=ext4 --size=18000

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
grub2-efi-x64-cdboot
grub2-efi-x64-modules
grub2-tools
grub2-tools-efi
grub2-tools-extra
shim-x64
efibootmgr
%end

%post --log=/root/kaizen-desktop-post.log
set -eux

printf "Kaizen Linux Desktop ISO Prototype\n\n" > /etc/motd
printf "This system was built from the Kaizen desktop Kickstart prototype.\n" >> /etc/motd

rm -rf /opt/kaizen-linux
git clone --branch full-rice-integration --single-branch https://github.com/Aetherelic/Kaizen-Linux.git /opt/kaizen-linux

cd /opt/kaizen-linux
bash scripts/kaizen-image-postinstall.sh kaizen

printf "Kaizen desktop postinstall completed.\n" >> /etc/motd
%end
