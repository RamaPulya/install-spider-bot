#!/bin/bash

# ===============================================
# 🗑️ REMNAWAVE BEDOLAGA BOT - ДЕИНСТАЛЛЯТОР
# ===============================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Автоопределение директории установки
if [ -d "/opt/remnawave-bedolaga-telegram-bot" ]; then
    INSTALL_DIR="/opt/remnawave-bedolaga-telegram-bot"
elif [ -d "/root/remnawave-bedolaga-telegram-bot" ]; then
    INSTALL_DIR="/root/remnawave-bedolaga-telegram-bot"
else
    if [ -f "./docker-compose.yml" ] && [ -f "./.env" ]; then
        INSTALL_DIR="$(pwd)"
    else
        echo -e "${RED}❌ Бот не установлен!${NC}"
        exit 1
    fi
fi

echo -e "${PURPLE}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║     🗑️ REMNAWAVE BEDOLAGA BOT - ДЕИНСТАЛЛЯТОР 🗑️            ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${CYAN}📁 Директория: $INSTALL_DIR${NC}"
echo

# Проверка root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}❌ Скрипт должен быть запущен от имени root!${NC}"
    exit 1
fi

echo -e "${YELLOW}⚠️  ВНИМАНИЕ! Это действие удалит:${NC}"
echo -e "   - Docker контейнеры бота"
echo -e "   - Файлы конфигурации"
echo -e "   - Конфигурации Nginx"
echo
echo -e "${CYAN}Данные PostgreSQL и бэкапы НЕ будут удалены автоматически.${NC}"
echo

read -p "Вы уверены, что хотите удалить бота? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo -e "${GREEN}Удаление отменено${NC}"
    exit 0
fi

echo

# Создание бэкапа перед удалением
read -p "Создать бэкап перед удалением? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${CYAN}📦 Создание бэкапа...${NC}"
    BACKUP_NAME="bedolaga_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
    if [ -d "$INSTALL_DIR" ]; then
        cd "$INSTALL_DIR"
        tar -czf "/root/$BACKUP_NAME" .env data/ 2>/dev/null || true
        echo -e "${GREEN}✅ Бэкап создан: /root/$BACKUP_NAME${NC}"
    fi
fi

# Остановка Docker контейнеров
echo -e "${CYAN}🛑 Остановка Docker контейнеров...${NC}"
if [ -d "$INSTALL_DIR" ]; then
    cd "$INSTALL_DIR"
    # Определяем compose файл
    COMPOSE_FILE="docker-compose.yml"
    [ -f ".install_config" ] && source .install_config
    [ -f "docker-compose.local.yml" ] && COMPOSE_FILE="docker-compose.local.yml"
    
    docker compose -f "$COMPOSE_FILE" down -v 2>/dev/null || docker compose down -v 2>/dev/null || true
fi
echo -e "${GREEN}✅ Контейнеры остановлены${NC}"

# Удаление конфигураций Nginx
echo -e "${CYAN}🔧 Удаление конфигураций Nginx...${NC}"
rm -f /etc/nginx/sites-enabled/bedolaga-webhook
rm -f /etc/nginx/sites-enabled/bedolaga-miniapp
rm -f /etc/nginx/sites-available/bedolaga-webhook
rm -f /etc/nginx/sites-available/bedolaga-miniapp
nginx -t 2>/dev/null && systemctl reload nginx 2>/dev/null || true
echo -e "${GREEN}✅ Конфигурации Nginx удалены${NC}"

# Удаление Docker образов
read -p "Удалить Docker образы бота? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${CYAN}🐳 Удаление Docker образов...${NC}"
    docker images | grep -E 'remnawave|bedolaga' | awk '{print $3}' | xargs -r docker rmi -f 2>/dev/null || true
    echo -e "${GREEN}✅ Docker образы удалены${NC}"
fi

# Удаление Docker volumes
read -p "Удалить Docker volumes (данные PostgreSQL и Redis)? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${CYAN}💾 Удаление Docker volumes...${NC}"
    docker volume ls | grep -E 'remnawave|bedolaga|postgres|redis' | awk '{print $2}' | xargs -r docker volume rm 2>/dev/null || true
    echo -e "${GREEN}✅ Docker volumes удалены${NC}"
fi

# Удаление файлов
read -p "Удалить директорию $INSTALL_DIR? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${CYAN}📁 Удаление файлов...${NC}"
    rm -rf "$INSTALL_DIR"
    echo -e "${GREEN}✅ Директория удалена${NC}"
fi

echo
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     ✅ REMNAWAVE BEDOLAGA BOT УДАЛЕН                         ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo

if [[ $REPLY =~ ^[Yy]$ ]] && [ -f "/root/$BACKUP_NAME" ]; then
    echo -e "${YELLOW}📦 Бэкап сохранен: /root/$BACKUP_NAME${NC}"
fi

echo -e "${CYAN}Спасибо за использование Bedolaga Bot!${NC}"
