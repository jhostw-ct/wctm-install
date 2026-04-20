# arch-install

Scripts de instalación automatizada de Arch Linux.
**Hardware objetivo:** Lenovo V15 G2 ALC — Ryzen 5 5500U / Radeon Vega 7

---

## Estructura

```
arch-install/
├── install.sh        # Instalación base desde el live ISO
└── post-install.sh   # Configuración post-instalación en TTY
```

---

## Uso

### 1. Desde el live ISO de Arch Linux

Arranca el ISO, conéctate a internet si puedes, luego:

```bash
# Con curl
curl -O https://raw.githubusercontent.com/TU_USUARIO/arch-install/main/install.sh
bash install.sh
```

```bash
# O con wget
wget https://raw.githubusercontent.com/TU_USUARIO/arch-install/main/install.sh
bash install.sh
```

El script te preguntará:
- Hostname de la máquina
- Nombre de usuario y contraseñas
- Disco destino (muestra `lsblk` y pide confirmación antes de borrar)
- Paquetes adicionales al base

Al finalizar, reinicia y retira el USB.

---

### 2. Ya en tu sistema (TTY)

Inicia sesión con tu usuario, clona el repo y ejecuta:

```bash
git clone https://github.com/TU_USUARIO/arch-install.git
cd arch-install
bash post-install.sh
```

El script instala:
- **yay** — AUR helper
- **Drivers AMD** — mesa, vulkan-radeon, VA-API
- **Audio** — pipewire + wireplumber (reemplaza PulseAudio)
- **zsh** — shell con configuración básica
- **Utilidades** — btop, fastfetch, nerd fonts, python, node, etc.
- **Servicios** — bluetooth, fstrim (SSD), power-profiles-daemon

---

## Paquetes base instalados por `install.sh`

| Paquete | Descripción |
|---------|-------------|
| `base` | Sistema mínimo |
| `linux` | Kernel estable |
| `linux-lts` | Kernel LTS (respaldo) |
| `linux-firmware` | Firmware hardware |
| `amd-ucode` | Microcode AMD |
| `base-devel` | Herramientas de compilación |
| `sudo` | Privilegios |
| `nano` | Editor de texto |
| `git` | Control de versiones |
| `curl` / `wget` | Descarga desde terminal |

---

## Hardware soportado

| Componente | Estado |
|-----------|--------|
| CPU Ryzen 5 5500U | ✅ amd-ucode |
| GPU Radeon Vega 7 | ✅ mesa + vulkan-radeon |
| Audio Realtek | ✅ pipewire |
| WiFi | ✅ networkmanager |
| Bluetooth | ✅ bluez |
| SSD | ✅ fstrim.timer |

---

## Próximo paso (no incluido en estos scripts)

Una vez en TTY con todo configurado:

```bash
yay -S hyprland
sudo pacman -S kitty waybar wofi
```

---

## Notas

- La instalación usa **UEFI + GPT** (requiere Secure Boot desactivado en BIOS)
- Particionado: `1G EFI (FAT32)` + `resto ROOT (ext4)`
- Zona horaria: `America/Lima`
- Locale: `en_US.UTF-8`
