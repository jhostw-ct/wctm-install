#!/usr/bin/env bash
# =============================================================================
#  install.sh — Arch Linux Base Installer
#  Autor: william | Hardware: Lenovo V15 G2 ALC (Ryzen 5 5500U)
#  Uso: Desde el live ISO de Arch Linux
#       curl -O https://raw.githubusercontent.com/TU_USER/arch-install/main/install.sh
#       bash install.sh
# =============================================================================

set -e

# -----------------------------------------------------------------------------
# COLORES — Tokyo Night
# -----------------------------------------------------------------------------
TN_BG='\033[0m'
TN_PURPLE='\033[38;5;141m'   # #bb9af7 — purple
TN_BLUE='\033[38;5;111m'     # #7aa2f7 — blue
TN_CYAN='\033[38;5;73m'      # #7dcfff — cyan
TN_GREEN='\033[38;5;120m'    # #9ece6a — green
TN_YELLOW='\033[38;5;179m'   # #e0af68 — yellow
TN_RED='\033[38;5;203m'      # #f7768e — red
TN_MAGENTA='\033[38;5;204m'  # #ff007c — magenta
TN_GRAY='\033[38;5;238m'     # dark gray
TN_WHITE='\033[38;5;255m'    # bright white
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
dim()   { echo -e " ${DIM}${TN_GRAY}$1${NC}"; }

section() {
    clear
    echo -e "${TN_PURPLE}"
    echo "  ╔══════════════════════════════════════════╗"
    printf  "  ║  %-40s  ║\n" "$1"
    echo "  ╚══════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Enter o Y = confirmar
confirm() {
    read -rp "$(echo -e " ${TN_YELLOW}[?]${NC} $1 ${DIM}[Y/n]:${NC} ")" ans
    [[ -z "$ans" || "$ans" =~ ^[Yy]$ ]]
}

# Pedir un valor con confirmación — reintenta si el usuario no confirma
# ask_confirmed <varname> <prompt> <default>
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
            dim "  device list"
            dim "  station wlan0 scan"
            dim "  station wlan0 get-networks"
            dim "  station wlan0 connect \"NombreRed\""
            dim "  exit"
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
# FASE 2 — DATOS DEL SISTEMA
# -----------------------------------------------------------------------------
section "FASE 2 // Configuracion del sistema"

echo -e " ${DIM}${TN_GRAY}  Ingresa los datos. Podras confirmar cada uno antes de continuar.${NC}"
echo ""

ask_confirmed HOSTNAME "Hostname" "archbook"
echo ""
ask_confirmed USERNAME "Nombre de usuario" "william"
echo ""

# Contraseña root (sin confirmación de texto, solo doble ingreso)
echo -e " ${TN_BLUE}[>]${NC} Contrasena para ROOT:"
while true; do
    read -rsp "     Password : " ROOT_PASS; echo
    read -rsp "     Confirmar: " ROOT_PASS2; echo
    [[ "$ROOT_PASS" == "$ROOT_PASS2" ]] && break
    warn "No coinciden, intenta de nuevo."
done
ok "Contrasena root configurada"
echo ""

echo -e " ${TN_BLUE}[>]${NC} Contrasena para ${TN_WHITE}${USERNAME}${NC}:"
while true; do
    read -rsp "     Password : " USER_PASS; echo
    read -rsp "     Confirmar: " USER_PASS2; echo
    [[ "$USER_PASS" == "$USER_PASS2" ]] && break
    warn "No coinciden, intenta de nuevo."
done
ok "Contrasena de ${USERNAME} configurada"

sleep 1

# -----------------------------------------------------------------------------
# FASE 3 — SELECCIÓN DE DISCO
# -----------------------------------------------------------------------------
section "FASE 3 // Seleccion de disco"

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
# FASE 4 — PAQUETES
# -----------------------------------------------------------------------------
section "FASE 4 // Paquetes a instalar"

BASE_PACKAGES=(
    base
    linux
    linux-lts
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
)

echo -e " ${TN_CYAN}  Paquetes base:${NC}"
echo ""
for pkg in "${BASE_PACKAGES[@]}"; do
    echo -e "  ${TN_GREEN}(+)${NC} $pkg"
done
echo ""

echo -e " ${TN_YELLOW}  Paquetes extra${NC} ${DIM}(separados por espacio, Enter para ninguno):${NC}"
read -rp "  > " EXTRA_INPUT

EXTRA_PACKAGES=()
if [[ -n "$EXTRA_INPUT" ]]; then
    read -ra EXTRA_PACKAGES <<< "$EXTRA_INPUT"
    echo ""
    echo -e " ${TN_CYAN}  Extras agregados:${NC}"
    for pkg in "${EXTRA_PACKAGES[@]}"; do
        echo -e "  ${TN_MAGENTA}[+]${NC} $pkg"
    done
fi

ALL_PACKAGES=("${BASE_PACKAGES[@]}" "${EXTRA_PACKAGES[@]}")

sleep 1

# -----------------------------------------------------------------------------
# RESUMEN FINAL
# -----------------------------------------------------------------------------
section "RESUMEN // Confirma antes de continuar"

echo -e "  ${TN_CYAN}Hostname     :${NC}  ${TN_WHITE}$HOSTNAME${NC}"
echo -e "  ${TN_CYAN}Usuario      :${NC}  ${TN_WHITE}$USERNAME${NC}  ${DIM}(shell: /bin/zsh)${NC}"
echo -e "  ${TN_CYAN}Disco        :${NC}  ${TN_RED}${BOLD}$DISK${NC}  ${TN_RED}<- TODO SERA BORRADO${NC}"
echo -e "  ${TN_CYAN}EFI          :${NC}  $PART_EFI  -> 1G -> FAT32"
echo -e "  ${TN_CYAN}Root         :${NC}  $PART_ROOT -> Resto -> ext4"
echo -e "  ${TN_CYAN}Timezone     :${NC}  America/Lima"
echo -e "  ${TN_CYAN}Locale       :${NC}  en_US.UTF-8"
echo -e "  ${TN_CYAN}Paquetes     :${NC}  ${DIM}${ALL_PACKAGES[*]}${NC}"
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
sgdisk -n 2:0:0     -t 2:8300 -c 2:"ROOT" "$DISK"
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
section "FASE 8 // Instalando sistema base"

info "Ejecutando pacstrap — puede tardar varios minutos..."
echo ""
pacstrap -K /mnt "${ALL_PACKAGES[@]}"
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

arch-chroot /mnt /bin/bash <<CHROOT_SCRIPT
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

echo "  -> Hostname $HOSTNAME..."
echo "$HOSTNAME" > /etc/hostname
cat > /etc/hosts <<EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOSTNAME.localdomain $HOSTNAME
EOF
echo "  [OK] Hostname"

echo "  -> NetworkManager..."
systemctl enable NetworkManager
echo "  [OK] NetworkManager"

echo "  -> Contrasena root..."
echo "root:$ROOT_PASS" | chpasswd
echo "  [OK] root password"

echo "  -> Usuario $USERNAME (shell: zsh)..."
useradd -m -G wheel -s /bin/zsh "$USERNAME"
echo "$USERNAME:$USER_PASS" | chpasswd
echo "  [OK] Usuario creado"

echo "  -> sudo para grupo wheel..."
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
echo "  [OK] sudoers"

echo "  -> GRUB..."
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=ARCH
grub-mkconfig -o /boot/grub/grub.cfg
echo "  [OK] GRUB"

echo ""
echo "  Configuracion completada."
CHROOT_SCRIPT

ok "Chroot completado"

# -----------------------------------------------------------------------------
section "EXTRA // Copiando post-install.sh al usuario"

# Buscar post-install.sh en el mismo directorio que este script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
POST_SCRIPT="$SCRIPT_DIR/post-install.sh"

if [[ -f "$POST_SCRIPT" ]]; then
    TARGET_HOME="/mnt/home/$USERNAME"
    cp "$POST_SCRIPT" "$TARGET_HOME/post-install.sh"
    # Dar ownership al usuario (necesitamos su UID/GID dentro del sistema instalado)
    USERID=$(arch-chroot /mnt id -u "$USERNAME")
    GROUPID=$(arch-chroot /mnt id -g "$USERNAME")
    chown "$USERID:$GROUPID" "$TARGET_HOME/post-install.sh"
    chmod +x "$TARGET_HOME/post-install.sh"
    ok "post-install.sh copiado a /home/$USERNAME/"
    ok "Permisos: chmod +x aplicado"
    info "Al iniciar sesion ejecuta: bash ~/post-install.sh"
else
    warn "No se encontro post-install.sh junto a install.sh"
    warn "Ruta buscada: $POST_SCRIPT"
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
echo -e "  ${DIM}  1. Retira el USB${NC}"
echo -e "  ${DIM}  2. Inicia sesion como ${TN_WHITE}$USERNAME${NC}"
echo -e "  ${DIM}  3. Ejecuta${NC} ${TN_CYAN}bash ~/post-install.sh${NC}"
echo ""

if confirm "Desmontar y reiniciar ahora?"; then
    info "Desmontando particiones..."
    umount -R /mnt
    info "Reiniciando..."
    reboot
else
    info "Cuando estes listo: umount -R /mnt && reboot"
fi
