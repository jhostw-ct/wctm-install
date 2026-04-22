#!/usr/bin/env bash
# =============================================================================
#  post-install.sh — Arch Linux Post Install
#  Autor: william | Hardware: Lenovo V15 G2 ALC (Ryzen 5 5500U)
#  Uso: Ya en sesion grafica o TTY como usuario normal -> bash ~/post-install.sh
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
echo "  │  |  _ \ ___  ___| |_  |_ _|_ __  ___| |_      | | | │"
echo "  │  | |_) / _ \/ __| __|  | || '_ \/ __| __|     | | | │"
echo "  │  |  __/ (_) \__ \ |_   | || | | \__ \ |_      |_|_| │"
echo "  │  |_|   \___/|___/\__| |___|_| |_|___/\__|     (_|_) │"
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

if grep -q "^Color" /etc/pacman.conf; then
    ok "Color ya estaba activado"
else
    sudo sed -i 's/^#Color/Color/' /etc/pacman.conf
    ok "Color activado"
fi

if grep -q "^ILoveCandy" /etc/pacman.conf; then
    ok "ILoveCandy ya estaba presente"
else
    sudo sed -i '/^Color/a ILoveCandy' /etc/pacman.conf
    ok "ILoveCandy agregado"
fi

if grep -q "^ParallelDownloads" /etc/pacman.conf; then
    sudo sed -i 's/^ParallelDownloads.*/ParallelDownloads = 10/' /etc/pacman.conf
    ok "ParallelDownloads -> 10"
else
    sudo sed -i '/^ILoveCandy/a ParallelDownloads = 10' /etc/pacman.conf
    ok "ParallelDownloads = 10 agregado"
fi

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
dim "Color / ILoveCandy / ParallelDownloads=10 / multilib"

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
# FASE 3 — YAY
# =============================================================================
section "FASE 3 // Instalando yay (AUR Helper)"

if command -v yay &>/dev/null; then
    ok "yay ya esta instalado"
else
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
# FASE 4 — PAQUETES DE SISTEMA
# =============================================================================
section "FASE 4 // Paquetes de sistema"

SYSTEM_PKGS=(
    btop
    unzip
    zip
    rsync
    man-db
    man-pages
)

echo -e " ${TN_CYAN}  Paquetes:${NC}"
echo ""
for p in "${SYSTEM_PKGS[@]}"; do
    echo -e "  ${TN_BLUE}(+)${NC} $p"
done
echo ""

info "Instalando..."
sudo pacman -S --noconfirm --needed "${SYSTEM_PKGS[@]}"
echo ""
ok "Paquetes de sistema instalados"

sleep 1

# =============================================================================
# FASE 5 — FUENTES
# =============================================================================
section "FASE 5 // Fuentes"

FONT_PKGS=(
    ttf-jetbrains-mono-nerd
    ttf-iosevka-nerd
    ttf-firacode-nerd
    ttf-nerd-fonts-symbols
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
)

echo -e " ${TN_CYAN}  Fuentes:${NC}"
echo ""
for p in "${FONT_PKGS[@]}"; do
    echo -e "  ${TN_BLUE}(+)${NC} $p"
done
echo ""

info "Instalando..."
sudo pacman -S --noconfirm --needed "${FONT_PKGS[@]}"
echo ""
ok "Fuentes instaladas"

sleep 1

# =============================================================================
# FASE 6 — CARPETAS DE USUARIO
# =============================================================================
section "FASE 6 // Carpetas de usuario"

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
# FASE 7 — PAQUETES EXTRA PACMAN
# =============================================================================
section "FASE 7 // Paquetes extra — pacman"

echo -e " ${TN_YELLOW}  Paquetes oficiales adicionales${NC}"
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
# FASE 8 — PAQUETES EXTRA AUR
# =============================================================================
section "FASE 8 // Paquetes extra — AUR (yay)"

echo -e " ${TN_YELLOW}  Paquetes AUR adicionales${NC}"
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
# FASE 9 — SERVICIOS
# =============================================================================
section "FASE 9 // Activando servicios"

info "Activando servicios de audio (usuario)..."
echo ""

systemctl --user enable --now pipewire.service
ok "pipewire"

systemctl --user enable --now pipewire-pulse.service
ok "pipewire-pulse"

systemctl --user enable --now wireplumber.service
ok "wireplumber"

echo ""
info "Estado pipewire:"
systemctl --user status pipewire --no-pager -l 2>/dev/null | head -4 || true

sleep 1

# =============================================================================
# COMPLETADO
# =============================================================================
section "COMPLETADO // Post-install finalizado"

echo -e "${TN_GREEN}"
echo "  ▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄"
echo "  █          __                           █"
echo "  █         /  \         TODO LISTO       █"
echo "  █        / /\ \        Lenovo V15       █"
echo "  █       / /__\ \       Ready            █"
echo "  █      /_/    \_\                       █"
echo "  █▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄"
echo -e "${NC}"


echo -e " ${TN_CYAN}  Resumen:${NC}"
echo ""
dim "[+] pacman.conf     Color / ILoveCandy / ParallelDownloads=10 / multilib"
dim "[+] Sistema         btop, unzip, zip, rsync, man-db"
dim "[+] Fuentes         JetBrainsMono Nerd / Nerd Symbols / Noto / Noto Emoji"
dim "[+] yay             AUR helper listo"
dim "[+] Carpetas        xdg-user-dirs / .local/share/icons / fonts"
dim "[+] Audio           pipewire + wireplumber (activo)"
echo ""
echo -e " ${DIM}${TN_GRAY}  \"Un gran poder conlleva una gran responsabilidad.\"${NC}"
echo ""

read -rp "$(echo -e " ${TN_YELLOW}[?]${NC} Presiona Enter para reiniciar... ")" _
sudo reboot