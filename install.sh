#!/usr/bin/env bash
# =============================================================================
#  install.sh — Arch Linux Base Installer
#  Autor: william | Hardware: Lenovo V15 G2 ALC (Ryzen 5 5500U)
#  Uso: Desde el live ISO de Arch Linux
#       curl -O https://raw.githubusercontent.com/TU_USER/arch-install/main/install.sh
#       bash install.sh
# =============================================================================

set -e  # Detener en cualquier error

# -----------------------------------------------------------------------------
# COLORES
# -----------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# -----------------------------------------------------------------------------
# HELPERS
# -----------------------------------------------------------------------------
info()    { echo -e "${CYAN}[INFO]${NC} $1"; }
ok()      { echo -e "${GREEN}[OK]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }
section() { echo -e "\n${BOLD}${BLUE}══════════════════════════════════════${NC}"; \
            echo -e "${BOLD}${BLUE}  $1${NC}"; \
            echo -e "${BOLD}${BLUE}══════════════════════════════════════${NC}\n"; }

confirm() {
    # $1 = pregunta, retorna 0 si yes
    read -rp "$(echo -e "${YELLOW}$1 [s/N]: ${NC}")" ans
    [[ "$ans" =~ ^[sS]$ ]]
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
# FASE 1 — VERIFICAR CONEXIÓN
# -----------------------------------------------------------------------------
section "FASE 1 — Conexión a Internet"

check_connection() {
    ping -c 1 -W 3 archlinux.org &>/dev/null
}

if check_connection; then
    ok "Conexión a Internet detectada ✓"
else
    warn "Sin conexión. Verificando interfaces..."
    echo ""

    # Mostrar interfaces disponibles
    info "Interfaces de red disponibles:"
    ip link show
    echo ""

    echo -e "${YELLOW}Opciones:${NC}"
    echo "  1) Conectar por WiFi (iwctl)"
    echo "  2) Ya conecté manualmente, re-verificar"
    echo "  3) Salir y conectarme primero"
    read -rp "$(echo -e "${YELLOW}Elige [1/2/3]: ${NC}")" net_choice

    case "$net_choice" in
        1)
            info "Abriendo iwctl... Comandos útiles:"
            echo -e "  ${CYAN}device list${NC}"
            echo -e "  ${CYAN}station wlan0 scan${NC}"
            echo -e "  ${CYAN}station wlan0 get-networks${NC}"
            echo -e "  ${CYAN}station wlan0 connect \"NombreRed\"${NC}"
            echo -e "  ${CYAN}exit${NC}"
            echo ""
            iwctl
            ;;
        2)
            info "Re-verificando..."
            ;;
        3)
            error "Conéctate a Internet y ejecuta el script de nuevo."
            ;;
        *)
            error "Opción inválida."
            ;;
    esac

    # Re-verificar
    if check_connection; then
        ok "Conexión establecida ✓"
    else
        error "Sigue sin haber conexión. Verifica tu red y vuelve a intentarlo."
    fi
fi

# Sincronizar reloj
info "Sincronizando reloj..."
timedatectl set-ntp true
ok "NTP activado ✓"

# -----------------------------------------------------------------------------
# FASE 2 — DATOS DEL SISTEMA
# -----------------------------------------------------------------------------
section "FASE 2 — Configuración del sistema"

# Hostname
echo -e "${YELLOW}Ingresa el nombre de la máquina (hostname):${NC}"
read -rp "  Hostname [archbook]: " HOSTNAME
HOSTNAME="${HOSTNAME:-archbook}"
ok "Hostname: $HOSTNAME"

echo ""

# Usuario
echo -e "${YELLOW}Ingresa el nombre de usuario:${NC}"
read -rp "  Usuario [william]: " USERNAME
USERNAME="${USERNAME:-william}"
ok "Usuario: $USERNAME"

echo ""

# Contraseña root
echo -e "${YELLOW}Contraseña para ROOT:${NC}"
while true; do
    read -rsp "  root password: " ROOT_PASS; echo
    read -rsp "  Confirmar root password: " ROOT_PASS2; echo
    [[ "$ROOT_PASS" == "$ROOT_PASS2" ]] && break
    warn "Las contraseñas no coinciden. Intenta de nuevo."
done
ok "Contraseña root configurada ✓"

echo ""

# Contraseña usuario
echo -e "${YELLOW}Contraseña para ${USERNAME}:${NC}"
while true; do
    read -rsp "  $USERNAME password: " USER_PASS; echo
    read -rsp "  Confirmar $USERNAME password: " USER_PASS2; echo
    [[ "$USER_PASS" == "$USER_PASS2" ]] && break
    warn "Las contraseñas no coinciden. Intenta de nuevo."
done
ok "Contraseña de $USERNAME configurada ✓"

# -----------------------------------------------------------------------------
# FASE 3 — DISCO
# -----------------------------------------------------------------------------
section "FASE 3 — Selección de disco"

echo -e "${CYAN}Discos disponibles:${NC}"
echo ""
lsblk -d -o NAME,SIZE,MODEL,TYPE | grep disk
echo ""

read -rp "$(echo -e "${YELLOW}Ingresa el disco destino (ej: nvme0n1, sda): ${NC}")" DISK_NAME
DISK="/dev/$DISK_NAME"

# Validar que existe
if [[ ! -b "$DISK" ]]; then
    error "El disco $DISK no existe. Verifica con: lsblk"
fi

# Definir particiones según tipo de disco
if [[ "$DISK_NAME" == nvme* ]]; then
    PART_EFI="${DISK}p1"
    PART_ROOT="${DISK}p2"
else
    PART_EFI="${DISK}1"
    PART_ROOT="${DISK}2"
fi

echo ""
warn "⚠️  ADVERTENCIA: Se borrará TODO el contenido de $DISK"
echo -e "   Disco seleccionado: ${RED}${BOLD}$DISK${NC}"
echo -e "   Tamaño: $(lsblk -d -n -o SIZE $DISK)"
echo ""

if ! confirm "¿Estás SEGURO de que quieres borrar $DISK?"; then
    error "Operación cancelada. Vuelve a ejecutar el script."
fi

ok "Disco confirmado: $DISK"

# -----------------------------------------------------------------------------
# FASE 4 — PAQUETES
# -----------------------------------------------------------------------------
section "FASE 4 — Paquetes a instalar"

BASE_PACKAGES="base linux linux-lts linux-firmware amd-ucode base-devel sudo nano git curl wget"

echo -e "${CYAN}Paquetes base que se instalarán:${NC}"
echo ""
for pkg in $BASE_PACKAGES; do
    echo -e "  ${GREEN}✓${NC} $pkg"
done
echo ""

echo -e "${YELLOW}¿Quieres agregar paquetes adicionales ahora?${NC}"
echo -e "${CYAN}(Separados por espacios, ej: neovim htop fastfetch)${NC}"
echo -e "${CYAN}(Enter para continuar sin extras)${NC}"
read -rp "  Paquetes extra: " EXTRA_PACKAGES

if [[ -n "$EXTRA_PACKAGES" ]]; then
    echo ""
    echo -e "${CYAN}Paquetes extra que se agregarán:${NC}"
    for pkg in $EXTRA_PACKAGES; do
        echo -e "  ${GREEN}+${NC} $pkg"
    done
fi

ALL_PACKAGES="$BASE_PACKAGES $EXTRA_PACKAGES"

echo ""

# -----------------------------------------------------------------------------
# RESUMEN FINAL ANTES DE PROCEDER
# -----------------------------------------------------------------------------
section "RESUMEN — Confirma antes de continuar"

echo -e "  ${CYAN}Hostname:${NC}        $HOSTNAME"
echo -e "  ${CYAN}Usuario:${NC}         $USERNAME"
echo -e "  ${CYAN}Disco:${NC}           $DISK  (SE BORRARÁ TODO)"
echo -e "  ${CYAN}Partición EFI:${NC}   $PART_EFI  →  1G  →  FAT32"
echo -e "  ${CYAN}Partición Root:${NC}  $PART_ROOT →  Resto → ext4"
echo -e "  ${CYAN}Timezone:${NC}        America/Lima"
echo -e "  ${CYAN}Locale:${NC}          en_US.UTF-8"
echo -e "  ${CYAN}Paquetes:${NC}        $ALL_PACKAGES"
echo ""

if ! confirm "¿Todo correcto? Comenzar instalación"; then
    error "Instalación cancelada."
fi

# =============================================================================
# INSTALACIÓN
# =============================================================================

# -----------------------------------------------------------------------------
# FASE 5 — PARTICIONAR
# -----------------------------------------------------------------------------
section "FASE 5 — Particionando disco"

info "Limpiando disco $DISK..."
wipefs -af "$DISK"
sgdisk --zap-all "$DISK"
ok "Disco limpiado ✓"

info "Creando tabla GPT y particiones..."
sgdisk -n 1:0:+1G   -t 1:ef00 -c 1:"EFI"  "$DISK"
sgdisk -n 2:0:0      -t 2:8300 -c 2:"ROOT" "$DISK"
ok "Particiones creadas ✓"

# Esperar a que el kernel reconozca las particiones
sleep 2
partprobe "$DISK"
sleep 1

# -----------------------------------------------------------------------------
# FASE 6 — FORMATEAR
# -----------------------------------------------------------------------------
section "FASE 6 — Formateando particiones"

info "Formateando EFI ($PART_EFI) → FAT32..."
mkfs.fat -F32 "$PART_EFI"
ok "EFI formateada ✓"

info "Formateando Root ($PART_ROOT) → ext4..."
mkfs.ext4 -F "$PART_ROOT"
ok "Root formateada ✓"

# -----------------------------------------------------------------------------
# FASE 7 — MONTAR
# -----------------------------------------------------------------------------
section "FASE 7 — Montando particiones"

mount "$PART_ROOT" /mnt
mkdir -p /mnt/boot/efi
mount "$PART_EFI" /mnt/boot/efi
ok "Particiones montadas ✓"

# -----------------------------------------------------------------------------
# FASE 8 — INSTALAR BASE
# -----------------------------------------------------------------------------
section "FASE 8 — Instalando sistema base"

info "Ejecutando pacstrap (puede tardar varios minutos)..."
# shellcheck disable=SC2086
pacstrap -K /mnt $ALL_PACKAGES
ok "Sistema base instalado ✓"

# -----------------------------------------------------------------------------
# FASE 9 — FSTAB
# -----------------------------------------------------------------------------
section "FASE 9 — Generando fstab"

genfstab -U /mnt >> /mnt/etc/fstab
ok "fstab generado ✓"
echo ""
cat /mnt/etc/fstab

# -----------------------------------------------------------------------------
# FASE 10 — CONFIGURACIÓN (via arch-chroot)
# -----------------------------------------------------------------------------
section "FASE 10 — Configurando sistema (chroot)"

info "Entrando al chroot para configurar..."

arch-chroot /mnt /bin/bash <<CHROOT_SCRIPT
set -e

# Zona horaria
ln -sf /usr/share/zoneinfo/America/Lima /etc/localtime
hwclock --systohc
echo "  [OK] Zona horaria: America/Lima"

# Locale
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "  [OK] Locale: en_US.UTF-8"

# Hostname
echo "$HOSTNAME" > /etc/hostname
cat > /etc/hosts <<EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOSTNAME.localdomain $HOSTNAME
EOF
echo "  [OK] Hostname: $HOSTNAME"

# NetworkManager
systemctl enable NetworkManager
echo "  [OK] NetworkManager habilitado"

# Contraseña root
echo "root:$ROOT_PASS" | chpasswd
echo "  [OK] Contraseña root configurada"

# Usuario
useradd -m -G wheel -s /bin/bash "$USERNAME"
echo "$USERNAME:$USER_PASS" | chpasswd
echo "  [OK] Usuario $USERNAME creado"

# Sudo: habilitar wheel
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
echo "  [OK] sudo para wheel configurado"

# GRUB
pacman -S --noconfirm grub efibootmgr
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=ARCH
grub-mkconfig -o /boot/grub/grub.cfg
echo "  [OK] GRUB instalado y configurado"

echo ""
echo "  Configuración del chroot completada."
CHROOT_SCRIPT

ok "Chroot completado ✓"

# -----------------------------------------------------------------------------
# FASE 11 — FINALIZAR
# -----------------------------------------------------------------------------
section "✅ INSTALACIÓN COMPLETADA"

echo -e "  ${GREEN}Sistema base de Arch Linux instalado correctamente.${NC}"
echo ""
echo -e "  ${CYAN}Hostname:${NC}  $HOSTNAME"
echo -e "  ${CYAN}Usuario:${NC}   $USERNAME"
echo -e "  ${CYAN}Disco:${NC}     $DISK"
echo ""
echo -e "  ${YELLOW}Próximos pasos:${NC}"
echo -e "    1. Retira el USB"
echo -e "    2. Ejecuta: ${CYAN}umount -R /mnt && reboot${NC}"
echo -e "    3. Inicia sesión como ${CYAN}$USERNAME${NC}"
echo -e "    4. Clona tu repo y ejecuta ${CYAN}post-install.sh${NC}"
echo ""

if confirm "¿Desmontar y reiniciar ahora?"; then
    info "Desmontando particiones..."
    umount -R /mnt
    info "Reiniciando..."
    reboot
else
    info "Cuando estés listo ejecuta: umount -R /mnt && reboot"
fi
