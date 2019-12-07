# Partition disk
parted --script -- /dev/sda mklabel gpt

parted --script -- /dev/sda mkpart primary fat32 0% 1GiB
parted --script -- /dev/sda set 1 boot on
parted --script -- /dev/sda name 1 ESP

parted --script -- /dev/sda mkpart primary 1GiB 100%
parted --script -- /dev/sda name 2 dragonite

# Setup encryption (LUKS1 cause GRUB can't handle LUKS2)
cryptsetup luksFormat --type luks1 -c aes-xts-plain64 -s 256 -h sha512 /dev/sda2
cryptsetup luksOpen /dev/sda2 cryptdragonite

# Setup LVM
pvcreate /dev/mapper/cryptdragonite

vgcreate dragonite /dev/mapper/cryptdragonite

lvcreate --size 16G --name swap dragonite
lvcreate --size 256G --name root dragonite
lvcreate --extents '95%FREE' --name home dragonite

# Create filesystems
mkfs.vfat -F32 -n ESP /dev/sda1
mkswap -L swap /dev/dragonite/swap
mkfs.ext4 -L root /dev/dragonite/root
mkfs.ext4 -m 0 -L home /dev/dragonite/home

# Mount shit and swapon
mount /dev/dragonite/root /mnt
mkdir -p /mnt/{home,boot/efi}
mount /dev/sda1 /mnt/boot/efi/
mount /dev/dragonite/home /mnt/home/
swapon /dev/dragonite/swap

# Create default NixOS config
nix-generate-config --root /mnt
# Edit shit so it looks good
nixos-install
reboot
