#!/usr/bin/env bash
# =============================================================================
#  post-install.sh — Arch Linux Post Install
#  Autor: william | Hardware: Lenovo V15 G2 ALC (Ryzen 5 5500U)
#  Uso: Después de instalar la base y reiniciar en TTY
#       Ejecutar como usuario normal (NO como root): bash post-install.sh
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
section() { echo -e "\n${BOLD}${BLUE}══════════════════════════════════════${NC}"; \
            echo -e "${BOLD}${BLUE}  $1${NC}"; \
            echo -e "${BOLD}${BLUE}══════════════════════════════════════${NC}\n"; }

confirm() {
    read -rp "$(echo -e "${YELLOW}$1 [s/N]: ${NC}")" ans
    [[ "$ans" =~ ^[sS]$ ]]
}

# -----------------------------------------------------------------------------
# VERIFICACIONES INICIALES
# -----------------------------------------------------------------------------
section "Verificaciones previas"

# No ejecutar como root
if [[ "$EUID" -eq 0 ]]; then
    error "No ejecutes este script como root. Úsalo como tu usuario normal con sudo disponible."
fi

# Verificar sudo
if ! sudo -v &>/dev/null; then
    error "Tu usuario no tiene sudo. Asegúrate de estar en el grupo wheel."
fi
ok "Usuario con sudo ✓"

# Verificar conexión
if ! ping -c 1 -W 3 archlinux.org &>/dev/null; then
    warn "Sin conexión a Internet."
    info "Si usas WiFi, conéctate primero con: nmcli device wifi connect \"TuRed\" password \"TuPass\""
    error "Conéctate a Internet y vuelve a ejecutar el script."
fi
ok "Conexión a Internet ✓"

# -----------------------------------------------------------------------------
# FASE 1 — ACTUALIZAR SISTEMA
# -----------------------------------------------------------------------------
section "FASE 1 — Actualizar sistema"

info "Actualizando base de datos de paquetes y sistema..."
sudo pacman -Syu --noconfirm
ok "Sistema actualizado ✓"

# -----------------------------------------------------------------------------
# FASE 2 — YAY (AUR Helper)
# -----------------------------------------------------------------------------
section "FASE 2 — Instalar yay (AUR Helper)"

if command -v yay &>/dev/null; then
    ok "yay ya está instalado ✓"
else
    info "Instalando dependencias para yay..."
    sudo pacman -S --noconfirm --needed git base-devel

    info "Clonando yay-bin desde AUR..."
    cd /tmp
    rm -rf yay-bin
    git clone https://aur.archlinux.org/yay-bin.git
    cd yay-bin
    makepkg -si --noconfirm
    cd ~
    rm -rf /tmp/yay-bin
    ok "yay instalado ✓"
fi

# Actualizar base de datos AUR
yay -Syu --noconfirm
ok "AUR actualizado ✓"

# -----------------------------------------------------------------------------
# FASE 3 — DRIVERS AMD / LENOVO V15 G2 ALC
# -----------------------------------------------------------------------------
section "FASE 3 — Drivers AMD (Ryzen 5 5500U / Radeon)"

AMD_PACKAGES=(
    mesa                    # OpenGL open-source
    lib32-mesa              # Mesa 32-bit (Steam, Wine, etc.)
    vulkan-radeon           # Vulkan para AMD (RADV)
    lib32-vulkan-radeon     # Vulkan 32-bit
    xf86-video-amdgpu       # Driver Xorg AMD (útil aunque uses Wayland)
    libva-mesa-driver       # VA-API hardware video decode AMD
    lib32-libva-mesa-driver # VA-API 32-bit
    mesa-vdpau              # VDPAU AMD
    lib32-mesa-vdpau        # VDPAU 32-bit
)

info "Instalando drivers AMD..."
sudo pacman -S --noconfirm --needed "${AMD_PACKAGES[@]}"
ok "Drivers AMD instalados ✓"

# Multilib (necesario para lib32-*)
info "Verificando multilib en pacman.conf..."
if grep -q "^\[multilib\]" /etc/pacman.conf; then
    ok "multilib ya habilitado ✓"
else
    info "Habilitando repositorio multilib..."
    sudo sed -i '/^#\[multilib\]/,/^#Include/ s/^#//' /etc/pacman.conf
    sudo pacman -Sy
    ok "multilib habilitado ✓"
fi

# -----------------------------------------------------------------------------
# FASE 4 — AUDIO (Pipewire)
# -----------------------------------------------------------------------------
section "FASE 4 — Audio con Pipewire"

AUDIO_PACKAGES=(
    pipewire
    pipewire-pulse          # Reemplaza PulseAudio
    pipewire-alsa           # Soporte ALSA
    pipewire-jack           # Soporte JACK (opcional pero útil)
    wireplumber             # Session manager para Pipewire
    pavucontrol             # GUI control de volumen (útil en TTY también via futuro WM)
    alsa-utils              # amixer, alsamixer en TTY
)

info "Instalando Pipewire y utilidades de audio..."
sudo pacman -S --noconfirm --needed "${AUDIO_PACKAGES[@]}"

# Habilitar servicios para el usuario actual
info "Habilitando servicios de audio para $USER..."
systemctl --user enable --now pipewire.service
systemctl --user enable --now pipewire-pulse.service
systemctl --user enable --now wireplumber.service

ok "Pipewire configurado y habilitado ✓"

# Verificar
info "Estado de audio:"
systemctl --user status pipewire --no-pager -l | head -5 || true

# -----------------------------------------------------------------------------
# FASE 5 — HERRAMIENTAS BASE / UTILIDADES
# -----------------------------------------------------------------------------
section "FASE 5 — Herramientas y utilidades"

TOOLS_PACKAGES=(
    # Sistema
    htop                    # Monitor de procesos
    btop                    # Monitor moderno (recomendado)
    fastfetch               # System info bonito
    tree                    # Ver árbol de directorios
    unzip                   # Descomprimir ZIP
    zip                     # Comprimir ZIP
    p7zip                   # 7zip
    rsync                   # Sincronización de archivos
    man-db                  # Manual pages
    man-pages               # Páginas de manual
    less                    # Pager

    # Red
    networkmanager-applet   # Indicador NM (útil para futuro WM)
    nm-connection-editor    # Editor gráfico NM
    nmap                    # Herramienta de red
    wget                    # Descarga
    curl                    # HTTP requests

    # Desarrollo
    python                  # Python 3
    python-pip              # pip
    nodejs                  # Node.js
    npm                     # Node Package Manager

    # Fuentes
    ttf-jetbrains-mono-nerd # JetBrains Mono Nerd Font (terminal)
    ttf-nerd-fonts-symbols  # Símbolos Nerd Fonts
    noto-fonts              # Noto (cobertura Unicode amplia)
    noto-fonts-emoji        # Emojis
)

echo -e "${CYAN}Paquetes de utilidades que se instalarán:${NC}"
for pkg in "${TOOLS_PACKAGES[@]}"; do
    # Ignorar comentarios
    [[ "$pkg" == \#* ]] && continue
    echo -e "  ${GREEN}✓${NC} $pkg"
done
echo ""

if confirm "¿Instalar estas utilidades?"; then
    # Filtrar comentarios del array
    CLEAN_TOOLS=()
    for pkg in "${TOOLS_PACKAGES[@]}"; do
        [[ "$pkg" == \#* ]] && continue
        CLEAN_TOOLS+=("$pkg")
    done
    sudo pacman -S --noconfirm --needed "${CLEAN_TOOLS[@]}"
    ok "Utilidades instaladas ✓"
else
    info "Saltando utilidades."
fi

# -----------------------------------------------------------------------------
# FASE 6 — ZSH
# -----------------------------------------------------------------------------
section "FASE 6 — ZSH como shell predeterminado"

if command -v zsh &>/dev/null; then
    ok "zsh ya instalado ✓"
else
    sudo pacman -S --noconfirm --needed zsh zsh-completions
    ok "zsh instalado ✓"
fi

# Cambiar shell
if [[ "$SHELL" != "$(which zsh)" ]]; then
    info "Cambiando shell de $USER a zsh..."
    chsh -s "$(which zsh)"
    ok "Shell cambiado a zsh ✓ (efectivo al próximo login)"
else
    ok "zsh ya es tu shell predeterminado ✓"
fi

# .zshrc básico si no existe
if [[ ! -f "$HOME/.zshrc" ]]; then
    info "Creando .zshrc básico..."
    cat > "$HOME/.zshrc" <<'ZSHRC'
# ─── Historial ──────────────────────────────────────────────────────────────
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY

# ─── Autocompletado ─────────────────────────────────────────────────────────
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select

# ─── Prompt simple ──────────────────────────────────────────────────────────
autoload -Uz colors && colors
PROMPT="%{$fg_bold[cyan]%}%n%{$reset_color%}@%{$fg[blue]%}%m%{$reset_color%} %{$fg_bold[green]%}%~%{$reset_color%} %# "

# ─── Aliases ────────────────────────────────────────────────────────────────
alias ls='ls --color=auto'
alias ll='ls -lah --color=auto'
alias la='ls -A --color=auto'
alias grep='grep --color=auto'
alias pacup='sudo pacman -Syu'
alias yayup='yay -Syu'
alias cls='clear'

# ─── Variables de entorno ────────────────────────────────────────────────────
export EDITOR=nano
export VISUAL=nano
export PATH="$HOME/.local/bin:$PATH"
ZSHRC
    ok ".zshrc creado ✓"
else
    ok ".zshrc ya existe, no se modificó ✓"
fi

# -----------------------------------------------------------------------------
# FASE 7 — PAQUETES EXTRA OPCIONALES
# -----------------------------------------------------------------------------
section "FASE 7 — Paquetes adicionales opcionales"

echo -e "${YELLOW}¿Deseas instalar paquetes adicionales ahora?${NC}"
echo -e "${CYAN}(Separados por espacios, ej: neovim mpv feh)${NC}"
echo -e "${CYAN}(Enter para saltar)${NC}"
read -rp "  Paquetes: " EXTRA_NOW

if [[ -n "$EXTRA_NOW" ]]; then
    info "Instalando paquetes extra..."
    # Intentar primero con pacman, luego yay para AUR
    sudo pacman -S --noconfirm --needed $EXTRA_NOW 2>/dev/null || \
    yay -S --noconfirm --needed $EXTRA_NOW
    ok "Paquetes extra instalados ✓"
else
    info "Sin paquetes extra."
fi

# -----------------------------------------------------------------------------
# FASE 8 — SERVICIOS DEL SISTEMA
# -----------------------------------------------------------------------------
section "FASE 8 — Servicios del sistema"

info "Habilitando servicios base..."

# NetworkManager ya se habilitó en install.sh, pero por si acaso
sudo systemctl enable NetworkManager 2>/dev/null && ok "NetworkManager ✓" || true

# Bluetooth (Lenovo V15 tiene BT)
sudo pacman -S --noconfirm --needed bluez bluez-utils
sudo systemctl enable bluetooth
ok "Bluetooth habilitado ✓"

# fstrim — SSD TRIM semanal
sudo systemctl enable fstrim.timer
ok "fstrim.timer (SSD TRIM) ✓"

# Optimización AMD — power management
sudo pacman -S --noconfirm --needed power-profiles-daemon
sudo systemctl enable power-profiles-daemon
ok "power-profiles-daemon (AMD power mgmt) ✓"

# -----------------------------------------------------------------------------
# RESUMEN FINAL
# -----------------------------------------------------------------------------
section "✅ POST-INSTALL COMPLETADO"

echo -e "  ${GREEN}Todo instalado y configurado correctamente.${NC}"
echo ""
echo -e "  ${CYAN}Instalado:${NC}"
echo -e "    ✓ Drivers AMD (mesa, vulkan-radeon, VA-API)"
echo -e "    ✓ Audio (pipewire + wireplumber)"
echo -e "    ✓ Utilidades del sistema"
echo -e "    ✓ zsh como shell predeterminado"
echo -e "    ✓ yay (AUR helper)"
echo -e "    ✓ Bluetooth, fstrim, power-profiles"
echo ""
echo -e "  ${YELLOW}Próximos pasos sugeridos:${NC}"
echo -e "    → Instalar Hyprland:  ${CYAN}yay -S hyprland${NC}"
echo -e "    → Instalar kitty:     ${CYAN}sudo pacman -S kitty${NC}"
echo -e "    → Relogin para zsh:   ${CYAN}exit${NC} y vuelve a entrar"
echo ""
echo -e "  ${YELLOW}¿Reiniciar ahora para aplicar todos los cambios?${NC}"

if confirm "Reiniciar"; then
    sudo reboot
else
    info "Reinicia cuando estés listo: sudo reboot"
fi
