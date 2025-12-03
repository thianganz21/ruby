#!/bin/bash
# Copyright cc 2025 thian

# setup color
red='\033[0;31m'
green='\e[0;32m'
white='\033[0m'
yellow='\033[0;33m'
cyan='\033[0;36m'
blue='\033[0;34m'


WORK_DIR=$(pwd)
NAME_ZIP="$(ls "$WORK_DIR"/Thian-Kernel-*.zip 2>/dev/null | head -n 1)"
KERNEL_SUPPORT=KernelSU-Next/kernel/setup.sh
KernelSU="default"
SUSFS="default"
SERIAL="default"
NETHUNTER="default"

OUT_DIR="${WORK_DIR}/out"
TMP_DIR="$WORK_DIR/.tmp"
CLANG_DIR="$WORK_DIR/myclang"
SECONDS=0 # builtin bash timer
DEVICE="ruby"
ZIPNAME="Thian-Kernel-$(date '+%Y%m%d-%H%M').zip"

CONFIG_DIR="${WORK_DIR}/arch/arm64/configs"
CONFIG_BOT_TELEGRAM="${WORK_DIR}/.bot"
CONFIG_FILE="${CONFIG_BOT_TELEGRAM}/bot_token.json"
IMG_DIR="${OUT_DIR}/arch/arm64/boot/"
KERNEL_SUPPORT_CONFIG_FILE="${TMP_DIR}/kernel_support_config.json"

export ARCH=arm64
export KBUILD_BUILD_USER=Thian
export KBUILD_BUILD_HOST=thianganz
export PATH="$CLANG_DIR/bin/:$PATH"

URL_CLANG="https://gitlab.com/crdroidandroid/android_prebuilts_clang_host_linux-x86_clang-r530567.git" # clang-r530567 (19)
URL_CLANG2="https://gitlab.com/crdroidandroid/android_prebuilts_clang_host_linux-x86_clang-r498229b.git" #clang-r498229b (17.0.4)
Clang_DIR="myclang"


function makebot_config(){
    echo -e "\n"
    echo -e "${yellow} << setup bot telegram >> ${white}\n"
    echo -e "\n"
    
    
    if [ ! -d "$CONFIG_BOT_TELEGRAM" ]; then
        mkdir -p "$CONFIG_BOT_TELEGRAM"
    fi
    
    
    if [ ! -f "$CONFIG_FILE" ]; then
        echo -e "${yellow}Creating bot configuration...${white}"
        printf "Enter your Telegram Bot Token: "
        read BOT_TOKEN
        
        printf "Enter your Telegram Chat ID: "
        read CHAT_ID
        
        cat > "$CONFIG_FILE" << EOF
{
    "token": "$BOT_TOKEN",
    "chat_id": "$CHAT_ID"
}
EOF
        echo -e "${green}Bot configuration saved successfully.${white}"
        
    else
        
        echo -e "${yellow}Bot configuration already exists at $CONFIG_FILE.${white}"
        printf "${yellow}Do you want to delete old config and create a new one? (y/n): ${white}"
        read ANS
        
        if [ "$ANS" = "y" ]; then
            rm -f "$CONFIG_FILE"
            echo -e "${yellow}Creating new bot configuration...${white}"
            
            printf "Enter your Telegram Bot Token: "
            read BOT_TOKEN
            
            printf "Enter your Telegram Chat ID: "
            read CHAT_ID
            
            cat > "$CONFIG_FILE" << EOF
{
    "token": "$BOT_TOKEN",
    "chat_id": "$CHAT_ID"
}
EOF
            
            echo -e "${green}New bot configuration saved successfully.${white}"
        else
            echo -e "${green}Keeping existing configuration.${white}"
        fi
    fi
    
    echo -e "\n"
}



function make_defconfig(){
    echo -e "\n"
    echo -e "\n"
    echo -e "${yellow}Setting up Thian ruby defconfig...${white}"
    echo -e "\n"
    echo -e "\n"
    printf "${yellow}Do you want to add vendor/kernelsu.config for KernelSU support to the defconfig? (y/n): ${white}"
    read -r add_kernelsu
    if [[ $add_kernelsu == "y" || $add_kernelsu == "Y" ]]; then
        if [ ! -f "$KERNEL_SUPPORT" ]; then
            echo -e "${green}Installing kernelsu-next...${white}"
            curl -LSs "https://raw.githubusercontent.com/thianganz21/ksun/refs/heads/next/kernel/setup.sh" | bash -s next
            echo -e "${red}kernelsu-next installed successfully.${white}"
            make ARCH=arm64 O=out vendor/kernelsu.config
            echo -e "${red}kernelsu.config added successfully.${white}"
            KernelSU="enabled"
        else
            echo -e "${green}KERNELSU-NEXT already exists. Skipping installation.${white}"
        fi
    else
        if [  -f "$KERNEL_SUPPORT" ]; then
            echo -e"${green}Removing kernelsu-next...${white}"
            ./$KERNEL_SUPPORT --cleanup
            echo -e "${red}kernelsu-next removed successfully.${white}"
        fi
        
        echo -e "${red}Skipping kernelsu.config addition.${white}"
        KernelSU="disabled"
    fi
    
    
    if [ "$KernelSU" == "enabled" ]; then
        
        make ARCH=arm64 O=out ruby_defconfig
        make ARCH=arm64 O=out vendor/lz4kd.config
        make ARCH=arm64 O=out vendor/bbr.config
        make ARCH=arm64 O=out vendor/noop.config
        make ARCH=arm64 O=out vendor/lru.config
        echo -e "${red}Thian ruby defconfig set up successfully.${white}"
        echo -e "\n"
        
        echo -e "${green}KernelSU support is enabled in the defconfig.${white}"
        printf "${yellow}do you want to enable SUSFS support as well? (y/n): ${white}"
        read -r add_susfs
        if [[ $add_susfs == "y" || $add_susfs == "Y" ]]; then
            make ARCH=arm64 O=out vendor/susfs.config
            echo -e "${red}susfs.config added successfully.${white}"
            SUSFS="enabled"
        fi
    else
        echo -e "${green}KernelSU support is disabled in the defconfig.${white}"
        SUSFS="disabled"
    fi
    
    if [ "$KernelSU" == "enabled" ]; then
        printf "\n${yellow}Do you want to enable Serial over USB support for arduino/esp32  to the defconfig? (y/n): ${white}"
        read -r add_serial
        if [[ $add_serial == "y" || $add_serial == "Y" ]]; then
            make ARCH=arm64 O=out vendor/serial.config
            echo -e "${red}serial.config added successfully.${white}"
            SERIAL="enabled"
        else
            echo -e "${red}Skipping serial.config addition.${white}"
            SERIAL="disabled"
        fi
    else
        SERIAL="disabled"
    fi

    if [ "$KernelSU" == "enabled" ]; then
        printf "\n${yellow}Do you want to add nethunter.config for nethunter support to the defconfig? (y/n): ${white}"
        read -r add_nethunter
        if [[ $add_nethunter == "y" || $add_nethunter == "Y" ]]; then
            make ARCH=arm64 O=out nethunter.config
            echo -e "${red}nethunter.config added successfully.${white}"
            NETHUNTER="enabled"
        else
            echo -e "${red}Skipping nethunter.config addition.${white}"
            NETHUNTER="disabled"
        fi
    else
        NETHUNTER="disabled"
    fi
    echo -e "\n"
    echo -e "${green}Defconfig setup complete.${white}"
    echo -e "\n"
    echo -e "${yellow}You can now proceed to build the kernel using ./script.sh build${white}"
    cekout_config
}

function cekout_config(){
    if [ ! -d "$TMP_DIR" ]; then
        mkdir -p "$TMP_DIR"
    fi
    cat > "$KERNEL_SUPPORT_CONFIG_FILE" << EOF
{
    "KernelSU": "$KernelSU",
    "SUSFS": "$SUSFS",
    "Serial": "$SERIAL",
    "NETHUNTER": "$NETHUNTER"
}
EOF
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
    
    zip_image
    
    
}

function zip_image(){
    
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
    
    # Read data from $KERNEL_SUPPORT_CONFIG_FILE
    if [ -f "$KERNEL_SUPPORT_CONFIG_FILE" ]; then
        # Extract feature flags from JSON config file
        KERNELSU=$(grep -o '"KernelSU": *"[^"]*"' "$KERNEL_SUPPORT_CONFIG_FILE" | cut -d'"' -f4)
        SUSFS=$(grep -o '"SUSFS": *"[^"]*"' "$KERNEL_SUPPORT_CONFIG_FILE" | cut -d'"' -f4)
        SERIAL=$(grep -o '"Serial": *"[^"]*"' "$KERNEL_SUPPORT_CONFIG_FILE" | cut -d'"' -f4)
        NETHUNTER=$(grep -o '"NETHUNTER": *"[^"]*"' "$KERNEL_SUPPORT_CONFIG_FILE" | cut -d'"' -f4)
        
        # Build feature list - only add enabled features without the status
        FEATURES=""
        [ "$KERNELSU" = "enabled" ] && FEATURES+="  - KernelSU"
        [ "$SUSFS" = "enabled" ] && FEATURES+=" - SUSFS"
        [ "$SERIAL" = "enabled" ] && FEATURES+=" - Serial"
        [ "$NETHUNTER" = "enabled" ] && FEATURES+=" - NetHunter"
        
        # Search for line containing "-*" in banner and replace with feature list
        if grep -q "^  -\*" banner; then
            sed -i 's/^  -\*$/'"$(echo "$FEATURES" | sed 's/[&/\]/\\&/g')"'/' banner
        fi
    fi
    
    ## Set zip name
    zip -r9 "../$ZIPNAME" * -x .git
    cd ..
    rm -rf AnyKernel3
    echo "[thian  Build Script] Completed in $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s) !"
    echo "[thian  Build Script] Zip: $ZIPNAME"
    upload_image
}

function setup() {
    echo -e "${yellow}Installing dependencies...${white}"
    sudo apt-get update
    sudo apt-get install -y zip wget jq gcc g++ \
    gcc-aarch64-linux-gnu gcc-arm-linux-gnueabihf
    echo -e "${green}Dependencies installed successfully.${white}"
    
    echo -e "${green}Installing dependencies2...${white}"
    sudo apt install -y nano bc bison ca-certificates curl flex gcc git libc6-dev \
    libssl-dev openssl python-is-python3 ssh wget zip zstd sudo make clang \
    gcc-arm-linux-gnueabi software-properties-common build-essential \
    libarchive-tools gcc-aarch64-linux-gnu
    echo -e "${green}Dependencies2 installed successfully.${white}"
    
    while true; do
        printf "\n${yellow}Please select clang version to download:\n"
        printf "1. clang-r530567 (19) (recommended)\n"
        printf "2. r498229b (17.0.4)\n${white}"
        echo -e "${yellow}Enter your choice (1/2): ${white}"
        
        read -r clang_version
        
        if [[ $clang_version == "1" ]]; then
            git clone "$URL_CLANG" "$Clang_DIR" --depth 1
            echo -e "${green}Clang clang-r530567 (19) downloaded successfully.${white}"
            break
            elif [[ $clang_version == "2" ]]; then
            git clone "$URL_CLANG2" "$Clang_DIR" --depth 1
            echo -e "${green}Clang r498229b (17.0.4) downloaded successfully.${white}"
            break
        else
            echo -e "${red}Invalid option. Please try again.${white}"
        fi
    done
    echo -e "type ${cyan}All setup completed.${white} "
}

function cek_config(){
    if [ ! -f "${OUT_DIR}/.config" ]; then
        echo -e "${red}Error:${white} No .config file found in out directory."
        echo "Please run '{$red} ./script.sh config' to generate the configuration file.${white}"
        exit 1
    fi
}

function clean_up(){
    echo -e "\n"
    printf "$red are you sure want to clean up? (y/n): $white"
    read CONFIRM
    if [ "$CONFIRM" = "y" ]; then
        echo -e "\n"
        echo -e "$yellow << cleaning up build artifacts >> \n$white"
        echo -e "\n"
        make -C "$OUT_DIR" clean
        echo -e "${green}Clean up completed successfully.${white}"
    else
        echo -e "${yellow}Clean up cancelled.${white}"
    fi
    echo -e "\n"
}

function full_clean_up(){
    echo -e "\n"
    printf "$red are you sure want to full clean up? this will delete the out directory (y/n): $white"
    read CONFIRM
    if [ "$CONFIRM" = "y" ]; then
        echo -e "\n"
        echo -e "$yellow << performing full clean up >> \n$white"
        echo -e "\n"
        rm -rf "$OUT_DIR"
        echo -e "${green}Full clean up completed successfully.${white}"
    else
        echo -e "${yellow}Full clean up cancelled.${white}"
    fi
    echo -e "\n"
    
}

function cek_clang() {
    if [ ! -f "$CLANG_DIR/bin/clang" ]; then
        echo -e "${red}Error:${white} Clang not found at ${CLANG_DIR}."
        echo -e "Please ensure that Clang is properly set up in the specified directory."
        echo -e "You can download and set up Clang in the directory: $CLANG_DIR"
        echo -e "Please extract clang tar.gz to $CLANG_DIR"
        echo -e "Or if you use git clone, please rename the folder to 'myclang' to match the script"
        echo -e "Or move your existing clang folder to $CLANG_DIR"
        echo -e "run this script with setup"
        echo -e "and try again."
        exit 1
    else
        echo -e "${yellow}== Checking Clang Version ==${white}"
        "$CLANG_DIR/bin/clang" --version
    fi
}

function help_menu(){
    echo -e "${cyan}Usage: $0 {setup|build|config|upload|bot|clean|fullclean}${white}"
    echo
    echo -e "${green}Commands:${white}"
    echo  -e "  ${blue}build        Build the kernel${white}"
    echo  -e "  ${blue}config       Make and configure defconfig${white}"
    echo  -e "  ${blue}upload       Upload built images to Telegram${white}"
    echo  -e "  ${blue}bot          Setup Telegram bot configuration${white}"
    echo  -e "  ${blue}clean        Clean up build artifacts${white}"
    echo  -e "  ${blue}fullclean    Perform a full clean up of the out directory${white}"
    echo  -e "  ${blue}setup        Setup build environment and dependencies${white}"
    echo -e "\n"
    echo -e "${red}note : fullclean will delete the out directory${white}"
    echo -e "\n"
    echo -e "${green}note: run '${red}./script setup${yellow}' first to install dependencies and clang before build or cannot build${white}"
    echo -e "${yellow}note: run '${red}./script bot${yellow}' first to setup bot telegram before upload images if not cannot upload${white}"
    echo -e "${yellow}note: run '${red}./script config${yellow}' first to setup kernel config before build or cannot build because no .config found${white}"
}

function upload_image() {
    printf "Are you want to upload the $NAME_ZIP? (y/n): "
    read UP

    [ "$UP" != "y" ] && echo "Upload cancelled." && return

    ZIP_FILE=$(ls "$WORK_DIR"/Thian-Kernel-*.zip 2>/dev/null | head -n 1)
    if [ ! -f "$ZIP_FILE" ]; then
        echo -e "${red}Error:${white} please run build to generate the zip file."
        return
    fi

     # cek bot config
    if [ ! -f "$CONFIG_FILE" ]; then
        echo -e "${red}Error:${white} Bot configuration file not found."
        echo -e "Please run '${red}./script.sh bot${white}' to set up the bot configuration."
        printf "do you want to setup bot now? (y/n): "
        read SETUP_BOT
        if [[ "$SETUP_BOT" = "y" || "$SETUP_BOT" = "y" ]]; then
            makebot_config
        else
            echo -e "${yellow}Upload cancelled.${white}"
        fi
        return
    fi


    TOKEN=$(jq -r '.token' "$CONFIG_FILE")
    CHAT_ID=$(jq -r '.chat_id' "$CONFIG_FILE")

    ZIP_FILE=$(ls "$WORK_DIR"/Thian-Kernel-*.zip 2>/dev/null | head -n 1)
    if [ ! -f "$ZIP_FILE" ]; then
        echo -e "${red}Error:${white} zip file not found."
        return
    fi
    
        echo -e "${yellow}Uploading $ZIP_FILE...${white}"
        curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendDocument" \
            -F chat_id="$CHAT_ID" \
            -F document=@"$ZIP_FILE" > /dev/null
        echo -e "${green}Uploaded $ZIP_FILE successfully.${white}"
}

function read_user(){
    if [ $# -eq 0 ]; then
        echo -e "${red}Error:${white} No arguments provided."
        help_menu
        return
    fi
    case "$1" in
        build)
            cek_config
            cek_clang
            Build
        ;;
        config)
            make_defconfig
        ;;
        setup)
            setup
        ;;
        bot)
            makebot_config
        ;;
        upload)
            upload_image
        ;;
        clean)
            clean_up
        ;;
        fullclean)
            full_clean_up
        ;;
        *)
            echo -e "${red}Error:${white} Invalid argument: $1"
            help_menu
            exit 1
        ;;
    esac
}

# execute
read_user "$@"
