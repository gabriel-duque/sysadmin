#!/bin/sh

# This strictly POSIX compliant script is used to install NixOS on my laptop

# We should not allow errors to occur
set -e

# ANSI color codes for logging functions
red='\e[31m'
grn='\e[32m'
yel='\e[33m'
rst='\e[0m'

# Necessary binaries to run this script
deps="nc parted cryptsetup pvcreate lvcreate mkfs.vfat mkfs.ext4 mkswap mount "
deps="${deps} mkdir swapon nixos-generate-config nixos-install"

# The disk on which we wish to install NixOS
disk=
# Our hostname
hostname=
# The volume group name
vg_name=
# The open LUKS device
crypt_dm=
# EFI system partition and its size
esp=
esp_size=
# LUKS formatted partition
crypt_part=

# Simple logging function
log() {
    printf -- "[${grn}*${rst}] $*\n"
}

# Warn but don't exit
warn() {
    printf -- "[${yel}*${rst}] $*\n"
}

# Print error and exit
die() {
    printf -- "[${red}*${rst}] $*\n"
    exit 1
}

# Print usage
print_usage() {
    printf -- "$(basename $0): -d [DISK] -H [HOSTNAME] -v [VGNAME] "
    printf -- "-c [CRYPTDM] -s [ESP_SIZE]\n"
}

# This is a sanity check that is used to check we have everythong we need to
# install our system before messing with disks and everything else
check_env() {
    for bin in $deps
    do
        if ! command -v "$bin" >/dev/null
        then
            die "Could not find $bin"
        fi
    done

    if ! nc -z nixos.org 80
    then
        die "Failed to connect to nixos.org. Are you connected to a network?"
    fi

    if ! [ -f "$(basename $0)/configuration.nix" ]
    then
        die "No configuration.nix file was found"
    fi
}

# Parse script arguments
parse_args() {
    while :
    do
        case $1 in
            -h|-\?)
                print_usage
                exit 0
                ;;
            -d)
                if [ -n "$2" ]
                then
                    disk="$2"
                    shift
                else
                    die "-d requires an argument"
                fi
                ;;
            -H)
                if [ -n "$2" ]
                then
                    hostname="$2"
                    shift
                else
                    die "-H requires an argument"
                fi
                ;;
            -v)
                if [ -n "$2" ]
                then
                    vg_name="$2"
                    shift
                else
                    die "-v requires an argument"
                fi
                ;;
            -c)
                if [ -n "$2" ]
                then
                    crypt_dm="$2"
                    shift
                else
                    die "-c requires an argument"
                fi
                ;;
            -s)
                if [ -n "$2" ]
                then
                    esp_size="$2"
                    shift
                else
                    die "-s requires an argument"
                fi
                ;;
            -?*)
                warn "Unknown argument: $1"
                ;;
            *)
                break
                ;;
        esac
        shift
    done
    if [ -n "$1" ]
    then
        warn "Unexpected parameters: $*"
    fi

    # Propagate the fact that variables were set
    disk="${disk:-/dev/sda}"
    esp="${disk}1"
    esp_size="${esp_size:-1GiB}"
    crypt_part="${disk}2"
    hostname="${hostname:-dragonite}"
    crypt_dm="${crypt_dm:-crypt${hostname}}"
    vg_name="${vg_name:-${hostname}}"
}

# Dump configuration to prompt the user for approval before doing anything
dump_args() {
    printf "Configuration:\n"
    printf "\t%-42s ${disk}\n" "Disk:"
    printf "\t%-42s ${esp}\n" "EFI system partition:"
    printf "\t%-42s ${esp_size}\n" "Size of the EFI system partition:"
    printf "\t%-42s ${crypt_part}\n" "LUKS encrypted device:"
    printf "\t%-42s ${crypt_dm}\n" "Mapping name for LUKS device:"
    printf "\t%-42s ${vg_name}\n" "Volume group name:"
    printf "\t%-42s ${hostname}\n" "Hostname:"
}

# Partition disk
partition_disk() {
    parted --script -- "${disk}" mklabel gpt

    parted -a opt --script -- "${disk}" mkpart primary fat32 0% "${esp_size}"
    parted -a opt --script -- "${disk}" name 1 ESP
    parted -a opt --script -- "${disk}" set 1 boot on

    parted -a opt --script -- "${disk}" mkpart primary "${esp_size}" 100%
    parted -a opt --script -- "${disk}" name 2 "${hostname}"
}

# Setup encryption (LUKS1 cause GRUB cryptoboot can't handle LUKS2)
make_filesystems() {

    cryptsetup -q -y luksFormat --type luks1 -c aes-xts-plain64 -s 256 \
        -h sha512 "${crypt_part}"

    cryptsetup -q luksOpen "${crypt_part}" "${crypt_dm}"

    # Setup LVM
    pvcreate -f -q "/dev/mapper/${crypt_dm}" >/dev/null

    vgcreate -f -q "${vg_name}" "/dev/mapper/${crypt_dm}" >/dev/null

    lvcreate -q --size 16G --name swap "${vg_name}" >/dev/null
    lvcreate -q --size 256G --name root "${vg_name}" >/dev/null
    lvcreate -q --extents '95%FREE' --name home "${vg_name}" >/dev/null

    # Create filesystems
    mkfs.vfat -F32 -n ESP "${esp}" >/dev/null
    mkfs.ext4 -q -L root "/dev/${vg_name}/root"
    mkfs.ext4 -q -m 0 -L home "/dev/${vg_name}/home"
    mkswap -L swap "/dev/${vg_name}/swap" >/dev/null
}

# Mount shit and swapon
mount_filesystems() {
    mount "/dev/${vg_name}/root" /mnt
    mkdir -p /mnt/{home,boot/efi}
    mount "${esp}" /mnt/boot/efi
    mount "/dev/${vg_name}/home" /mnt/home
    swapon "/dev/${vg_name}/swap"
}

# Generate out NixOS config
generate_nix_config() {
    # Create default NixOS config
    nixos-generate-config --root /mnt

    sed -i.orig -e \
        "s/crypt_part_uuid/$(blkid ${crypt_part} -o value -s UUID)/" \
        configuration.nix

    mv configuration.nix /mnt/etc/nixos/
}

# Cleanup
cleanup() {
    echo cleaning up
}

main() {
    check_env
    log "Passed environment check"

    parse_args $*
    log "Parsed arguments"

    dump_args

    printf "Is this okay for you? (y/n) "
    read ans
    if ! [ "${ans:0:1}" == "y" -o "${ans:0:1}" == "Y" ]
    then
        exit 1
    fi
    unset ans

    partition_disk
    log "Partitioned disk"

    make_filesystems
    log "Made filesystems"

    mount_filesystems
    log "Mounted filesystems"

    generate_nix_config
    log "Generated NixOS config"

    printf "Launching the actual installation\n"

    until nixos-install
    do
        printf "Something went wrong with nixos-install. Try again? (y/n) "
        read ans
        if ! [ "${ans:0:1}" == "y" -o "${ans:0:1}" == "Y" ]
        then
            cleanup
            exit 1
        fi
        unset ans
    done
    log "Succesfully installed NixOS"

    printf "Would you like to unmount all partitions and reboot? (y/n) "
    read ans

    if [ "${ans:0:1}" == "y" -o "${ans:0:1}" == "Y" ]
    then
        cleanup
        reboot
    fi
    unset ans
}
