#!/bin/bash

# ===============================================
# 🚀 REMNAWAVE BEDOLAGA BOT - БЫСТРАЯ УСТАНОВКА
# ===============================================
# Одна команда для запуска полной установки
# ===============================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║     🤖 REMNAWAVE BEDOLAGA BOT - БЫСТРАЯ УСТАНОВКА 🤖        ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Проверка root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}❌ Скрипт должен быть запущен от имени root!${NC}"
    echo -e "${YELLOW}Используйте: sudo bash quick-install.sh${NC}"
    exit 1
fi

# Установка необходимых пакетов
echo -e "${GREEN}📦 Установка базовых пакетов...${NC}"
apt-get update -y
apt-get install -y curl wget git

# URL репозитория
REPO_URL="https://github.com/RamaPulya/bot_auto_install"
REPO_BRANCH="spiderman"
REPO_RAW="https://raw.githubusercontent.com/RamaPulya/bot_auto_install/${REPO_BRANCH}"

# Директория для скриптов
INSTALL_DIR="/tmp/bedolaga-installer"
rm -rf "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR/lib"

echo -e "${GREEN}📥 Загрузка установщика...${NC}"

# Скачиваем главный скрипт и все модули
download_file() {
    local file=$1
    local dest=$2
    local auth_header=()
    if [ -n "$GITHUB_TOKEN" ]; then
        auth_header=(-H "Authorization: Bearer $GITHUB_TOKEN")
    fi
    echo -e "${CYAN}   Загрузка: $file${NC}"
    curl -fsSL "${auth_header[@]}" "${REPO_RAW}/scripts/${file}" -o "$dest" || {
        echo -e "${RED}   ❌ Не удалось загрузить $file${NC}"
        return 1
    }
}

# Основной скрипт
download_file "install.sh" "$INSTALL_DIR/install.sh"

# Модули
MODULES=(
    "lib/utils.sh"
    "lib/packages.sh"
    "lib/interactive.sh"
    "lib/docker_setup.sh"
    "lib/env_config.sh"
    "lib/nginx_setup.sh"
    "lib/caddy_setup.sh"
    "lib/final.sh"
)

for module in "${MODULES[@]}"; do
    download_file "$module" "$INSTALL_DIR/$module" || {
        echo -e "${YELLOW}⚠️ Не удалось загрузить модули, клонируем репозиторий...${NC}"
        rm -rf "$INSTALL_DIR"
        if [ -n "$GITHUB_TOKEN" ]; then
            git clone --depth 1 --single-branch --branch "$REPO_BRANCH" \
                "https://$GITHUB_TOKEN@github.com/RamaPulya/bot_auto_install.git" "$INSTALL_DIR"
        else
            git clone --depth 1 --single-branch --branch "$REPO_BRANCH" "$REPO_URL" "$INSTALL_DIR"
        fi
        cd "$INSTALL_DIR/scripts"
        chmod +x install.sh lib/*.sh
        echo -e "${GREEN}🚀 Запуск установщика...${NC}"
        bash install.sh
        exit $?
    }
done

# Делаем скрипты исполняемыми
chmod +x "$INSTALL_DIR/install.sh"
chmod +x "$INSTALL_DIR/lib/"*.sh

echo -e "${GREEN}🚀 Запуск установщика...${NC}"
cd "$INSTALL_DIR"
bash install.sh

# Очистка
rm -rf "$INSTALL_DIR"

