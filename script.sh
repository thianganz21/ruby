#!/bin/bash
# Copyright cc 2025 thian

# setup color
red='\033[0;31m'
green='\e[0;32m'
white='\033[0m'
yellow='\033[0;33m'
cyan='\033[0;36m'
blue='\033[0;34m'
reset='\e[0m'


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

###
STATE_FILE="${WORK_DIR}/.tmp/menu_state.conf"
CONFIGS="${WORK_DIR}/out/.config"



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
            make ARCH=arm64 O=out vendor/kernelsu.config
            echo -e "${red}kernelsu.config added successfully.${white}"
            KernelSU="enabled"
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
    if [ "$KernelSU" == "disabled" ]; then
        make ARCH=arm64 O=out ruby_defconfig
        echo -e "${red}Thian ruby defconfig set up successfully.${white}"
        if
    fi
    echo -e "\n"
    echo -e "${green}Defconfig setup complete.${white}"
    echo -e "\n"
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
    
   
    if [ -f "$KERNEL_SUPPORT_CONFIG_FILE" ]; then
        
        KERNELSU=$(grep -o '"KernelSU": *"[^"]*"' "$KERNEL_SUPPORT_CONFIG_FILE" | cut -d'"' -f4)
        SUSFS=$(grep -o '"SUSFS": *"[^"]*"' "$KERNEL_SUPPORT_CONFIG_FILE" | cut -d'"' -f4)
        SERIAL=$(grep -o '"Serial": *"[^"]*"' "$KERNEL_SUPPORT_CONFIG_FILE" | cut -d'"' -f4)
        NETHUNTER=$(grep -o '"NETHUNTER": *"[^"]*"' "$KERNEL_SUPPORT_CONFIG_FILE" | cut -d'"' -f4)
        
        
        FEATURES=""
        [ "$KERNELSU" = "enabled" ] && FEATURES+="  - KernelSU"
        [ "$SUSFS" = "enabled" ] && FEATURES+=" - SUSFS"
        [ "$SERIAL" = "enabled" ] && FEATURES+=" - Serial"
        [ "$NETHUNTER" = "enabled" ] && FEATURES+=" - NetHunter"
        
        
        if grep -q "^  -\*" banner; then
            sed -i 's/^  -\*$/'"$(echo "$FEATURES" | sed 's/[&/\]/\\&/g')"'/' banner
        fi
    fi
    
   
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



function upload_image() {
    printf "Are you want to upload the $NAME_ZIP? (y/n): "
    read UP
    
    [ "$UP" != "y" ] && echo "Upload cancelled." && return
    
    ZIP_FILE=$(ls "$WORK_DIR"/Thian-Kernel-*.zip 2>/dev/null | head -n 1)
    if [ ! -f "$ZIP_FILE" ]; then
        echo -e "${red}Error:${white} please run build to generate the zip file."
        return
    fi
    
   
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

function menu(){
    kernel_sup=" "
    SET="default"
    kernel="out/arch/arm64/boot/Image.gz-dtb"
    confix="${WORK_DIR}/out/.config"
    build_name=$NAME_ZIP
    clean_up1=" "
    full_clean_up1=" "
    if [ ! -d "$TMP_DIR" ]; then
        mkdir -p "$TMP_DIR"
    fi
    if [[ ! -f "$STATE_FILE" ]]; then
        echo "env=0" > "$STATE_FILE"
        echo "defconfig=0" >> "$STATE_FILE"
        echo "build=0" >> "$STATE_FILE"
        echo "clean=0" >> "$STATE_FILE"
        echo "fullclean=0" >> "$STATE_FILE"
        echo "bot=0" >> "$STATE_FILE"
    fi
    source "$STATE_FILE"
    mark() { [[ $1 -eq 1 ]] && echo "[${green}✔${white}]" || echo "[❌${white}]"; }
    save_state(){
        cat <<EOF > "$STATE_FILE"
env=$env
defconfig=$defconfig
build=$build
clean=$clean
fullclean=$fullclean
bot=$bot
EOF
    }
    toggle(){
        case $1 in
            env) env=$((1 - env)) ;;
            defconfig) defconfig=$((1 - defconfig)) ;;
            build) build=$((1 - build)) ;;
            clean) clean=$((1 - clean)) ;;
            fullclean) fullclean=$((1 - fullclean)) ;;
            bot) bot=$((1 - bot)) ;;
        esac
        save_state
    }
    while true; do
        if [ ! -f "$CONFIG_FILE" ]; then
            bot=0
            else
            bot=1
        fi
        if [ ! -f "$CLANG_DIR/bin/clang" ]; then
            env=0
            else
            env=1
        fi
        if [ ! -f "$CONFIGS" ]; then
            defconfig=0
            kernel_sup="configuration not set"
            else
            defconfig=1
        fi
        if [ ! -f "$kernel" ]; then
            build=0
            clean=0
            build_name="${red}no build found${white}"
            clean_up1="${red}no build found${white}"
          else
            build=1
            build_name=$NAME_ZIP
            clean=1
            clean_up1=$kernel
        fi
        if [ -f "$KERNEL_SUPPORT_CONFIG_FILE" ]; then
           
            KERNELSU=$(grep -o '"KernelSU": *"[^"]*"' "$KERNEL_SUPPORT_CONFIG_FILE" | cut -d'"' -f4)
            SUSFS=$(grep -o '"SUSFS": *"[^"]*"' "$KERNEL_SUPPORT_CONFIG_FILE" | cut -d'"' -f4)
            Serial=$(grep -o '"Serial": *"[^"]*"' "$KERNEL_SUPPORT_CONFIG_FILE" | cut -d'"' -f4)
            NETHUNTER=$(grep -o '"NETHUNTER": *"[^"]*"' "$KERNEL_SUPPORT_CONFIG_FILE" | cut -d'"' -f4)
            
            kernel_sup="(KernelSU: $KERNELSU, SUSFS: $SUSFS, Serial: $Serial, NETHUNTER: $NETHUNTER)"
         else
            kernel_sup="configuration not set"
        fi
        if [ ! -f "$confix" ]; then
            full_clean_up1="${red}no config found${white}"
            fullclean=0
            else
            full_clean_up1="${green}config found${white}"
            fullclean=1
            
        fi


        clear
        printf "${blue}"
        printf "RRRRRRRRRRRRRRRRR   UUUUUUUU     UUUUUUUUBBBBBBBBBBBBBBBBB   YYYYYYY       YYYYYYY\n"
        printf "R::::::::::::::::R  U::::::U     U::::::UB::::::::::::::::B  Y:::::Y       Y:::::Y\n"
        printf "R::::::RRRRRR:::::R U::::::U     U::::::UB::::::BBBBBB:::::B Y:::::Y       Y:::::Y\n"
        printf "RR:::::R     R:::::RUU:::::U     U:::::UUBB:::::B     B:::::BY::::::Y     Y::::::Y\n"
        printf "  R::::R     R:::::R U:::::U     U:::::U   B::::B     B:::::BYYY:::::Y   Y:::::YYY\n"
        printf "  R::::R     R:::::R U:::::D     D:::::U   B::::B     B:::::B   Y:::::Y Y:::::Y   \n"
        printf "  R::::RRRRRR:::::R  U:::::D     D:::::U   B::::BBBBBB:::::B     Y:::::Y:::::Y    \n"
        printf "  R:::::::::::::RR   U:::::D     D:::::U   B:::::::::::::BB       Y:::::::::Y     \n"
        printf "  R::::RRRRRR:::::R  U:::::D     D:::::U   B::::BBBBBB:::::B       Y:::::::Y      \n"
        printf "  R::::R     R:::::R U:::::D     D:::::U   B::::B     B:::::B       Y:::::Y       \n"
        printf "  R::::R     R:::::R U:::::D     D:::::U   B::::B     B:::::B       Y:::::Y       \n"
        printf "  R::::R     R:::::R U::::::U   U::::::U   B::::B     B:::::B       Y:::::Y       \n"
        printf "RR:::::R     R:::::R U:::::::UUU:::::::U BB:::::BBBBBB::::::B       Y:::::Y       \n"
        printf "R::::::R     R:::::R  UU:::::::::::::UU  B:::::::::::::::::B     YYYY:::::YYYY    \n"
        printf "R::::::R     R:::::R    UU:::::::::UU    B::::::::::::::::B      Y:::::::::::Y    \n"
        printf "RRRRRRRR     RRRRRRR      UUUUUUUUU      BBBBBBBBBBBBBBBBB       YYYYYYYYYYYYY    \n"
        printf "################################################################################\n"
        printf "\t      ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n"
        printf "\t      |         T H I A N   K E R N E L   B U I L D E R |\n"
        printf "\t      ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n"
        printf "${reset}"
        printf "\n"
        echo -e "${yellow}1.${white} Setup Environment              $(mark $env) "
        echo -e "${yellow}2.${white} Configure Defconfig            $(mark $defconfig)  ${kernel_sup}"
        echo -e "${yellow}3.${white} Build Kernel                   $(mark $build)      ${build_name}"
        echo -e "${yellow}4.${white} Clean Build Artifacts          $(mark $clean)      ${clean_up1}"
        echo -e "${yellow}5.${white} Full Clean Build Artifacts     $(mark $fullclean)      ${full_clean_up1}"
        echo -e "${yellow}6.${white} Setup Bot Telegram             $(mark $bot)"
        echo -e "${yellow}7.${white} Upload Kernel Zip to Telegram"
        echo -e "${yellow}0.${white} Exit"


        echo -e "\n${cyan}Notes:${white}"
        echo -e "${cyan}- Make sure to setup environment and defconfig before building the kernel.${white}"
        echo -e "${cyan}- You can clean build artifacts or perform a full clean if needed.${white}"
        echo -e "${cyan}- Setup bot telegram to upload the kernel zip after build.${white}"

        printf "\n${cyan}Select an option (0-7): ${white}"
        read -r choice
        case $choice in
            1)
                toggle env
                if [ ! -f "$CLANG_DIR/bin/clang" ]; then
                    setup
                    set="setup environment complete"
                    env=1
                else
                    printf "${yellow}Clang is already installed. Do you want to reinstall it? (y/n): ${white}"
                    read -r reinstall_clang
                    if [[ $reinstall_clang == "y" || $reinstall_clang == "Y" ]]; then
                        rm -rf "$CLANG_DIR"
                        setup
                        set="reinstall environment complete"
                        env=1
                    else
                        env=1
                    fi
                    
                fi
            ;;
            2)
                if [ ! -f "$CONFIGS" ]; then
                    make_defconfig
                    set="defconfig setup complete"
                    defconfig=1
                else
                    printf "${yellow}Defconfig already exists. Do you want to regenerate it? (y/n): ${white}"
                    read -r regen_defconfig
                    if [[ $regen_defconfig == "y" || $regen_defconfig == "Y" ]]; then
                        rm -f "$CONFIGS"
                        make_defconfig
                        set="defconfig regenerated successfully"
                        defconfig=1
                    else
                        defconfig=1
                    fi
                fi
            ;;
            3)
                if [ ! -f "$CONFIGS" ]; then
                    echo -e "${red}Error:${white} No .config file found. Please configure defconfig first."
                    set="build failed: no defconfig"
                    build=0
                else
                    if [ ! -f "$CLANG_DIR/bin/clang" ]; then
                        echo -e "${red}Error:${white} Clang not found. Please set up the environment first."
                        set="build failed: no clang"
                        build=0
                        else
                        if [ -f "$WORK_DIR"/Thian-Kernel-*.zip ]; then
                            rm -f "$WORK_DIR"/Thian-Kernel-*.zip
                            cek_clang
                            Build
                            set="build complete"
                            build=1
                            else
                            cek_clang
                            Build
                            set="build complete"
                            build=1
                        fi
                        
                    fi
                    
                fi
            ;;
            4)
                if [ ! -f "$kernel" ]; then
                    echo -e "${red}Error:${white} No build found to clean."
                    set="clean failed: no build found"
                    clean=0
                else
                    clean_up
                    set="clean complete"
                    clean=1
                    clean_up1="clean completed"
                fi
            ;;
            5)
                if [ ! -d "$OUT_DIR" ]; then
                    echo -e "${red}Error:${white} No out directory found to full clean."
                    set="full clean failed: no out directory"
                    fullclean=0
                else
                    full_clean_up
                    set="full clean complete"
                    fullclean=1
                    full_clean_up1="full clean completed"
                    rm KERNEL_SUPPORT_CONFIG_FILE
                fi
            ;;
            6)
                if [ ! -f "$CONFIG_FILE" ]; then
                    
                    toggle bot
                    makebot_config
                    set="bot setup complete"
                else
                    bot=1
                    makebot_config
                fi
            ;;
            7)
                echo -e "${yellow}Upload Kernel Zip to Telegram...${white}"
                upload_image
                set="upload complete"
            ;;
            0)
                echo -e "${yellow}Exiting...${white}"
                exit 0
            ;;
            *)
                echo -e "${red}Invalid option. Please try again.${white}"
            ;;
        esac
        printf "\n${cyan}${set}\n\nPress Enter to continue...${white}"
        read -r
    done
    
    
}
menu