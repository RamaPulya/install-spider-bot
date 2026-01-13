#!/bin/bash

# ===============================================
# 🏥 REMNAWAVE BEDOLAGA BOT - ПРОВЕРКА ЗДОРОВЬЯ
# ===============================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Автоопределение директории установки
if [ -d "/opt/remnawave-bedolaga-telegram-bot" ]; then
    INSTALL_DIR="/opt/remnawave-bedolaga-telegram-bot"
elif [ -d "/root/remnawave-bedolaga-telegram-bot" ]; then
    INSTALL_DIR="/root/remnawave-bedolaga-telegram-bot"
else
    if [ -f "./docker-compose.yml" ] && [ -f "./main.py" ]; then
        INSTALL_DIR="$(pwd)"
    else
        echo -e "${RED}❌ Бот не установлен!${NC}"
        exit 1
    fi
fi

echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║     🏥 REMNAWAVE BEDOLAGA BOT - ПРОВЕРКА ЗДОРОВЬЯ 🏥         ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${CYAN}📁 Директория: $INSTALL_DIR${NC}"
echo

cd "$INSTALL_DIR"

echo -e "${CYAN}🐳 Статус Docker контейнеров:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
docker compose ps
echo

# Проверка каждого контейнера
echo -e "${CYAN}📊 Детальная информация:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Bot
BOT_STATUS=$(docker compose ps -q bot 2>/dev/null)
if [ -n "$BOT_STATUS" ]; then
    BOT_STATE=$(docker inspect --format='{{.State.Status}}' "$BOT_STATUS" 2>/dev/null || echo "unknown")
    if [ "$BOT_STATE" == "running" ]; then
        echo -e "${GREEN}✅ Bot: Работает${NC}"
    else
        echo -e "${RED}❌ Bot: $BOT_STATE${NC}"
    fi
else
    echo -e "${RED}❌ Bot: Не найден${NC}"
fi

# PostgreSQL
PG_STATUS=$(docker compose ps -q postgres 2>/dev/null)
if [ -n "$PG_STATUS" ]; then
    PG_STATE=$(docker inspect --format='{{.State.Status}}' "$PG_STATUS" 2>/dev/null || echo "unknown")
    if [ "$PG_STATE" == "running" ]; then
        # Проверка подключения к БД
        if docker compose exec -T postgres pg_isready -U remnawave_user -d remnawave_bot >/dev/null 2>&1; then
            echo -e "${GREEN}✅ PostgreSQL: Работает и принимает подключения${NC}"
        else
            echo -e "${YELLOW}⚠️ PostgreSQL: Работает, но не принимает подключения${NC}"
        fi
    else
        echo -e "${RED}❌ PostgreSQL: $PG_STATE${NC}"
    fi
else
    echo -e "${RED}❌ PostgreSQL: Не найден${NC}"
fi

# Redis
REDIS_STATUS=$(docker compose ps -q redis 2>/dev/null)
if [ -n "$REDIS_STATUS" ]; then
    REDIS_STATE=$(docker inspect --format='{{.State.Status}}' "$REDIS_STATUS" 2>/dev/null || echo "unknown")
    if [ "$REDIS_STATE" == "running" ]; then
        # Проверка подключения к Redis
        if docker compose exec -T redis redis-cli ping >/dev/null 2>&1; then
            echo -e "${GREEN}✅ Redis: Работает и отвечает${NC}"
        else
            echo -e "${YELLOW}⚠️ Redis: Работает, но не отвечает${NC}"
        fi
    else
        echo -e "${RED}❌ Redis: $REDIS_STATE${NC}"
    fi
else
    echo -e "${RED}❌ Redis: Не найден${NC}"
fi

echo

# Проверка HTTP эндпоинтов
echo -e "${CYAN}🌐 Проверка HTTP эндпоинтов:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Локальный health check
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/health 2>/dev/null | grep -q "200\|401"; then
    echo -e "${GREEN}✅ Health endpoint: Доступен (localhost:8080/health)${NC}"
else
    echo -e "${RED}❌ Health endpoint: Недоступен${NC}"
fi

echo

# Использование ресурсов
echo -e "${CYAN}📈 Использование ресурсов:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"

echo

# Место на диске
echo -e "${CYAN}💾 Место на диске:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
df -h / | tail -1 | awk '{print "Использовано: " $3 " из " $2 " (" $5 ")"}'

echo

# Последние логи
echo -e "${CYAN}📋 Последние логи бота (5 строк):${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
docker compose logs --tail=5 bot 2>/dev/null || echo "Логи недоступны"

echo
echo -e "${GREEN}✅ Проверка завершена${NC}"
