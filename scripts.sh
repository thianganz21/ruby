#!/bin/bash
# Copyright cc 2025 thian

# setup color
red='\033[0;31m'
green='\e[0;32m'
white='\033[0m'
yellow='\033[0;33m'
cyan='\033[0;36m'
blue='\033[0;34m'

KernelSU="default"
WORK_DIR=$(pwd)
CLANG_DIR="$WORK_DIR/myclang"
SECONDS=0 # builtin bash timer
DEVICE="ruby"
ZIPNAME="Thian-Kernel-$(date '+%Y%m%d-%H%M').zip"

export ARCH=arm64
export KBUILD_BUILD_USER=Thian
export KBUILD_BUILD_HOST=thianganz
export PATH="$CLANG_DIR/bin/:$PATH"



function make_defconfig(){
    echo -e "${yellow}Setting up Thian ruby defconfig...${white}"
    make ARCH=arm64 O=out ruby_defconfig
    make ARCH=arm64 O=out vendor/lz4kd.config
    make ARCH=arm64 O=out vendor/bbr.config
    make ARCH=arm64 O=out vendor/noop.config
    make ARCH=arm64 O=out vendor/lru.config
    echo -e "${red}Thian ruby defconfig set up successfully.${white}"
    echo -e "\n"
    printf "${yellow}Do you want to add vendor/kernelsu.config for KernelSU support to the defconfig? (y/n): ${white}"
    read -r add_kernelsu
    if [[ $add_kernelsu == "y" || $add_kernelsu == "Y" ]]; then
        make ARCH=arm64 O=out vendor/kernelsu.config
        echo -e "${red}vendor/kernelsu.config added successfully.${white}"
        KernelSU="enabled"
    else
        echo -e "${red}Skipping vendor/kernelsu.config addition.${white}"
        KernelSU="disabled"
    fi
    if [ "$KernelSU" == "enabled" ]; then
        echo -e "${green}KernelSU support is enabled in the defconfig.${white}"
        printf "${yellow}do you want to enable SUSFS support as well? (y/n): ${white}"
        read -r add_susfs
        if [[ $add_susfs == "y" || $add_susfs == "Y" ]]; then
            make ARCH=arm64 O=out vendor/susfs.config
            echo -e "${red}vendor/susfs.config added successfully.${white}"
        fi
    else
        echo -e "${green}KernelSU support is disabled in the defconfig.${white}"
    fi
    printf "\n${yellow}Do you want to add vendor/serial.config for arduino/esp32 to the defconfig? (y/n): ${white}"
    read -r add_serial
    if [[ $add_serial == "y" || $add_serial == "Y" ]]; then
        make ARCH=arm64 O=out vendor/serial.config
        echo -e "${red}vendor/serial.config added successfully.${white}"
    else
        echo -e "${red}Skipping vendor/serial.config addition.${white}"
    fi
    printf "\n${yellow}Do you want to add vendor/nethunter.config for nethunter to the defconfig? (y/n): ${white}"
    read -r add_nethunter
    if [[ $add_nethunter == "y" || $add_nethunter == "Y" ]]; then
        make ARCH=arm64 O=out vendor/nethunter.config
        echo -e "${red}vendor/nethunter.config added successfully.${white}"
    else
        echo -e "${red}Skipping vendor/nethunter.config addition.${white}"
    fi
    echo -e "\n"
    echo -e "${green}Defconfig setup complete.${white}"
    echo -e "\n"
    echo -e "${yellow}You can now proceed to build the kernel using ./script.sh build${white}"
}

function Build(){
    if [[ $1 = "-mc" || $1 = "--makeconfig" || $2 = "-mc" || $2 = "--makeconfig" ]]; then
        echo "[Thian Build Script] Make config for $DEVICE"
        make -j$(nproc) \
        O=out KCFLAGS="-O2 -march=armv8.2-a+crypto+fp16+dotprod -mcpu=cortex-a78 -mtune=cortex-a78" \
        ARCH=arm64 \
        LLVM=1 \
        LLVM_IAS=1 \
        CROSS_COMPILE=aarch64-linux-gnu- \
        CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
        thian_defconfig
    fi
    echo "[thian  Build Script] Starting building Image.gz-dtb for $DEVICE..."
    make -j$(nproc) \
    O=out KCFLAGS="-O2 -march=armv8.2-a+crypto+fp16+dotprod -mcpu=cortex-a78 -mtune=cortex-a78" \
    ARCH=arm64 \
    LLVM=1 \
    LLVM_IAS=1 \
    CROSS_COMPILE=aarch64-linux-gnu- \
    CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
    Image.gz-dtb
    
    kernel="out/arch/arm64/boot/Image.gz-dtb"
    
    if [ ! -f "$kernel" ]; then
        echo "[thian  Build Script] Compilation failed!"
        exit 1
    fi
    
    echo "[thian  Build Script] Kernel compiled successfully! Zipping up..."
    
    if [ -d "$AK3_DIR" ]; then
        cp -r $AK3_DIR AnyKernel3
    else
        if ! git clone -q https://github.com/thianganz21/AnyKernel3.git -b ruby AnyKernel3; then
            echo "[thian  Build Script] AnyKernel3 repo not found locally and couldn't clone from GitHub! Aborting..."
            exit 1
        fi
    fi
    
    cp $kernel AnyKernel3
    cd AnyKernel3
    zip -r9 "../$ZIPNAME" * -x .git
    cd ..
    rm -rf AnyKernel3
    echo "[thian  Build Script] Completed in $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s) !"
    echo "[thian  Build Script] Zip: $ZIPNAME"
}