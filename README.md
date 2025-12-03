# ⚡ Thian Kernel
### Redmi Note 12 Pro 5G — *ruby*  
Custom kernel based on Moonwake Kernel with performance improvements, optional modules, and extended configurability.

---

## 🏗 Base Source
Kernel ini dikembangkan menggunakan base source dari:

> 🔗 https://github.com/RainyXeon/moonwake_kernel_xiaomi_ruby  
🔥 *Huge thanks to RainyXeon for the original work and foundation.*

---

## 🔥 Highlight Features
- Based on Moonwake Kernel (Ruby)
- Tuned for stability, gaming, and smooth performance
- Optional enhancement configs:
  - KernelSU support (optional install)
  - SUSFS mount & overlay
  - Serial config for Arduino / ESP32 developer
  - Kali NetHunter kernel flags
- Default performance configs enabled:
  ✓ **LZ4KD**  
  ✓ **BBR TCP Congestion Control**  
  ✓ **NOOP I/O Scheduler**  
  ✓ **LRU Memory Control**

---

## 📌 Device Information
| Info | Specs |
|---|---|
| Device | Redmi Note 12 Pro 5G |
| Codename | `ruby` |
| Base Kernel | Moonwake by RainyXeon |
| SoC | MediaTek Dimensity 1080 |
| Status | Development & Experimental |

---

## 🛠 Build Instructions
```bash
# 1. Clone source
git clone https://github.com/yourrepo/thian-ruby-kernel.git --depth=1
cd thian-ruby-kernel

# 2. Usage Script
Usage: ./script {setup|build|config|upload|bot|clean|fullclean}

Commands:
  build        Build the kernel
  config       Make and configure defconfig
  upload       Upload built images to Telegram
  bot          Setup Telegram bot configuration
  clean        Clean up build artifacts
  fullclean    Perform a full clean up of the out directory
  setup        Setup build environment and dependencies

Notes:
  fullclean will delete the out directory
  run './script setup' first to install dependencies & clang before build
  run './script bot'   first to setup telegram bot before upload
  run './script config' first to setup kernel config before build

# 3. Build kernel
./script.sh setup
./script.sh config
./script.sh build

# 4. Upload (Optional)
./script.sh bot
./script.sh upload
