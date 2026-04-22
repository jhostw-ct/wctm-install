#!/usr/bin/env bash
# =============================================================================
#  install.sh — Arch Linux Base Installer
#  Autor: william | Hardware: Lenovo V15 G2 ALC (Ryzen 5 5500U)
#  Uso: Desde el live ISO de Arch Linux
#       bash install.sh
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

# -----------------------------------------------------------------------------
# HELPERS
# -----------------------------------------------------------------------------
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

ask_confirmed() {
    local varname="$1"
    local prompt="$2"
    local default="$3"
    local value
    while true; do
        read -rp "$(echo -e " ${TN_BLUE}[>]${NC} $prompt ${DIM}[$default]:${NC} ")" value
        value="${value:-$default}"
        echo -e " ${DIM}    -> ${TN_WHITE}${value}${NC}"
        confirm "    Confirmar \"${value}\"?" && break
        echo -e " ${TN_YELLOW}    Vuelve a ingresar...${NC}"
    done
    printf -v "$varname" '%s' "$value"
}

# -----------------------------------------------------------------------------
# BANNER
# -----------------------------------------------------------------------------
clear
echo -e "${TN_PURPLE}"
echo "  ┌─────────────────────────────────────────────────────┐"
echo "  │                                                     │"
echo "  │        _             _       ___           _        │"
echo "  │       / \   _ __ ___| |__   |_ _|_ __  ___| |_      │"
echo "  │      / _ \ | '__/ __| '_ \   | || '_ \/ __| __|     │"
echo "  │     / ___ \| | | (__| | | |  | || | | \__ \ |_      │"
echo "  │    /_/   \_\_|  \___|_| |_| |___|_| |_|___/\__|     │"
echo "  │                                                     │"
echo "  │         Lenovo V15 G2 ALC  //  Ryzen 5 5500U        │"
echo "  └─────────────────────────────────────────────────────┘"
echo -e "${NC}"
echo -e " ${DIM}${TN_GRAY}  install.sh — Base Installer${NC}"
echo -e " ${DIM}${TN_GRAY}  $(date)${NC}"
echo ""
read -rp "$(echo -e " ${TN_YELLOW}[?]${NC} Presiona Enter para comenzar... ")" _

# -----------------------------------------------------------------------------
# FASE 0 — VERIFICAR UEFI
# -----------------------------------------------------------------------------
section "FASE 0 // Verificando modo UEFI"

if ls /sys/firmware/efi/efivars &>/dev/null; then
    ok "Sistema arrancado en modo UEFI"
else
    error "No estas en modo UEFI. Reinicia -> BIOS (F2) -> Boot Mode: UEFI"
fi

sleep 1

# -----------------------------------------------------------------------------
# FASE 1 — CONEXIÓN A INTERNET
# -----------------------------------------------------------------------------
section "FASE 1 // Conexion a Internet"

check_connection() {
    ping -c 1 -W 3 archlinux.org &>/dev/null
}

if check_connection; then
    ok "Conexion a Internet detectada"
else
    warn "Sin conexion. Interfaces disponibles:"
    echo ""
    ip link show | grep -E "^[0-9]" | awk '{print "  " $2}' | sed 's/://'
    echo ""
    echo -e " ${TN_BLUE}  [1]${NC} Conectar por WiFi con iwctl"
    echo -e " ${TN_BLUE}  [2]${NC} Ya me conecte, re-verificar"
    echo -e " ${TN_RED}  [3]${NC} Salir"
    echo ""
    read -rp "$(echo -e " ${TN_YELLOW}[?]${NC} Elige [1/2/3]: ")" net_choice

    case "$net_choice" in
        1)
            echo ""
            info "Comandos utiles dentro de iwctl:"
            dim "device list"
            dim "station wlan0 scan"
            dim "station wlan0 get-networks"
            dim "station wlan0 connect \"NombreRed\""
            dim "exit"
            echo ""
            iwctl
            ;;
        2) info "Re-verificando..." ;;
        3) error "Conectate a Internet y vuelve a ejecutar el script." ;;
        *) error "Opcion invalida." ;;
    esac

    check_connection || error "Sin conexion. Verifica tu red e intenta de nuevo."
    ok "Conexion establecida"
fi

info "Sincronizando reloj..."
timedatectl set-ntp true
ok "NTP activado"

sleep 1

# -----------------------------------------------------------------------------
# FASE 2 — MIRRORS CON REFLECTOR
# -----------------------------------------------------------------------------
section "FASE 2 // Optimizando mirrors con reflector"

info "Instalando reflector en el live ISO..."
pacman -Sy --noconfirm reflector

echo ""
info "Generando mirrorlist optimizado (Peru / Chile / Brasil, https, los 10 mas rapidos)..."
reflector \
    --country Peru,Chile,Brazil \
    --protocol https \
    --sort rate \
    --latest 20 \
    --fastest 10 \
    --save /etc/pacman.d/mirrorlist

echo ""
ok "Mirrorlist generado"
echo ""
echo -e " ${DIM}${TN_GRAY}  Mirrors seleccionados:${NC}"
grep "^Server" /etc/pacman.d/mirrorlist | head -5 | while read -r line; do
    dim "$line"
done

echo ""
info "Habilitando multilib en el live ISO (necesario para paquetes lib32-*)..."
if grep -q "^\[multilib\]" /etc/pacman.conf; then
    ok "multilib ya estaba habilitado en el live ISO"
else
    sed -i '/^#\[multilib\]/{
        s/^#//
        n
        s/^#//
    }' /etc/pacman.conf
    ok "multilib habilitado en el live ISO"
fi

info "Sincronizando base de datos con multilib..."
pacman -Sy --noconfirm
ok "Base de datos sincronizada"

sleep 1

# -----------------------------------------------------------------------------
# FASE 3 — DATOS DEL SISTEMA
# -----------------------------------------------------------------------------
section "FASE 3 // Configuracion del sistema"

echo -e " ${DIM}${TN_GRAY}  Ingresa los datos. Podras confirmar cada uno antes de continuar.${NC}"
echo ""

ask_confirmed HOSTNAME "Hostname" "archbook"
echo ""
ask_confirmed USERNAME "Nombre de usuario" "william"
echo ""

# Contraseña root
echo -e " ${TN_BLUE}[>]${NC} Contrasena para ROOT:"
while true; do
    read -rsp "     Password : " ROOT_PASS; echo
    read -rsp "     Confirmar: " ROOT_PASS2; echo
    [[ "$ROOT_PASS" == "$ROOT_PASS2" ]] && break
    warn "No coinciden, intenta de nuevo."
done
ok "Contrasena root configurada"
echo ""

# Contraseña usuario — opción de reusar la de root
if confirm "Usar la misma contrasena para ${USERNAME}?"; then
    USER_PASS="$ROOT_PASS"
    ok "Contrasena de ${USERNAME} = root"
else
    echo ""
    echo -e " ${TN_BLUE}[>]${NC} Contrasena para ${TN_WHITE}${USERNAME}${NC}:"
    while true; do
        read -rsp "     Password : " USER_PASS; echo
        read -rsp "     Confirmar: " USER_PASS2; echo
        [[ "$USER_PASS" == "$USER_PASS2" ]] && break
        warn "No coinciden, intenta de nuevo."
    done
    ok "Contrasena de ${USERNAME} configurada"
fi

sleep 1

# -----------------------------------------------------------------------------
# FASE 4 — SELECCIÓN DE DISCO
# -----------------------------------------------------------------------------
section "FASE 4 // Seleccion de disco"

mapfile -t DISKS < <(lsblk -d -n -o NAME,SIZE,MODEL | grep -v "^loop")

if [[ ${#DISKS[@]} -eq 0 ]]; then
    error "No se encontraron discos."
fi

echo -e " ${TN_CYAN}  Discos disponibles:${NC}"
echo ""
for i in "${!DISKS[@]}"; do
    echo -e "  ${TN_BLUE}[[$((i+1))]]${NC}  ${TN_WHITE}${DISKS[$i]}${NC}"
done
echo ""

while true; do
    read -rp "$(echo -e " ${TN_YELLOW}[?]${NC} Selecciona el numero del disco: ")" DISK_NUM
    if [[ "$DISK_NUM" =~ ^[0-9]+$ ]] && \
       [[ "$DISK_NUM" -ge 1 ]] && \
       [[ "$DISK_NUM" -le ${#DISKS[@]} ]]; then
        break
    fi
    warn "Numero invalido. Elige entre 1 y ${#DISKS[@]}."
done

DISK_NAME=$(echo "${DISKS[$((DISK_NUM-1))]}" | awk '{print $1}')
DISK="/dev/$DISK_NAME"

if [[ "$DISK_NAME" == nvme* ]]; then
    PART_EFI="${DISK}p1"
    PART_ROOT="${DISK}p2"
else
    PART_EFI="${DISK}1"
    PART_ROOT="${DISK}2"
fi

echo ""
echo -e "  ${TN_CYAN}Disco:${NC}           ${BOLD}${TN_WHITE}$DISK${NC}"
echo -e "  ${TN_CYAN}Tamano:${NC}          $(lsblk -d -n -o SIZE "$DISK")"
echo -e "  ${TN_CYAN}Particion EFI:${NC}   ${PART_EFI}  ->  1G   ->  FAT32"
echo -e "  ${TN_CYAN}Particion Root:${NC}  ${PART_ROOT}  ->  Resto  ->  ext4"
echo ""
warn "/!\\ TODO el contenido de ${BOLD}$DISK${NC}${TN_YELLOW} sera BORRADO permanentemente."
echo ""

confirm "Confirmas usar $DISK?" || error "Operacion cancelada."

# -----------------------------------------------------------------------------
# RESUMEN FINAL ANTES DE INSTALAR
# -----------------------------------------------------------------------------
section "RESUMEN // Confirma antes de continuar"

echo -e "  ${TN_CYAN}Hostname     :${NC}  ${TN_WHITE}$HOSTNAME${NC}"
echo -e "  ${TN_CYAN}Usuario      :${NC}  ${TN_WHITE}$USERNAME${NC}  ${DIM}(shell: /bin/zsh)${NC}"
echo -e "  ${TN_CYAN}Disco        :${NC}  ${TN_RED}${BOLD}$DISK${NC}  ${TN_RED}<- TODO SERA BORRADO${NC}"
echo -e "  ${TN_CYAN}EFI          :${NC}  $PART_EFI  -> 1G -> FAT32"
echo -e "  ${TN_CYAN}Root         :${NC}  $PART_ROOT -> Resto -> ext4"
echo -e "  ${TN_CYAN}Timezone     :${NC}  America/Lima"
echo -e "  ${TN_CYAN}Locale       :${NC}  en_US.UTF-8"
echo ""

confirm "Todo correcto? Iniciar instalacion" || error "Instalacion cancelada."

# =============================================================================
# INSTALACION
# =============================================================================

# -----------------------------------------------------------------------------
section "FASE 5 // Particionando $DISK"

info "Limpiando disco..."
wipefs -af "$DISK"
sgdisk --zap-all "$DISK"
ok "Disco limpiado"

info "Creando tabla GPT y particiones..."
sgdisk -n 1:0:+1G  -t 1:ef00 -c 1:"EFI"  "$DISK"
sgdisk -n 2:0:0    -t 2:8300 -c 2:"ROOT" "$DISK"
ok "Particiones creadas"

sleep 2
partprobe "$DISK"
sleep 1

# -----------------------------------------------------------------------------
section "FASE 6 // Formateando particiones"

info "Formateando $PART_EFI -> FAT32..."
mkfs.fat -F32 "$PART_EFI"
ok "EFI lista"

info "Formateando $PART_ROOT -> ext4..."
mkfs.ext4 -F "$PART_ROOT"
ok "Root lista"

sleep 1

# -----------------------------------------------------------------------------
section "FASE 7 // Montando particiones"

mount "$PART_ROOT" /mnt
mkdir -p /mnt/boot/efi
mount "$PART_EFI" /mnt/boot/efi
ok "Particiones montadas"

sleep 1

# -----------------------------------------------------------------------------
section "FASE 8 // Instalando sistema base (pacstrap)"

PACKAGES=(
    # — Base ──────────────────────────────────────────────────────────────────
    base
    linux
    linux-firmware
    amd-ucode
    base-devel
    sudo
    nano
    git
    curl
    wget
    zsh
    zsh-completions
    networkmanager
    grub
    efibootmgr

    # — Drivers AMD ───────────────────────────────────────────────────────────
    mesa
    lib32-mesa
    vulkan-radeon
    lib32-vulkan-radeon
    libva-mesa-driver
    lib32-libva-mesa-driver

    # — Audio — Pipewire ──────────────────────────────────────────────────────
    pipewire
    pipewire-pulse
    pipewire-alsa
    pipewire-jack
    wireplumber
    alsa-utils

    # — Power y sistema ───────────────────────────────────────────────────────
    power-profiles-daemon
    xdg-user-dirs

    # — Hyprland y Wayland ────────────────────────────────────────────────────
    hyprland
    waybar
    rofi
    sddm
    xdg-desktop-portal-hyprland
    xdg-desktop-portal-gtk
    hyprpolkitagent
    grim
    slurp
    wl-clipboard
    qt5-wayland
    qt6-wayland
    nwg-look

    # — Terminal y herramientas ───────────────────────────────────────────────
    kitty
    neovim
    fastfetch
    yazi
    7zip
    ripgrep
    fzf
    fd
    udisks2
    udiskie
)

info "Ejecutando pacstrap — puede tardar varios minutos..."
echo ""
pacstrap -K /mnt "${PACKAGES[@]}"
echo ""
ok "Sistema base instalado"

# -----------------------------------------------------------------------------
section "FASE 9 // Generando fstab"

genfstab -U /mnt >> /mnt/etc/fstab
ok "fstab generado"
echo ""
echo -e " ${DIM}${TN_GRAY}"
cat /mnt/etc/fstab
echo -e "${NC}"

sleep 1

# -----------------------------------------------------------------------------
section "FASE 10 // Configurando sistema (chroot)"

# Escribir credenciales en script temporal — nunca como variables de entorno
cat > /mnt/root/setup_creds.sh <<CREDS
#!/bin/bash
echo "root:${ROOT_PASS}" | chpasswd
useradd -m -G wheel -s /bin/zsh "${USERNAME}"
echo "${USERNAME}:${USER_PASS}" | chpasswd
rm -f /root/setup_creds.sh
CREDS
chmod 700 /mnt/root/setup_creds.sh

arch-chroot /mnt /bin/bash <<CHROOT
set -e

echo "  -> Zona horaria America/Lima..."
ln -sf /usr/share/zoneinfo/America/Lima /etc/localtime
hwclock --systohc
echo "  [OK] Timezone"

echo "  -> Locale en_US.UTF-8..."
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen > /dev/null
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "  [OK] Locale"

echo "  -> Hostname ${HOSTNAME}..."
echo "${HOSTNAME}" > /etc/hostname
cat > /etc/hosts <<EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   ${HOSTNAME}.localdomain ${HOSTNAME}
EOF
echo "  [OK] Hostname"

echo "  -> vconsole.conf..."
echo "KEYMAP=us" > /etc/vconsole.conf
echo "  [OK] vconsole.conf"

echo "  -> mkinitcpio..."
mkinitcpio -P
echo "  [OK] mkinitcpio"

echo "  -> sudo para grupo wheel..."
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
echo "  [OK] sudoers"

echo "  -> Credenciales de usuario..."
bash /root/setup_creds.sh
echo "  [OK] root y ${USERNAME} configurados"

echo "  -> GRUB..."
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=WCTMi
grub-mkconfig -o /boot/grub/grub.cfg
echo "  [OK] GRUB"

echo "  -> Habilitando servicios..."
systemctl enable NetworkManager
echo "  [OK] NetworkManager"

systemctl enable power-profiles-daemon
echo "  [OK] power-profiles-daemon"

systemctl enable fstrim.timer
echo "  [OK] fstrim.timer"

systemctl enable sddm
echo "  [OK] sddm"

echo ""
echo "  Configuracion completada."
CHROOT

ok "Chroot completado"

# -----------------------------------------------------------------------------
section "EXTRA // Copiando post-install.sh al usuario"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
POST_SCRIPT="$SCRIPT_DIR/post-install.sh"

if [[ -f "$POST_SCRIPT" ]]; then
    TARGET_HOME="/mnt/home/$USERNAME"
    cp "$POST_SCRIPT" "$TARGET_HOME/post-install.sh"
    USERID=$(arch-chroot /mnt id -u "$USERNAME")
    GROUPID=$(arch-chroot /mnt id -g "$USERNAME")
    chown "$USERID:$GROUPID" "$TARGET_HOME/post-install.sh"
    chmod +x "$TARGET_HOME/post-install.sh"
    ok "post-install.sh copiado a /home/$USERNAME/"
    info "Al iniciar sesion ejecuta: bash ~/post-install.sh"
else
    warn "No se encontro post-install.sh junto a install.sh"
    info "Descargalo manualmente despues de reiniciar desde tu repo."
fi

sleep 1

# -----------------------------------------------------------------------------
section "COMPLETADO // Arch Linux instalado"

echo -e "${TN_GREEN}"
echo "  .o88b.  .d88b.  .88b  d88. d8888b. db      db"
echo " d8P  Y8 .8P  Y8. 88'YbdP'88 88  '8D 88      88"
echo " 8P      88    88 88  88  88 88oodD' 88      88"
echo " 8b      88    88 88  88  88 88      88      88"
echo " Y8b  d8 '8b  d8' 88  88  88 88      88booo. 88booo."
echo "  'Y88P'  'Y88P'  YP  YP  YP 88      Y88888P Y88888P"
echo -e "${NC}"

echo -e "  ${TN_CYAN}Hostname :${NC}  $HOSTNAME"
echo -e "  ${TN_CYAN}Usuario  :${NC}  $USERNAME  ${DIM}(shell: zsh)${NC}"
echo -e "  ${TN_CYAN}Disco    :${NC}  $DISK"
echo ""
echo -e "  ${TN_YELLOW}Proximos pasos:${NC}"
dim "1. Retira el USB"
dim "2. Inicia sesion como $USERNAME en SDDM"
dim "3. Ejecuta: bash ~/post-install.sh"
echo ""

if confirm "Desmontar y reiniciar ahora?"; then
    info "Desmontando particiones..."
    umount -R /mnt
    info "Reiniciando..."
    reboot
else
    info "Cuando estes listo: umount -R /mnt && reboot"
fi