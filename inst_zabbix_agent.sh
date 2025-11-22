#!/bin/bash

# ==========================================
# INSTALADOR SIMPLE DE ZABBIX AGENT (7.0 LTS)
# ==========================================
# [No verificado]

ZABBIX_SERVER_IP="10.100.100.150"
HOST_NAME=$(hostname)
ZBX_VER="7.0"

# Colores
VERDE='\033[0;32m'
ROJO='\033[0;31m'
AMARILLO='\033[1;33m'
NC='\033[0m'

echo -e "${VERDE}=== INSTALADOR ZABBIX AGENT (MODO SIMPLE) ===${NC}"

if [ "$EUID" -ne 0 ]; then
  echo -e "${ROJO}Error: Ejecuta como root (sudo).${NC}"
  exit 1
fi

echo "→ Instalando prerequisitos..."
apt update -qq
apt install -y wget lsb-release gnupg > /dev/null

source /etc/os-release
CODENAME=$VERSION_CODENAME

# Selección del repo correcto
if [ "$ID" == "ubuntu" ]; then
    case "$CODENAME" in
        noble)
            REPO="https://repo.zabbix.com/zabbix/${ZBX_VER}/ubuntu/pool/main/z/zabbix-release/zabbix-release_${ZBX_VER}-2+ubuntu24.04_all.deb"
            ;;
        jammy)
            REPO="https://repo.zabbix.com/zabbix/${ZBX_VER}/ubuntu/pool/main/z/zabbix-release/zabbix-release_${ZBX_VER}-2+ubuntu22.04_all.deb"
            ;;
        focal)
            REPO="https://repo.zabbix.com/zabbix/${ZBX_VER}/ubuntu/pool/main/z/zabbix-release/zabbix-release_${ZBX_VER}-2+ubuntu20.04_all.deb"
            ;;
        *)
            echo -e "${ROJO}Ubuntu no soportado automáticamente.${NC}"
            exit 1
            ;;
    esac
elif [ "$ID" == "debian" ]; then
    case "$CODENAME" in
        bookworm)
            REPO="https://repo.zabbix.com/zabbix/${ZBX_VER}/debian/pool/main/z/zabbix-release/zabbix-release_${ZBX_VER}-2+debian12_all.deb"
            ;;
        bullseye)
            REPO="https://repo.zabbix.com/zabbix/${ZBX_VER}/debian/pool/main/z/zabbix-release/zabbix-release_${ZBX_VER}-2+debian11_all.deb"
            ;;
        buster)
            REPO="https://repo.zabbix.com/zabbix/${ZBX_VER}/debian/pool/main/z/zabbix-release/zabbix-release_${ZBX_VER}-4+debian10_all.deb"
            ;;
        *)
            echo -e "${ROJO}Debian no soportado automáticamente.${NC}"
            exit 1
            ;;
    esac
else
    echo -e "${ROJO}Este instalador solo soporta Debian/Ubuntu.${NC}"
    exit 1
fi

echo "→ Instalando repo Zabbix..."
wget -q -O /tmp/zabbix-release.deb "$REPO"
dpkg -i /tmp/zabbix-release.deb > /dev/null
apt update -qq

echo "→ Instalando Zabbix Agent..."
apt install -y zabbix-agent > /dev/null

CFG="/etc/zabbix/zabbix_agentd.conf"

echo "→ Configurando agente Zabbix..."
sed -i "s/^Server=.*/Server=$ZABBIX_SERVER_IP/" $CFG
sed -i "s/^ServerActive=.*/ServerActive=$ZABBIX_SERVER_IP/" $CFG
sed -i "s/^Hostname=.*/Hostname=$HOST_NAME/" $CFG

echo "→ Activando servicio..."
systemctl enable zabbix-agent > /dev/null
systemctl restart zabbix-agent

if systemctl is-active --quiet zabbix-agent; then
    echo -e "${VERDE}✓ Agente Zabbix instalado y funcionando.${NC}"
else
    echo -e "${ROJO}✗ Error: el agente no arrancó.${NC}"
fi
