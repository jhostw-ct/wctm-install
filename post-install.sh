#!/usr/bin/env bash
# =============================================================================
#  post-install.sh — Arch Linux Post Install
#  Autor: william | Hardware: Lenovo V15 G2 ALC (Ryzen 5 5500U)
#  Uso: Ya en TTY como usuario normal -> bash ~/post-install.sh
# =============================================================================

set -e

# -----------------------------------------------------------------------------
# COLORES — Tokyo Night
# -----------------------------------------------------------------------------
TN_PURPLE='\033[38;5;141m'
TN_BLUE='\033[38;5;111m'
TN_CYAN='\033[38;5;73m'
TN_GREEN='\033[38;5;120m'
TN_YELLOW='\033[38;5;179m'
TN_RED='\033[38;5;203m'
TN_MAGENTA='\033[38;5;204m'
TN_GRAY='\033[38;5;238m'
TN_WHITE='\033[38;5;255m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

info()  { echo -e " ${TN_CYAN}[*]${NC} $1"; }
ok()    { echo -e " ${TN_GREEN}[+]${NC} $1"; }
warn()  { echo -e " ${TN_YELLOW}[!]${NC} $1"; }
error() { echo -e " ${TN_RED}[x]${NC} $1"; exit 1; }
dim()   { echo -e " ${DIM}${TN_GRAY}$1${NC}"; }

section() {
    clear
    echo -e "${TN_PURPLE}"
    echo "  ╔══════════════════════════════════════════╗"
    printf  "  ║  %-40s  ║\n" "$1"
    echo "  ╚══════════════════════════════════════════╝"
    echo -e "${NC}"
}

confirm() {
    read -rp "$(echo -e " ${TN_YELLOW}[?]${NC} $1 ${DIM}[Y/n]:${NC} ")" ans
    [[ -z "$ans" || "$ans" =~ ^[Yy]$ ]]
}

# -----------------------------------------------------------------------------
# BANNER
# -----------------------------------------------------------------------------
clear
echo -e "${TN_PURPLE}"
echo "  ┌─────────────────────────────────────────────────────┐"
echo "  │                                                     │"
echo "  │   ____           _     ___           _        _ _  │"
echo "  │  |  _ \ ___  ___| |_  |_ _|_ __  ___| |_ __ _| | | │"
echo "  │  | |_) / _ \/ __| __|  | || '_ \/ __| __/ _\` | | | │"
echo "  │  |  __/ (_) \__ \ |_   | || | | \__ \ || (_| | | | │"
echo "  │  |_|   \___/|___/\__| |___|_| |_|___/\__\__,_|_|_| │"
echo "  │                                                     │"
echo "  │         Lenovo V15 G2 ALC  //  Ryzen 5 5500U        │"
echo "  └─────────────────────────────────────────────────────┘"
echo -e "${NC}"
echo -e " ${DIM}${TN_GRAY}  post-install.sh — Ejecutando como: ${TN_WHITE}$USER${NC}"
echo -e " ${DIM}${TN_GRAY}  $(date)${NC}"
echo ""

# -----------------------------------------------------------------------------
# VERIFICACIONES
# -----------------------------------------------------------------------------
if [[ "$EUID" -eq 0 ]]; then
    error "No ejecutes como root. Usa tu usuario normal con sudo disponible."
fi

if ! sudo -v &>/dev/null; then
    error "Tu usuario no tiene sudo. Verifica que estes en el grupo wheel."
fi

ok "Usuario ${TN_WHITE}$USER${NC} verificado"
echo ""
read -rp "$(echo -e " ${TN_YELLOW}[?]${NC} Presiona Enter para comenzar... ")" _

# -----------------------------------------------------------------------------
# FASE 1 — PACMAN.CONF
# -----------------------------------------------------------------------------
section "FASE 1 // Configurando pacman.conf"

info "Aplicando mejoras a /etc/pacman.conf..."

# Color
if grep -q "^Color" /etc/pacman.conf; then
    ok "Color ya estaba activado"
else
    sudo sed -i 's/^#Color/Color/' /etc/pacman.conf
    ok "Color descomentado"
fi

# ILoveCandy — debajo de Color
if grep -q "^ILoveCandy" /etc/pacman.conf; then
    ok "ILoveCandy ya estaba presente"
else
    sudo sed -i '/^Color/a ILoveCandy' /etc/pacman.conf
    ok "ILoveCandy agregado"
fi

# ParallelDownloads = 10
if grep -q "^ParallelDownloads" /etc/pacman.conf; then
    sudo sed -i 's/^ParallelDownloads.*/ParallelDownloads = 10/' /etc/pacman.conf
    ok "ParallelDownloads actualizado a 10"
else
    # Agregarlo debajo de ILoveCandy si existe, si no debajo de Color
    sudo sed -i '/^ILoveCandy/a ParallelDownloads = 10' /etc/pacman.conf
    ok "ParallelDownloads = 10 agregado"
fi

# Multilib — descomentar [multilib] y su Include
if grep -q "^\[multilib\]" /etc/pacman.conf; then
    ok "multilib ya estaba habilitado"
else
    info "Habilitando repositorio multilib..."
    # Descomenta #[multilib] y la linea Include siguiente
    sudo sed -i '/^#\[multilib\]/{
        s/^#//
        n
        s/^#//
    }' /etc/pacman.conf
    ok "multilib habilitado"
fi

echo ""
info "Sincronizando base de datos con nueva configuracion..."
sudo pacman -Sy
ok "pacman.conf configurado y sincronizado"

echo ""
dim "  Resumen de cambios:"
dim "  (+) Color"
dim "  (+) ILoveCandy"
dim "  (+) ParallelDownloads = 10"
dim "  (+) [multilib] habilitado"

sleep 2

# -----------------------------------------------------------------------------
# FASE 2 — ACTUALIZAR SISTEMA
# -----------------------------------------------------------------------------
section "FASE 2 // Actualizando sistema"

info "Ejecutando pacman -Syu..."
echo ""
sudo pacman -Syu --noconfirm
echo ""
ok "Sistema actualizado"

sleep 1

# -----------------------------------------------------------------------------
# FASE 3 — INSTALAR PAQUETES
# -----------------------------------------------------------------------------
section "FASE 3 // Instalando paquetes"

PACKAGES=(
    # Drivers AMD — Ryzen 5 5500U / Radeon Vega 7
    mesa
    lib32-mesa
    vulkan-radeon
    lib32-vulkan-radeon
    xf86-video-amdgpu
    libva-mesa-driver
    lib32-libva-mesa-driver
    mesa-vdpau
    lib32-mesa-vdpau

    # Audio — Pipewire
    pipewire
    pipewire-pulse
    pipewire-alsa
    pipewire-jack
    wireplumber
    pavucontrol
    alsa-utils

    # Sistema y utilidades
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

    # Red
    networkmanager-applet
    nm-connection-editor

    # Desarrollo
    python
    python-pip
    nodejs
    npm

    # Fuentes
    ttf-jetbrains-mono-nerd
    ttf-nerd-fonts-symbols
    noto-fonts
    noto-fonts-emoji

    # Bluetooth
    bluez
    bluez-utils

    # Power management AMD
    power-profiles-daemon
)

# Mostrar agrupados
echo -e " ${TN_CYAN}  Drivers AMD:${NC}"
for p in mesa lib32-mesa vulkan-radeon lib32-vulkan-radeon xf86-video-amdgpu libva-mesa-driver lib32-libva-mesa-driver mesa-vdpau lib32-mesa-vdpau; do
    echo -e "  ${TN_BLUE}(+)${NC} $p"
done

echo ""
echo -e " ${TN_CYAN}  Audio:${NC}"
for p in pipewire pipewire-pulse pipewire-alsa pipewire-jack wireplumber pavucontrol alsa-utils; do
    echo -e "  ${TN_BLUE}(+)${NC} $p"
done

echo ""
echo -e " ${TN_CYAN}  Sistema / utilidades / fuentes / BT / power:${NC}"
for p in htop btop fastfetch tree unzip zip p7zip rsync man-db man-pages less xdg-user-dirs networkmanager-applet nm-connection-editor python python-pip nodejs npm ttf-jetbrains-mono-nerd ttf-nerd-fonts-symbols noto-fonts noto-fonts-emoji bluez bluez-utils power-profiles-daemon; do
    echo -e "  ${TN_BLUE}(+)${NC} $p"
done
echo ""

confirm "Instalar todos estos paquetes?" || error "Cancelado."

echo ""
info "Instalando — puede tardar varios minutos..."
echo ""
sudo pacman -S --noconfirm --needed "${PACKAGES[@]}"
echo ""
ok "Paquetes instalados"

sleep 1

# -----------------------------------------------------------------------------
# FASE 4 — YAY
# -----------------------------------------------------------------------------
section "FASE 4 // Instalando yay (AUR Helper)"

if command -v yay &>/dev/null; then
    ok "yay ya esta instalado"
else
    info "Clonando e instalando yay..."
    echo ""
    cd /tmp
    rm -rf yay
    sudo pacman -S --noconfirm --needed git base-devel
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd ~
    rm -rf /tmp/yay
    echo ""
    ok "yay instalado"
fi

sleep 1

# -----------------------------------------------------------------------------
# FASE 5 — CARPETAS DE USUARIO
# -----------------------------------------------------------------------------
section "FASE 5 // Creando carpetas de usuario"

info "Ejecutando xdg-user-dirs-update..."
xdg-user-dirs-update
ok "Carpetas estandar creadas"
dim "  -> Documents, Downloads, Music, Pictures, Videos, Desktop, Templates, Public"

echo ""
info "Creando carpetas locales..."
mkdir -p "$HOME/.local/share/icons"
mkdir -p "$HOME/.local/share/fonts"
ok "~/.local/share/icons  creada"
ok "~/.local/share/fonts  creada"

info "Actualizando cache de fuentes..."
fc-cache -f "$HOME/.local/share/fonts" 2>/dev/null
ok "Cache de fuentes actualizada"

sleep 1

# -----------------------------------------------------------------------------
# FASE 6 — SERVICIOS DE AUDIO
# -----------------------------------------------------------------------------
section "FASE 6 // Activando audio (Pipewire)"

info "Habilitando servicios de audio para $USER..."
echo ""

systemctl --user enable --now pipewire.service
ok "pipewire"

systemctl --user enable --now pipewire-pulse.service
ok "pipewire-pulse"

systemctl --user enable --now wireplumber.service
ok "wireplumber"

echo ""
info "Estado actual:"
systemctl --user status pipewire --no-pager -l 2>/dev/null | head -5 || true

sleep 1

# -----------------------------------------------------------------------------
# FASE 7 — SERVICIOS DEL SISTEMA
# -----------------------------------------------------------------------------
section "FASE 7 // Servicios del sistema"

info "Habilitando servicios..."
echo ""

sudo systemctl enable bluetooth
ok "bluetooth"

sudo systemctl enable fstrim.timer
ok "fstrim.timer  (SSD TRIM semanal)"

sudo systemctl enable power-profiles-daemon
ok "power-profiles-daemon  (AMD power management)"

sleep 1

# -----------------------------------------------------------------------------
# FASE 8 — PAQUETES EXTRA OPCIONALES
# -----------------------------------------------------------------------------
section "FASE 8 // Paquetes adicionales (opcional)"

echo -e " ${TN_YELLOW}  Paquetes extra desde pacman o AUR${NC}"
echo -e " ${DIM}${TN_GRAY}  Separados por espacio. Enter para saltar.${NC}"
echo ""
read -rp "  > " EXTRA_NOW

if [[ -n "$EXTRA_NOW" ]]; then
    echo ""
    info "Instalando con yay..."
    yay -S --noconfirm --needed $EXTRA_NOW
    ok "Paquetes extra instalados"
else
    dim "  Sin paquetes extra."
fi

sleep 1

# -----------------------------------------------------------------------------
# COMPLETADO
# -----------------------------------------------------------------------------
section "COMPLETADO // Post-install finalizado"

echo -e "${TN_GREEN}"
echo "  .___.  .___.  .___."
echo "  |   |  |   |  |   |"
echo "  |___|  |___|  |___|"
echo "  .___________________."
echo "  |                   |"
echo "  |   TODO LISTO  (^) |"
echo "  |___________________|"
echo -e "${NC}"

echo -e "  ${TN_CYAN}Instalado:${NC}"
echo -e "  ${DIM}${TN_GRAY}  [+] Drivers AMD   — mesa, vulkan-radeon, VA-API${NC}"
echo -e "  ${DIM}${TN_GRAY}  [+] Audio          — pipewire + wireplumber${NC}"
echo -e "  ${DIM}${TN_GRAY}  [+] yay            — AUR helper${NC}"
echo -e "  ${DIM}${TN_GRAY}  [+] Carpetas       — xdg-user-dirs, icons, fonts${NC}"
echo -e "  ${DIM}${TN_GRAY}  [+] Servicios      — bluetooth, fstrim, power-profiles${NC}"
echo -e "  ${DIM}${TN_GRAY}  [+] pacman.conf    — Color, ILoveCandy, ParallelDownloads=10, multilib${NC}"
echo ""
echo -e "  ${TN_YELLOW}Proximos pasos:${NC}"
echo -e "  ${DIM}  ->  ${TN_CYAN}yay -S hyprland${NC}"
echo -e "  ${DIM}  ->  ${TN_CYAN}sudo pacman -S kitty${NC}"
echo -e "  ${DIM}  ->  Relogin para aplicar cambios de shell${NC}"
echo ""

if confirm "Reiniciar ahora?"; then
    info "Reiniciando..."
    sudo reboot
else
    dim "  Reinicia cuando estes listo: sudo reboot"
fi
