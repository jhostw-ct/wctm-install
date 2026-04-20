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

# Enter o Y = confirmar, cualquier otra cosa = cancelar
confirm() {
    read -rp "$(echo -e "${YELLOW}$1 [Y/n]: ${NC}")" ans
    [[ -z "$ans" || "$ans" =~ ^[Yy]$ ]]
}

# -----------------------------------------------------------------------------
# FASE 0 — VERIFICAR UEFI
# -----------------------------------------------------------------------------
section "FASE 0 — Verificando modo UEFI"

if ls /sys/firmware/efi/efivars &>/dev/null; then
    ok "Sistema arrancado en modo UEFI ✓"
else
    error "No estás en modo UEFI. Reinicia y verifica la BIOS (F2 → Boot Mode: UEFI)"
fi

# -----------------------------------------------------------------------------
# FASE 1 — CONEXIÓN A INTERNET
# -----------------------------------------------------------------------------
section "FASE 1 — Conexión a Internet"

check_connection() {
    ping -c 1 -W 3 archlinux.org &>/dev/null
}

if check_connection; then
    ok "Conexión a Internet detectada ✓"
else
    warn "Sin conexión. Interfaces disponibles:"
    echo ""
    ip link show
    echo ""
    echo -e "${YELLOW}Opciones:${NC}"
    echo "  1) Conectar por WiFi (iwctl)"
    echo "  2) Ya me conecté, re-verificar"
    echo "  3) Salir"
    read -rp "$(echo -e "${YELLOW}Elige [1/2/3]: ${NC}")" net_choice

    case "$net_choice" in
        1)
            info "Comandos dentro de iwctl:"
            echo -e "  ${CYAN}device list${NC}"
            echo -e "  ${CYAN}station wlan0 scan${NC}"
            echo -e "  ${CYAN}station wlan0 get-networks${NC}"
            echo -e "  ${CYAN}station wlan0 connect \"NombreRed\"${NC}"
            echo -e "  ${CYAN}exit${NC}\n"
            iwctl
            ;;
        2) info "Re-verificando..." ;;
        3) error "Conéctate a Internet y vuelve a ejecutar el script." ;;
        *) error "Opción inválida." ;;
    esac

    check_connection || error "Sin conexión. Verifica tu red e intenta de nuevo."
    ok "Conexión establecida ✓"
fi

info "Sincronizando reloj..."
timedatectl set-ntp true
ok "NTP activado ✓"

# -----------------------------------------------------------------------------
# FASE 2 — DATOS DEL SISTEMA
# -----------------------------------------------------------------------------
section "FASE 2 — Configuración del sistema"

read -rp "$(echo -e "${YELLOW}Hostname [archbook]: ${NC}")" HOSTNAME
HOSTNAME="${HOSTNAME:-archbook}"
ok "Hostname: $HOSTNAME"
echo ""

read -rp "$(echo -e "${YELLOW}Nombre de usuario [william]: ${NC}")" USERNAME
USERNAME="${USERNAME:-william}"
ok "Usuario: $USERNAME"
echo ""

echo -e "${YELLOW}Contraseña para ROOT:${NC}"
while true; do
    read -rsp "  Password: " ROOT_PASS; echo
    read -rsp "  Confirmar: " ROOT_PASS2; echo
    [[ "$ROOT_PASS" == "$ROOT_PASS2" ]] && break
    warn "No coinciden, intenta de nuevo."
done
ok "Contraseña root ✓"
echo ""

echo -e "${YELLOW}Contraseña para ${CYAN}${USERNAME}${YELLOW}:${NC}"
while true; do
    read -rsp "  Password: " USER_PASS; echo
    read -rsp "  Confirmar: " USER_PASS2; echo
    [[ "$USER_PASS" == "$USER_PASS2" ]] && break
    warn "No coinciden, intenta de nuevo."
done
ok "Contraseña de $USERNAME ✓"

# -----------------------------------------------------------------------------
# FASE 3 — SELECCIÓN DE DISCO
# -----------------------------------------------------------------------------
section "FASE 3 — Selección de disco"

mapfile -t DISKS < <(lsblk -d -n -o NAME,SIZE,MODEL | grep -v "^loop")

if [[ ${#DISKS[@]} -eq 0 ]]; then
    error "No se encontraron discos."
fi

echo -e "${CYAN}Discos disponibles:${NC}\n"
for i in "${!DISKS[@]}"; do
    echo -e "  ${BOLD}[$((i+1))]${NC}  ${DISKS[$i]}"
done
echo ""

while true; do
    read -rp "$(echo -e "${YELLOW}Selecciona el número del disco: ${NC}")" DISK_NUM
    if [[ "$DISK_NUM" =~ ^[0-9]+$ ]] && \
       [[ "$DISK_NUM" -ge 1 ]] && \
       [[ "$DISK_NUM" -le ${#DISKS[@]} ]]; then
        break
    fi
    warn "Número inválido. Elige entre 1 y ${#DISKS[@]}."
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
echo -e "  ${CYAN}Disco:${NC}          ${BOLD}$DISK${NC}"
echo -e "  ${CYAN}Tamaño:${NC}         $(lsblk -d -n -o SIZE "$DISK")"
echo -e "  ${CYAN}Partición EFI:${NC}  $PART_EFI  → 1G   → FAT32"
echo -e "  ${CYAN}Partición Root:${NC} $PART_ROOT → Resto → ext4"
echo ""
warn "⚠  TODO el contenido de $DISK será BORRADO permanentemente."
echo ""

confirm "¿Confirmas usar $DISK?" || error "Operación cancelada."

# -----------------------------------------------------------------------------
# FASE 4 — PAQUETES
# -----------------------------------------------------------------------------
section "FASE 4 — Paquetes a instalar"

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

echo -e "${CYAN}Paquetes base:${NC}\n"
for pkg in "${BASE_PACKAGES[@]}"; do
    echo -e "  ${GREEN}✓${NC} $pkg"
done
echo ""

echo -e "${YELLOW}Paquetes extra (separados por espacio, Enter para ninguno):${NC}"
read -rp "  > " EXTRA_INPUT

EXTRA_PACKAGES=()
if [[ -n "$EXTRA_INPUT" ]]; then
    read -ra EXTRA_PACKAGES <<< "$EXTRA_INPUT"
    echo ""
    echo -e "${CYAN}Extras agregados:${NC}"
    for pkg in "${EXTRA_PACKAGES[@]}"; do
        echo -e "  ${GREEN}+${NC} $pkg"
    done
fi

ALL_PACKAGES=("${BASE_PACKAGES[@]}" "${EXTRA_PACKAGES[@]}")

# -----------------------------------------------------------------------------
# RESUMEN FINAL
# -----------------------------------------------------------------------------
section "RESUMEN — Confirma antes de continuar"

echo -e "  ${CYAN}Hostname:${NC}        $HOSTNAME"
echo -e "  ${CYAN}Usuario:${NC}         $USERNAME  (shell: /bin/zsh)"
echo -e "  ${CYAN}Disco:${NC}           $DISK  ← TODO SERÁ BORRADO"
echo -e "  ${CYAN}Partición EFI:${NC}   $PART_EFI  → 1G → FAT32"
echo -e "  ${CYAN}Partición Root:${NC}  $PART_ROOT → Resto → ext4"
echo -e "  ${CYAN}Timezone:${NC}        America/Lima"
echo -e "  ${CYAN}Locale:${NC}          en_US.UTF-8"
echo -e "  ${CYAN}Paquetes:${NC}        ${ALL_PACKAGES[*]}"
echo ""

confirm "¿Todo correcto? Iniciar instalación" || error "Instalación cancelada."

# =============================================================================
# INSTALACIÓN
# =============================================================================

section "FASE 5 — Particionando $DISK"

info "Limpiando disco..."
wipefs -af "$DISK"
sgdisk --zap-all "$DISK"
ok "Disco limpiado ✓"

info "Creando tabla GPT y particiones..."
sgdisk -n 1:0:+1G  -t 1:ef00 -c 1:"EFI"  "$DISK"
sgdisk -n 2:0:0     -t 2:8300 -c 2:"ROOT" "$DISK"
ok "Particiones creadas ✓"

sleep 2
partprobe "$DISK"
sleep 1

# -----------------------------------------------------------------------------
section "FASE 6 — Formateando"

info "Formateando $PART_EFI → FAT32..."
mkfs.fat -F32 "$PART_EFI"
ok "EFI lista ✓"

info "Formateando $PART_ROOT → ext4..."
mkfs.ext4 -F "$PART_ROOT"
ok "Root lista ✓"

# -----------------------------------------------------------------------------
section "FASE 7 — Montando particiones"

mount "$PART_ROOT" /mnt
mkdir -p /mnt/boot/efi
mount "$PART_EFI" /mnt/boot/efi
ok "Particiones montadas ✓"

# -----------------------------------------------------------------------------
section "FASE 8 — Instalando sistema base (pacstrap)"

info "Esto puede tardar varios minutos..."
pacstrap -K /mnt "${ALL_PACKAGES[@]}"
ok "Sistema base instalado ✓"

# -----------------------------------------------------------------------------
section "FASE 9 — Generando fstab"

genfstab -U /mnt >> /mnt/etc/fstab
ok "fstab generado ✓"
echo ""
cat /mnt/etc/fstab

# -----------------------------------------------------------------------------
section "FASE 10 — Configurando sistema (chroot)"

arch-chroot /mnt /bin/bash <<CHROOT_SCRIPT
set -e

echo "  → Zona horaria America/Lima..."
ln -sf /usr/share/zoneinfo/America/Lima /etc/localtime
hwclock --systohc
echo "  [OK] Timezone"

echo "  → Locale en_US.UTF-8..."
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen > /dev/null
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "  [OK] Locale"

echo "  → Hostname $HOSTNAME..."
echo "$HOSTNAME" > /etc/hostname
cat > /etc/hosts <<EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOSTNAME.localdomain $HOSTNAME
EOF
echo "  [OK] Hostname"

echo "  → NetworkManager..."
systemctl enable NetworkManager
echo "  [OK] NetworkManager"

echo "  → Contraseña root..."
echo "root:$ROOT_PASS" | chpasswd
echo "  [OK] root password"

echo "  → Usuario $USERNAME (shell: zsh)..."
useradd -m -G wheel -s /bin/zsh "$USERNAME"
echo "$USERNAME:$USER_PASS" | chpasswd
echo "  [OK] Usuario creado"

echo "  → sudo para grupo wheel..."
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
echo "  [OK] sudoers"

echo "  → GRUB..."
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=ARCH
grub-mkconfig -o /boot/grub/grub.cfg
echo "  [OK] GRUB"

echo ""
echo "  Configuración completada."
CHROOT_SCRIPT

ok "Chroot completado ✓"

# -----------------------------------------------------------------------------
section "✅ INSTALACIÓN COMPLETADA"

echo -e "  ${GREEN}Arch Linux instalado correctamente.${NC}\n"
echo -e "  ${CYAN}Hostname:${NC}  $HOSTNAME"
echo -e "  ${CYAN}Usuario:${NC}   $USERNAME  (shell: zsh)"
echo -e "  ${CYAN}Disco:${NC}     $DISK\n"
echo -e "  ${YELLOW}Próximos pasos:${NC}"
echo -e "    1. Retira el USB"
echo -e "    2. Inicia sesión como ${CYAN}$USERNAME${NC}"
echo -e "    3. Clona tu repo y ejecuta ${CYAN}bash post-install.sh${NC}\n"

if confirm "¿Desmontar y reiniciar ahora?"; then
    umount -R /mnt
    reboot
else
    info "Cuando estés listo: umount -R /mnt && reboot"
fi
