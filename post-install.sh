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
TN_GRAY='\033[38;5;238m'
TN_WHITE='\033[38;5;255m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

info()  { echo -e " ${TN_CYAN}[*]${NC} $1"; }
ok()    { echo -e " ${TN_GREEN}[+]${NC} $1"; }
warn()  { echo -e " ${TN_YELLOW}[!]${NC} $1"; }
error() { echo -e " ${TN_RED}[x]${NC} $1"; exit 1; }
dim()   { echo -e " ${DIM}${TN_GRAY}    $1${NC}"; }

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
echo "  ┌──────────────────────────────────────────────────────┐"
echo "  │                                                      │"
echo "  │   ____           _     ___           _        _ _   │"
echo "  │  |  _ \ ___  ___| |_  |_ _|_ __  ___| |_ __ _| | | │"
echo "  │  | |_) / _ \/ __| __|  | || '_ \/ __| __/ _\` | | | │"
echo "  │  |  __/ (_) \__ \ |_   | || | | \__ \ || (_| | | | │"
echo "  │  |_|   \___/|___/\__| |___|_| |_|___/\__\__,_|_|_| │"
echo "  │                                                      │"
echo "  │          Lenovo V15 G2 ALC  //  Ryzen 5 5500U        │"
echo "  └──────────────────────────────────────────────────────┘"
echo -e "${NC}"
echo -e " ${DIM}${TN_GRAY}  post-install.sh — Usuario: ${TN_WHITE}$USER${NC}"
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

# =============================================================================
# FASE 1 — PACMAN.CONF
# =============================================================================
section "FASE 1 // Configurando pacman.conf"

info "Aplicando mejoras a /etc/pacman.conf..."
echo ""

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
    ok "ParallelDownloads -> 10"
else
    sudo sed -i '/^ILoveCandy/a ParallelDownloads = 10' /etc/pacman.conf
    ok "ParallelDownloads = 10 agregado"
fi

# Multilib — descomentar [multilib] y su Include
if grep -q "^\[multilib\]" /etc/pacman.conf; then
    ok "multilib ya estaba habilitado"
else
    info "Habilitando repositorio multilib..."
    sudo sed -i '/^#\[multilib\]/{
        s/^#//
        n
        s/^#//
    }' /etc/pacman.conf
    ok "multilib habilitado"
fi

echo ""
info "Sincronizando base de datos..."
sudo pacman -Sy --noconfirm
echo ""
ok "pacman.conf listo"
echo ""
dim "Color            activado"
dim "ILoveCandy       activado"
dim "ParallelDownloads = 10"
dim "[multilib]       habilitado"

sleep 2

# =============================================================================
# FASE 2 — ACTUALIZAR SISTEMA
# =============================================================================
section "FASE 2 // Actualizando sistema"

info "Ejecutando pacman -Syu..."
echo ""
sudo pacman -Syu --noconfirm
echo ""
ok "Sistema actualizado"

sleep 1

# =============================================================================
# FASE 3 — INSTALAR PAQUETES
# =============================================================================
section "FASE 3 // Instalando paquetes"

# ── Drivers AMD ──────────────────────────────────────────────────────────────
AMD_PKGS=(
    mesa
    lib32-mesa
    vulkan-radeon
    lib32-vulkan-radeon
    libva-mesa-driver
    lib32-libva-mesa-driver
)

# ── Audio — Pipewire ──────────────────────────────────────────────────────────
AUDIO_PKGS=(
    pipewire
    pipewire-pulse
    pipewire-alsa
    pipewire-jack
    wireplumber
    pavucontrol
    alsa-utils
)

# ── Sistema y utilidades ──────────────────────────────────────────────────────
SYSTEM_PKGS=(
    btop
    fastfetch
    unzip
    zip
    rsync
    man-db
    man-pages
    xdg-user-dirs
)

# ── Fuentes ───────────────────────────────────────────────────────────────────
FONT_PKGS=(
    ttf-jetbrains-mono-nerd
    ttf-nerd-fonts-symbols
    noto-fonts
    noto-fonts-emoji
)

# ── Power ─────────────────────────────────────────────────────────────────────
POWER_PKGS=(
    power-profiles-daemon
)

# Mostrar lo que se va a instalar
echo -e " ${TN_CYAN}  Drivers AMD:${NC}"
for p in "${AMD_PKGS[@]}";    do echo -e "  ${TN_BLUE}(+)${NC} $p"; done

echo ""
echo -e " ${TN_CYAN}  Audio:${NC}"
for p in "${AUDIO_PKGS[@]}";  do echo -e "  ${TN_BLUE}(+)${NC} $p"; done

echo ""
echo -e " ${TN_CYAN}  Sistema y utilidades:${NC}"
for p in "${SYSTEM_PKGS[@]}"; do echo -e "  ${TN_BLUE}(+)${NC} $p"; done

echo ""
echo -e " ${TN_CYAN}  Fuentes:${NC}"
for p in "${FONT_PKGS[@]}";   do echo -e "  ${TN_BLUE}(+)${NC} $p"; done

echo ""
echo -e " ${TN_CYAN}  Power management:${NC}"
for p in "${POWER_PKGS[@]}";  do echo -e "  ${TN_BLUE}(+)${NC} $p"; done

echo ""
confirm "Instalar todos estos paquetes?" || error "Cancelado."

ALL_PKGS=(
    "${AMD_PKGS[@]}"
    "${AUDIO_PKGS[@]}"
    "${SYSTEM_PKGS[@]}"
    "${FONT_PKGS[@]}"
    "${POWER_PKGS[@]}"
)

echo ""
info "Instalando — puede tardar varios minutos..."
echo ""
sudo pacman -S --noconfirm --needed "${ALL_PKGS[@]}"
echo ""
ok "Paquetes instalados"

sleep 1

# =============================================================================
# FASE 4 — YAY
# =============================================================================
section "FASE 4 // Instalando yay (AUR Helper)"

if command -v yay &>/dev/null; then
    ok "yay ya esta instalado"
else
    info "Instalando dependencias..."
    sudo pacman -S --noconfirm --needed git base-devel
    echo ""
    info "Clonando yay desde AUR..."
    cd /tmp
    rm -rf yay
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd ~
    rm -rf /tmp/yay
    echo ""
    ok "yay instalado"
fi

sleep 1

# =============================================================================
# FASE 5 — CARPETAS DE USUARIO
# =============================================================================
section "FASE 5 // Creando carpetas de usuario"

info "Ejecutando xdg-user-dirs-update..."
xdg-user-dirs-update
ok "Carpetas estandar creadas"
dim "Documents  Downloads  Music  Pictures  Videos  Desktop"

echo ""
info "Creando carpetas locales..."
mkdir -p "$HOME/.local/share/icons"
mkdir -p "$HOME/.local/share/fonts"
ok "~/.local/share/icons  creada"
ok "~/.local/share/fonts  creada"

echo ""
info "Actualizando cache de fuentes..."
fc-cache -f "$HOME/.local/share/fonts" 2>/dev/null
ok "Cache de fuentes actualizada"

sleep 1

# =============================================================================
# FASE 6 — SERVICIOS DE AUDIO
# =============================================================================
section "FASE 6 // Activando audio (Pipewire)"

info "Habilitando servicios para $USER..."
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

# =============================================================================
# FASE 7 — SERVICIOS DEL SISTEMA
# =============================================================================
section "FASE 7 // Servicios del sistema"

info "Habilitando servicios..."
echo ""

sudo systemctl enable --now power-profiles-daemon
ok "power-profiles-daemon  (AMD power management)"

sudo systemctl enable fstrim.timer
ok "fstrim.timer  (SSD TRIM semanal)"

sleep 1

# =============================================================================
# FASE 8 — PAQUETES EXTRA PACMAN
# =============================================================================
section "FASE 8 // Paquetes extra — pacman (repositorios oficiales)"

echo -e " ${TN_YELLOW}  Paquetes oficiales a instalar${NC}"
echo -e " ${DIM}${TN_GRAY}  Separados por espacio. Enter para saltar.${NC}"
echo ""
read -rp "  > " EXTRA_PACMAN

if [[ -n "$EXTRA_PACMAN" ]]; then
    echo ""
    info "Instalando con pacman..."
    # shellcheck disable=SC2086
    sudo pacman -S --noconfirm --needed $EXTRA_PACMAN
    ok "Paquetes pacman instalados"
else
    dim "Sin paquetes extra de pacman."
fi

sleep 1

# =============================================================================
# FASE 9 — PAQUETES EXTRA YAY (AUR)
# =============================================================================
section "FASE 9 // Paquetes extra — yay (AUR)"

echo -e " ${TN_YELLOW}  Paquetes AUR a instalar${NC}"
echo -e " ${DIM}${TN_GRAY}  Separados por espacio. Enter para saltar.${NC}"
echo ""
read -rp "  > " EXTRA_YAY

if [[ -n "$EXTRA_YAY" ]]; then
    echo ""
    info "Instalando con yay..."
    # shellcheck disable=SC2086
    yay -S --noconfirm --needed $EXTRA_YAY
    ok "Paquetes AUR instalados"
else
    dim "Sin paquetes extra de AUR."
fi

sleep 1
# =============================================================================
# FASE 10 — SERVICIOS
# =============================================================================
section "FASE 10 // Servicios"

# Mostrar servicios ya activados por el script
echo -e " ${TN_CYAN}  Servicios activados automaticamente:${NC}"
echo ""
ok "pipewire  /  pipewire-pulse  /  wireplumber"
ok "power-profiles-daemon"
ok "fstrim.timer"
echo ""

SERVICES_ENABLED=()

# Preguntar si quiere activar algo adicional
if confirm "Quieres activar algun servicio adicional?"; then
    echo ""
    echo -e " ${DIM}${TN_GRAY}  Solo escribe el nombre — ejecuta: sudo systemctl enable <nombre>${NC}"
    echo -e " ${DIM}${TN_GRAY}  Ejemplo: sddm  /  bluetooth  /  cups  /  docker${NC}"
    echo ""

    while true; do
        read -rp "$(echo -e "  ${TN_BLUE}servicio>${NC} ")" SVC
        echo ""

        # Intentar activar
        if sudo systemctl enable --now "$SVC" 2>/dev/null; then
            ok "$SVC activado"
            SERVICES_ENABLED+=("$SVC")
        else
            warn "No se pudo activar '$SVC' — puede que no este instalado."
            echo ""
            echo -e "  ${TN_BLUE}[1]${NC} Intentar con otro nombre"
            echo -e "  ${TN_BLUE}[2]${NC} Omitir y continuar"
            echo ""
            read -rp "$(echo -e "  ${TN_YELLOW}[?]${NC} Elige [1/2]: ")" RETRY
            echo ""
            if [[ "$RETRY" == "1" ]]; then
                continue
            else
                dim "Omitido."
                echo ""
            fi
        fi

        # Preguntar si quiere activar otro
        confirm "Activar otro servicio?" || break
        echo ""
    done
fi

sleep 1

# =============================================================================
# COMPLETADO
# =============================================================================
section "COMPLETADO // Post-install finalizado"

echo -e "${TN_GREEN}"
echo "  +---------------------------------------+"
echo "  |                                       |"
echo "  |   /\  /\                              |"
echo "  |  /  \/  \  TODO LISTO                 |"
echo "  | /  arch  \  Lenovo V15 ready          |"
echo "  |/__________\                           |"
echo "  |                                       |"
echo "  +---------------------------------------+"
echo -e "${NC}"

echo -e " ${TN_CYAN}  Resumen:${NC}"
echo ""
dim "[+] pacman.conf    Color / ILoveCandy / ParallelDownloads=10 / multilib"
dim "[+] Drivers AMD    mesa, vulkan-radeon, libva"
dim "[+] Audio          pipewire + wireplumber (activo)"
dim "[+] yay            AUR helper listo"
dim "[+] Carpetas       xdg-user-dirs / .local/share/icons / fonts"
dim "[+] Servicios      power-profiles-daemon / fstrim.timer"

# Mostrar servicios manuales si se activaron
if [[ ${#SERVICES_ENABLED[@]} -gt 0 ]]; then
    SVCLIST=$(IFS=' / '; echo "${SERVICES_ENABLED[*]}")
    dim "[+] Servicios manuales  $SVCLIST"
fi
echo ""
echo -e " ${DIM}${TN_GRAY}  \"Un gran poder conlleva una gran responsabilidad.\"${NC}"
echo ""

read -rp "$(echo -e " ${TN_YELLOW}[?]${NC} Presiona Enter para reiniciar... ")" _
sudo reboot