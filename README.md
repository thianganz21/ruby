# ⚡ Thian Kernel
### Redmi Note 12 Pro 5G — *ruby*  
Custom kernel based on Moonwake Kernel with optional modules, and extended configurability.

---

## 🏗 Base Source
Kernel ini dikembangkan menggunakan base source dari:

> 🔗 https://github.com/RainyXeon/moonwake_kernel_xiaomi_ruby  
🔥 *Huge thanks to RainyXeon for the original work and foundation.*

---

## 🔥 Highlight Features
- Based on Moonwake Kernel (Ruby)
- Tuned for stability
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

run ./script.sh
