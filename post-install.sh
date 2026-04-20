#!/usr/bin/env bash
# =============================================================================
#  post-install.sh — Arch Linux Post Install
#  Autor: william | Hardware: Lenovo V15 G2 ALC (Ryzen 5 5500U)
#  Uso: Ya en TTY como usuario normal → bash post-install.sh
# =============================================================================

set -e

# -----------------------------------------------------------------------------
# COLORES
# -----------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info()    { echo -e "${CYAN}[INFO]${NC} $1"; }
ok()      { echo -e "${GREEN}[OK]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }
section() {
    echo -e "\n${BOLD}${BLUE}══════════════════════════════════════${NC}"
    echo -e "${BOLD}${BLUE}  $1${NC}"
    echo -e "${BOLD}${BLUE}══════════════════════════════════════${NC}\n"
}

confirm() {
    read -rp "$(echo -e "${YELLOW}$1 [Y/n]: ${NC}")" ans
    [[ -z "$ans" || "$ans" =~ ^[Yy]$ ]]
}

# -----------------------------------------------------------------------------
# VERIFICACIÓN: no ejecutar como root
# -----------------------------------------------------------------------------
if [[ "$EUID" -eq 0 ]]; then
    error "Ejecuta este script como tu usuario normal, no como root."
fi

if ! sudo -v &>/dev/null; then
    error "Tu usuario no tiene sudo. Asegúrate de estar en el grupo wheel."
fi

section "Post-install — Lenovo V15 G2 ALC"
echo -e "  Usuario: ${CYAN}$USER${NC}"
echo -e "  Inicio:  $(date)\n"

# -----------------------------------------------------------------------------
# FASE 1 — ACTUALIZAR SISTEMA
# -----------------------------------------------------------------------------
section "FASE 1 — Actualizar sistema"

info "Actualizando sistema..."
sudo pacman -Syu --noconfirm
ok "Sistema actualizado ✓"

# -----------------------------------------------------------------------------
# FASE 2 — HABILITAR MULTILIB
# -----------------------------------------------------------------------------
section "FASE 2 — Repositorio multilib (32-bit)"

if grep -q "^\[multilib\]" /etc/pacman.conf; then
    ok "multilib ya está habilitado ✓"
else
    info "Habilitando multilib en /etc/pacman.conf..."
    sudo sed -i '/^#\[multilib\]/{s/^#//;n;s/^#//}' /etc/pacman.conf
    sudo pacman -Sy
    ok "multilib habilitado ✓"
fi

# -----------------------------------------------------------------------------
# FASE 3 — INSTALAR PAQUETES
# -----------------------------------------------------------------------------
section "FASE 3 — Instalando paquetes"

PACKAGES=(
    # ── Drivers AMD (Ryzen 5 5500U / Radeon Vega 7) ──
    mesa
    lib32-mesa
    vulkan-radeon
    lib32-vulkan-radeon
    xf86-video-amdgpu
    libva-mesa-driver
    lib32-libva-mesa-driver
    mesa-vdpau
    lib32-mesa-vdpau

    # ── Audio (Pipewire) ──
    pipewire
    pipewire-pulse
    pipewire-alsa
    pipewire-jack
    wireplumber
    pavucontrol
    alsa-utils

    # ── Sistema / utilidades ──
    htop
    btop
    fastfetch
    tree
    unzip
    zip
    p7zip
    rsync
    man-db
    man-pages
    less
    xdg-user-dirs

    # ── Red ──
    networkmanager-applet
    nm-connection-editor
    wget
    curl

    # ── Desarrollo ──
    python
    python-pip
    nodejs
    npm

    # ── Fuentes ──
    ttf-jetbrains-mono-nerd
    ttf-nerd-fonts-symbols
    noto-fonts
    noto-fonts-emoji

    # ── Bluetooth ──
    bluez
    bluez-utils

    # ── Power management AMD ──
    power-profiles-daemon
)

# Filtrar comentarios
CLEAN_PACKAGES=()
for pkg in "${PACKAGES[@]}"; do
    [[ "$pkg" == \#* ]] && continue
    CLEAN_PACKAGES+=("$pkg")
done

echo -e "${CYAN}Paquetes a instalar:${NC}\n"
for pkg in "${CLEAN_PACKAGES[@]}"; do
    echo -e "  ${GREEN}✓${NC} $pkg"
done
echo ""

confirm "¿Instalar todos estos paquetes?" || error "Cancelado."

info "Instalando paquetes (puede tardar varios minutos)..."
sudo pacman -S --noconfirm --needed "${CLEAN_PACKAGES[@]}"
ok "Paquetes instalados ✓"

# -----------------------------------------------------------------------------
# FASE 4 — YAY (AUR Helper)
# -----------------------------------------------------------------------------
section "FASE 4 — Instalar yay (AUR Helper)"

if command -v yay &>/dev/null; then
    ok "yay ya está instalado ✓"
else
    info "Instalando dependencias..."
    sudo pacman -S --noconfirm --needed git base-devel

    info "Clonando e instalando yay..."
    cd /tmp
    rm -rf yay
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd ~
    rm -rf /tmp/yay
    ok "yay instalado ✓"
fi

# -----------------------------------------------------------------------------
# FASE 5 — CARPETAS DE USUARIO (xdg-user-dirs)
# -----------------------------------------------------------------------------
section "FASE 5 — Creando carpetas de usuario"

info "Ejecutando xdg-user-dirs-update..."
xdg-user-dirs-update
ok "Carpetas estándar creadas (Documentos, Descargas, etc.) ✓"

info "Creando carpetas locales..."
mkdir -p "$HOME/.local/share/icons"
mkdir -p "$HOME/.local/share/fonts"
ok "~/.local/share/icons  creada ✓"
ok "~/.local/share/fonts  creada ✓"

# Actualizar caché de fuentes
fc-cache -f "$HOME/.local/share/fonts" 2>/dev/null && ok "Caché de fuentes actualizada ✓" || true

# -----------------------------------------------------------------------------
# FASE 6 — SERVICIOS DE AUDIO
# -----------------------------------------------------------------------------
section "FASE 6 — Activando servicios de audio"

info "Habilitando pipewire para el usuario $USER..."
systemctl --user enable --now pipewire.service
ok "pipewire ✓"

systemctl --user enable --now pipewire-pulse.service
ok "pipewire-pulse ✓"

systemctl --user enable --now wireplumber.service
ok "wireplumber ✓"

echo ""
info "Estado de audio:"
systemctl --user status pipewire --no-pager -l | head -6 || true

# -----------------------------------------------------------------------------
# FASE 7 — SERVICIOS DEL SISTEMA
# -----------------------------------------------------------------------------
section "FASE 7 — Servicios del sistema"

info "Habilitando servicios..."

sudo systemctl enable bluetooth
ok "bluetooth ✓"

sudo systemctl enable fstrim.timer
ok "fstrim.timer (SSD TRIM semanal) ✓"

sudo systemctl enable power-profiles-daemon
ok "power-profiles-daemon (AMD power mgmt) ✓"

# -----------------------------------------------------------------------------
# FASE 8 — PAQUETES EXTRA (AUR u opcionales)
# -----------------------------------------------------------------------------
section "FASE 8 — Paquetes adicionales (opcional)"

echo -e "${YELLOW}¿Quieres instalar paquetes extra ahora?${NC}"
echo -e "${CYAN}(pacman o AUR — separados por espacio, Enter para saltar)${NC}"
read -rp "  > " EXTRA_NOW

if [[ -n "$EXTRA_NOW" ]]; then
    info "Instalando con yay (soporta pacman + AUR)..."
    yay -S --noconfirm --needed $EXTRA_NOW
    ok "Paquetes extra instalados ✓"
else
    info "Sin paquetes extra."
fi

# -----------------------------------------------------------------------------
# RESUMEN FINAL
# -----------------------------------------------------------------------------
section "✅ POST-INSTALL COMPLETADO"

echo -e "  ${GREEN}Todo listo.${NC}\n"
echo -e "  ${CYAN}Instalado:${NC}"
echo -e "    ✓ Drivers AMD (mesa, vulkan-radeon, VA-API)"
echo -e "    ✓ Audio    — pipewire + wireplumber"
echo -e "    ✓ yay      — AUR helper"
echo -e "    ✓ Carpetas — xdg-user-dirs + icons + fonts"
echo -e "    ✓ Servicios — bluetooth, fstrim, power-profiles"
echo ""
echo -e "  ${YELLOW}Próximos pasos:${NC}"
echo -e "    → Hyprland:  ${CYAN}yay -S hyprland${NC}"
echo -e "    → kitty:     ${CYAN}sudo pacman -S kitty${NC}"
echo -e "    → Relogin para aplicar todo: ${CYAN}exit${NC} y vuelve a entrar"
echo ""

if confirm "¿Reiniciar ahora?"; then
    sudo reboot
else
    info "Reinicia cuando estés listo: sudo reboot"
fi
