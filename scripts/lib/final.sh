#!/bin/bash

# ===============================================
# 🏁 ФИНАЛЬНЫЕ ФУНКЦИИ
# ===============================================

# Копирование скриптов установщика в директорию бота
copy_installer_scripts() {
    print_info "Сохранение скриптов установщика..."
    
    local INSTALLER_DIR="$INSTALL_DIR/.installer"
    mkdir -p "$INSTALLER_DIR"
    
    # Определяем откуда копировать (откуда запущен install.sh)
    local SCRIPT_SOURCE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    
    if [ -d "$SCRIPT_SOURCE" ] && [ -f "$SCRIPT_SOURCE/install.sh" ]; then
        cp -r "$SCRIPT_SOURCE"/* "$INSTALLER_DIR/" 2>/dev/null
        chmod +x "$INSTALLER_DIR"/*.sh 2>/dev/null
        chmod +x "$INSTALLER_DIR"/lib/*.sh 2>/dev/null
        print_success "Скрипты установщика сохранены в $INSTALLER_DIR"
    else
        print_warning "Не удалось скопировать скрипты установщика"
    fi
}

# Создание глобальной команды 'bot' с интерактивным меню
create_management_scripts() {
    print_step "Создание команды управления ботом"
    
    cd "$INSTALL_DIR"
    
    # Копируем скрипты установщика
    copy_installer_scripts
    
    # Определяем compose файл для записи в скрипт
    local compose_file="docker-compose.yml"
    if [ -f "docker-compose.local.yml" ]; then
        compose_file="docker-compose.local.yml"
    fi
    
    # Создаём единый скрипт управления в /usr/local/bin/bot
    cat > /usr/local/bin/bot << 'BOTSCRIPT'
#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# 🤖 REMNAWAVE BEDOLAGA BOT - КОМАНДА УПРАВЛЕНИЯ
# ═══════════════════════════════════════════════════════════════

INSTALL_DIR="__INSTALL_DIR__"
COMPOSE_FILE="__COMPOSE_FILE__"
INSTALLER_DIR="__INSTALL_DIR__/.installer"

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m'

# Проверка директории
check_install_dir() {
    if [ ! -d "$INSTALL_DIR" ]; then
        echo -e "${RED}❌ Директория бота не найдена: $INSTALL_DIR${NC}"
        echo -e "${YELLOW}Возможно бот был удалён или перемещён${NC}"
        exit 1
    fi
    cd "$INSTALL_DIR"
}

# ═══════════════════════════════════════════════════════════════
# ФУНКЦИИ УПРАВЛЕНИЯ
# ═══════════════════════════════════════════════════════════════

do_logs() {
    check_install_dir
    echo -e "${CYAN}📋 Логи бота (Ctrl+C для выхода)...${NC}"
    docker compose -f "$COMPOSE_FILE" logs -f --tail=150 bot
}

do_status() {
    check_install_dir
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}📊 СТАТУС КОНТЕЙНЕРОВ${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo
    docker compose -f "$COMPOSE_FILE" ps
    echo
    echo -e "${WHITE}📈 Использование ресурсов:${NC}"
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" 2>/dev/null | grep -E "remnawave|postgres|redis" || echo "Контейнеры не запущены"
}

do_restart() {
    check_install_dir
    echo -e "${CYAN}🔄 Перезапуск бота...${NC}"
    docker compose -f "$COMPOSE_FILE" restart
    echo -e "${GREEN}✅ Бот перезапущен${NC}"
}

do_start() {
    check_install_dir
    echo -e "${CYAN}▶️  Запуск бота...${NC}"
    docker compose -f "$COMPOSE_FILE" up -d
    echo -e "${GREEN}✅ Бот запущен${NC}"
}

do_stop() {
    check_install_dir
    echo -e "${CYAN}⏹️  Остановка бота...${NC}"
    docker compose -f "$COMPOSE_FILE" down
    echo -e "${GREEN}✅ Бот остановлен${NC}"
}

do_update() {
    check_install_dir
    echo -e "${CYAN}📦 Обновление бота...${NC}"
    
    # Создаём бэкап .env перед обновлением
    cp .env ".env.backup_$(date +%Y%m%d_%H%M%S)" 2>/dev/null
    
    echo -e "${CYAN}1/4 Получение обновлений...${NC}"
    git pull origin main
    
    echo -e "${CYAN}2/4 Остановка контейнеров...${NC}"
    docker compose -f "$COMPOSE_FILE" down
    
    echo -e "${CYAN}3/4 Пересборка образов...${NC}"
    docker compose -f "$COMPOSE_FILE" build --no-cache
    
    echo -e "${CYAN}4/4 Запуск обновлённого бота...${NC}"
    docker compose -f "$COMPOSE_FILE" up -d
    
    echo -e "${GREEN}✅ Обновление завершено${NC}"
}

do_backup() {
    check_install_dir
    local BACKUP_DIR="$INSTALL_DIR/data/backups"
    local TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    mkdir -p "$BACKUP_DIR"
    
    echo -e "${CYAN}💾 Создание резервной копии...${NC}"
    
    # Бэкап базы данных
    echo -e "  ${WHITE}→ База данных...${NC}"
    docker compose -f "$COMPOSE_FILE" exec -T postgres pg_dump -U remnawave_user remnawave_bot > "$BACKUP_DIR/db_$TIMESTAMP.sql" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo -e "  ${GREEN}✅ db_$TIMESTAMP.sql${NC}"
    else
        echo -e "  ${RED}❌ Ошибка бэкапа БД${NC}"
    fi
    
    # Бэкап .env
    echo -e "  ${WHITE}→ Конфигурация...${NC}"
    cp .env "$BACKUP_DIR/.env_$TIMESTAMP"
    echo -e "  ${GREEN}✅ .env_$TIMESTAMP${NC}"
    
    echo
    echo -e "${GREEN}✅ Бэкап создан: $BACKUP_DIR${NC}"
    
    # Показываем размер бэкапов
    echo -e "${WHITE}📁 Размер бэкапов:${NC}"
    du -sh "$BACKUP_DIR" 2>/dev/null
}

do_health() {
    check_install_dir
    
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║           🏥 ДИАГНОСТИКА СИСТЕМЫ 🏥                          ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    
    echo -e "${WHITE}🐳 Статус контейнеров:${NC}"
    docker compose -f "$COMPOSE_FILE" ps
    echo
    
    echo -e "${WHITE}📊 Проверка сервисов:${NC}"
    
    # Bot
    if docker ps --format '{{.Names}}' | grep -q "remnawave_bot"; then
        echo -e "  ${GREEN}✅ Bot: работает${NC}"
    else
        echo -e "  ${RED}❌ Bot: не запущен${NC}"
    fi
    
    # PostgreSQL
    if docker compose -f "$COMPOSE_FILE" exec -T postgres pg_isready -U remnawave_user -d remnawave_bot >/dev/null 2>&1; then
        echo -e "  ${GREEN}✅ PostgreSQL: работает${NC}"
    else
        echo -e "  ${RED}❌ PostgreSQL: не отвечает${NC}"
    fi
    
    # Redis
    if docker compose -f "$COMPOSE_FILE" exec -T redis redis-cli ping >/dev/null 2>&1; then
        echo -e "  ${GREEN}✅ Redis: работает${NC}"
    else
        echo -e "  ${RED}❌ Redis: не отвечает${NC}"
    fi
    
    # Health endpoint
    local health_code=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/health 2>/dev/null)
    if [ "$health_code" = "200" ]; then
        echo -e "  ${GREEN}✅ Health endpoint: доступен${NC}"
    else
        echo -e "  ${YELLOW}⚠️  Health endpoint: недоступен (код: $health_code)${NC}"
    fi
    
    echo
    echo -e "${WHITE}📈 Использование ресурсов:${NC}"
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" 2>/dev/null | grep -E "remnawave|postgres|redis|NAME"
    
    echo
    echo -e "${WHITE}💾 Место на диске:${NC}"
    df -h "$INSTALL_DIR" 2>/dev/null | tail -1
    
    echo
    echo -e "${WHITE}📋 Последние 10 строк логов:${NC}"
    docker compose -f "$COMPOSE_FILE" logs --tail=10 bot 2>/dev/null
    
    echo
    echo -e "${GREEN}✅ Диагностика завершена${NC}"
}

do_config() {
    check_install_dir
    local ENV_FILE="$INSTALL_DIR/.env"
    
    get_env_value() {
        grep "^$1=" "$ENV_FILE" 2>/dev/null | cut -d'=' -f2- | tr -d '"' | tr -d "'"
    }
    
    set_env_value() {
        local key=$1
        local value=$2
        if grep -q "^$key=" "$ENV_FILE" 2>/dev/null; then
            sed -i "s|^$key=.*|$key=$value|" "$ENV_FILE"
        else
            echo "$key=$value" >> "$ENV_FILE"
        fi
    }
    
    while true; do
        clear
        echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${PURPLE}║           ⚙️  НАСТРОЙКИ БОТА ⚙️                                ║${NC}"
        echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo
        echo -e "${WHITE}Текущая конфигурация:${NC}"
        echo -e "  BOT_TOKEN:    ${CYAN}$(get_env_value BOT_TOKEN | head -c 25)...${NC}"
        echo -e "  ADMIN_IDS:    ${CYAN}$(get_env_value ADMIN_IDS)${NC}"
        echo -e "  API_URL:      ${CYAN}$(get_env_value REMNAWAVE_API_URL)${NC}"
        echo -e "  BOT_RUN_MODE: ${CYAN}$(get_env_value BOT_RUN_MODE)${NC}"
        echo
        echo -e "${WHITE}Выберите действие:${NC}"
        echo -e "  ${CYAN}1)${NC} Изменить BOT_TOKEN"
        echo -e "  ${CYAN}2)${NC} Изменить ADMIN_IDS"
        echo -e "  ${CYAN}3)${NC} Изменить REMNAWAVE_API_KEY"
        echo -e "  ${CYAN}4)${NC} Изменить REMNAWAVE_API_URL"
        echo -e "  ${CYAN}5)${NC} Открыть .env в редакторе"
        echo -e "  ${CYAN}6)${NC} Перезапустить бота (применить изменения)"
        echo -e "  ${CYAN}0)${NC} Назад"
        echo
        read -p "Ваш выбор: " choice
        
        case $choice in
            1)
                read -p "Новый BOT_TOKEN (Enter для отмены): " NEW_VALUE
                if [ -n "$NEW_VALUE" ]; then
                    set_env_value "BOT_TOKEN" "$NEW_VALUE"
                    echo -e "${GREEN}✅ BOT_TOKEN обновлён${NC}"
                fi
                ;;
            2)
                read -p "Новые ADMIN_IDS (Enter для отмены): " NEW_VALUE
                if [ -n "$NEW_VALUE" ]; then
                    set_env_value "ADMIN_IDS" "$NEW_VALUE"
                    echo -e "${GREEN}✅ ADMIN_IDS обновлены${NC}"
                fi
                ;;
            3)
                read -p "Новый REMNAWAVE_API_KEY (Enter для отмены): " NEW_VALUE
                if [ -n "$NEW_VALUE" ]; then
                    set_env_value "REMNAWAVE_API_KEY" "$NEW_VALUE"
                    echo -e "${GREEN}✅ REMNAWAVE_API_KEY обновлён${NC}"
                fi
                ;;
            4)
                read -p "Новый REMNAWAVE_API_URL (Enter для отмены): " NEW_VALUE
                if [ -n "$NEW_VALUE" ]; then
                    set_env_value "REMNAWAVE_API_URL" "$NEW_VALUE"
                    echo -e "${GREEN}✅ REMNAWAVE_API_URL обновлён${NC}"
                fi
                ;;
            5)
                ${EDITOR:-nano} "$ENV_FILE"
                ;;
            6)
                do_restart
                ;;
            0)
                return
                ;;
            *)
                echo -e "${RED}Неверный выбор${NC}"
                ;;
        esac
        
        [ "$choice" != "0" ] && read -p "Нажмите Enter..."
    done
}

update_installer_scripts() {
    echo -e "${CYAN}📥 Обновление скриптов установщика...${NC}"
    local TEMP_DIR=$(mktemp -d)
    
    git clone --depth 1 https://github.com/wrx861/bedolaga_auto_install.git "$TEMP_DIR" 2>/dev/null
    
    if [ -d "$TEMP_DIR/scripts" ]; then
        # Бэкап старой версии
        if [ -d "$INSTALLER_DIR" ]; then
            mv "$INSTALLER_DIR" "${INSTALLER_DIR}.backup_$(date +%Y%m%d_%H%M%S)" 2>/dev/null
        fi
        
        # Копируем новую версию
        cp -r "$TEMP_DIR/scripts" "$INSTALLER_DIR"
        chmod +x "$INSTALLER_DIR"/*.sh 2>/dev/null
        chmod +x "$INSTALLER_DIR"/lib/*.sh 2>/dev/null
        
        local NEW_VERSION=$(cat "$INSTALLER_DIR/VERSION" 2>/dev/null || echo "?")
        echo -e "${GREEN}✅ Обновлено до версии $NEW_VERSION${NC}"
        
        # Удаляем старые бэкапы (оставляем последние 3)
        ls -dt "${INSTALLER_DIR}.backup_"* 2>/dev/null | tail -n +4 | xargs -r rm -rf
    else
        echo -e "${RED}❌ Ошибка обновления${NC}"
    fi
    
    rm -rf "$TEMP_DIR"
}

show_changelog() {
    echo -e "${CYAN}📋 История изменений:${NC}"
    echo "─────────────────────────────────────────────────────────────"
    local CHANGELOG=$(curl -fsSL --connect-timeout 5 https://raw.githubusercontent.com/wrx861/bedolaga_auto_install/main/CHANGELOG.md 2>/dev/null)
    if [ -n "$CHANGELOG" ]; then
        echo "$CHANGELOG" | head -40
    else
        echo "Не удалось загрузить changelog"
    fi
    echo "─────────────────────────────────────────────────────────────"
}

check_installer_updates() {
    echo -e "${CYAN}🔍 Проверка обновлений установщика...${NC}"
    echo
    
    # Получаем локальную версию
    local LOCAL_VERSION="0.0.0"
    if [ -f "$INSTALLER_DIR/VERSION" ]; then
        LOCAL_VERSION=$(cat "$INSTALLER_DIR/VERSION")
    fi
    
    # Получаем версию с GitHub
    local REMOTE_VERSION=$(curl -fsSL https://raw.githubusercontent.com/wrx861/bedolaga_auto_install/main/scripts/VERSION 2>/dev/null)
    
    if [ -z "$REMOTE_VERSION" ]; then
        echo -e "${RED}❌ Не удалось получить версию с GitHub${NC}"
        return 1
    fi
    
    echo -e "${WHITE}Локальная версия:  ${CYAN}$LOCAL_VERSION${NC}"
    echo -e "${WHITE}Версия на GitHub:  ${CYAN}$REMOTE_VERSION${NC}"
    echo
    
    # Сравниваем версии
    if [ "$LOCAL_VERSION" = "$REMOTE_VERSION" ]; then
        echo -e "${GREEN}✅ У вас актуальная версия установщика${NC}"
        return 0
    fi
    
    # Есть обновление - показываем changelog
    echo -e "${YELLOW}📦 Доступно обновление!${NC}"
    echo
    
    # Пробуем получить changelog
    local CHANGELOG=$(curl -fsSL https://raw.githubusercontent.com/wrx861/bedolaga_auto_install/main/CHANGELOG.md 2>/dev/null | head -50)
    if [ -n "$CHANGELOG" ]; then
        echo -e "${WHITE}Изменения:${NC}"
        echo "─────────────────────────────────────────────────────────"
        echo "$CHANGELOG" | head -30
        echo "─────────────────────────────────────────────────────────"
        echo
    fi
    
    read -p "Обновить установщик до версии $REMOTE_VERSION? (y/n) [y]: " -n 1 -r
    echo
    REPLY=${REPLY:-y}
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${CYAN}📥 Обновление скриптов...${NC}"
        local TEMP_DIR=$(mktemp -d)
        
        git clone --depth 1 https://github.com/wrx861/bedolaga_auto_install.git "$TEMP_DIR" 2>/dev/null
        
        if [ -d "$TEMP_DIR/scripts" ]; then
            # Бэкап старой версии
            if [ -d "$INSTALLER_DIR" ]; then
                mv "$INSTALLER_DIR" "${INSTALLER_DIR}.backup_$(date +%Y%m%d_%H%M%S)"
            fi
            
            # Копируем новую версию
            cp -r "$TEMP_DIR/scripts" "$INSTALLER_DIR"
            chmod +x "$INSTALLER_DIR"/*.sh 2>/dev/null
            chmod +x "$INSTALLER_DIR"/lib/*.sh 2>/dev/null
            
            echo -e "${GREEN}✅ Установщик обновлён до версии $REMOTE_VERSION${NC}"
            
            # Удаляем старые бэкапы (оставляем последние 3)
            ls -dt "${INSTALLER_DIR}.backup_"* 2>/dev/null | tail -n +4 | xargs -r rm -rf
        else
            echo -e "${RED}❌ Ошибка обновления${NC}"
        fi
        
        rm -rf "$TEMP_DIR"
    else
        echo -e "${YELLOW}Обновление отменено${NC}"
    fi
}

do_install() {
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║           🔧 УСТАНОВЩИК БОТА 🔧                              ║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    
    # Проверяем наличие локальных скриптов установщика
    if [ -d "$INSTALLER_DIR" ] && [ -f "$INSTALLER_DIR/install.sh" ]; then
        # Получаем локальную версию
        local LOCAL_VERSION="0.0.0"
        if [ -f "$INSTALLER_DIR/VERSION" ]; then
            LOCAL_VERSION=$(cat "$INSTALLER_DIR/VERSION")
        fi
        
        echo -e "${GREEN}✅ Найдены локальные скрипты установщика${NC}"
        echo -e "${WHITE}Версия: ${CYAN}$LOCAL_VERSION${NC}"
        echo
        
        # Проверяем обновления
        echo -e "${CYAN}🔍 Проверка обновлений...${NC}"
        local REMOTE_VERSION=$(curl -fsSL --connect-timeout 5 https://raw.githubusercontent.com/wrx861/bedolaga_auto_install/main/scripts/VERSION 2>/dev/null)
        
        if [ -n "$REMOTE_VERSION" ] && [ "$LOCAL_VERSION" != "$REMOTE_VERSION" ]; then
            echo -e "${YELLOW}📦 Доступна новая версия: ${WHITE}$REMOTE_VERSION${NC}"
            echo
            echo -e "${WHITE}Варианты:${NC}"
            echo -e "  ${CYAN}1)${NC} Обновить и запустить (рекомендуется)"
            echo -e "  ${CYAN}2)${NC} Запустить текущую версию ($LOCAL_VERSION)"
            echo -e "  ${CYAN}3)${NC} Посмотреть изменения"
            echo -e "  ${CYAN}0)${NC} Отмена"
            echo
            read -p "Ваш выбор [1]: " choice
            choice=${choice:-1}
            
            case $choice in
                1)
                    update_installer_scripts
                    echo -e "${CYAN}🚀 Запуск установщика...${NC}"
                    sudo bash "$INSTALLER_DIR/install.sh"
                    ;;
                2)
                    echo -e "${CYAN}🚀 Запуск установщика v$LOCAL_VERSION...${NC}"
                    sudo bash "$INSTALLER_DIR/install.sh"
                    ;;
                3)
                    show_changelog
                    read -p "Нажмите Enter..."
                    do_install  # Вернуться в меню
                    ;;
                0)
                    return
                    ;;
            esac
        else
            echo -e "${GREEN}✅ У вас актуальная версия${NC}"
            echo
            echo -e "${WHITE}Варианты:${NC}"
            echo -e "  ${CYAN}1)${NC} Запустить установщик"
            echo -e "  ${CYAN}2)${NC} Принудительно скачать с GitHub"
            echo -e "  ${CYAN}0)${NC} Отмена"
            echo
            read -p "Ваш выбор [1]: " choice
            choice=${choice:-1}
            
            case $choice in
                1)
                    echo -e "${CYAN}🚀 Запуск установщика...${NC}"
                    sudo bash "$INSTALLER_DIR/install.sh"
                    ;;
                2)
                    echo -e "${CYAN}📥 Скачивание с GitHub...${NC}"
                    curl -fsSL https://raw.githubusercontent.com/wrx861/bedolaga_auto_install/main/scripts/quick-install.sh | sudo bash
                    ;;
                0)
                    return
                    ;;
            esac
        fi
    else
        echo -e "${YELLOW}⚠️  Локальные скрипты установщика не найдены${NC}"
        echo
        echo -e "${WHITE}Варианты:${NC}"
        echo -e "  ${CYAN}1)${NC} Скачать и запустить установщик с GitHub"
        echo -e "  ${CYAN}2)${NC} Скачать скрипты локально (без запуска)"
        echo -e "  ${CYAN}0)${NC} Отмена"
        echo
        read -p "Ваш выбор [1]: " choice
        choice=${choice:-1}
        
        case $choice in
            1)
                echo -e "${CYAN}📥 Скачивание с GitHub...${NC}"
                curl -fsSL https://raw.githubusercontent.com/wrx861/bedolaga_auto_install/main/scripts/quick-install.sh | sudo bash
                ;;
            2)
                echo -e "${CYAN}📥 Скачивание скриптов...${NC}"
                mkdir -p "$INSTALLER_DIR"
                local TEMP_DIR=$(mktemp -d)
                git clone --depth 1 https://github.com/wrx861/bedolaga_auto_install.git "$TEMP_DIR" 2>/dev/null
                if [ -d "$TEMP_DIR/scripts" ]; then
                    cp -r "$TEMP_DIR/scripts"/* "$INSTALLER_DIR/"
                    chmod +x "$INSTALLER_DIR"/*.sh 2>/dev/null
                    chmod +x "$INSTALLER_DIR"/lib/*.sh 2>/dev/null
                    echo -e "${GREEN}✅ Скрипты сохранены в $INSTALLER_DIR${NC}"
                else
                    echo -e "${RED}❌ Ошибка загрузки${NC}"
                fi
                rm -rf "$TEMP_DIR"
                ;;
            0)
                return
                ;;
            *)
                echo -e "${RED}Неверный выбор${NC}"
                ;;
        esac
    fi
}

do_uninstall() {
    check_install_dir
    
    echo -e "${RED}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║           🗑️  УДАЛЕНИЕ БОТА 🗑️                                ║${NC}"
    echo -e "${RED}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${YELLOW}⚠️  ВНИМАНИЕ! Это действие удалит:${NC}"
    echo -e "   - Docker контейнеры бота"
    echo -e "   - Данные PostgreSQL и Redis (опционально)"
    echo
    
    read -p "Введите 'yes' для подтверждения: " CONFIRM
    if [ "$CONFIRM" != "yes" ]; then
        echo -e "${GREEN}Удаление отменено${NC}"
        return
    fi
    
    echo -e "${CYAN}🛑 Остановка контейнеров...${NC}"
    docker compose -f "$COMPOSE_FILE" down
    
    read -p "Удалить данные (volumes)? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${CYAN}💾 Удаление volumes...${NC}"
        docker compose -f "$COMPOSE_FILE" down -v
        docker volume ls -q | grep -E "bedolaga|remnawave.*bot" | xargs -r docker volume rm 2>/dev/null
        echo -e "${GREEN}✅ Volumes удалены${NC}"
    fi
    
    # Удаление глобальной команды
    if [ -f "/usr/local/bin/bot" ]; then
        rm -f /usr/local/bin/bot
        echo -e "${GREEN}✅ Команда 'bot' удалена${NC}"
    fi
    
    echo
    echo -e "${GREEN}✅ Удаление завершено${NC}"
    echo -e "${YELLOW}Директория $INSTALL_DIR оставлена. Удалите вручную:${NC}"
    echo -e "${CYAN}rm -rf $INSTALL_DIR${NC}"
}

# ═══════════════════════════════════════════════════════════════
# ИНТЕРАКТИВНОЕ МЕНЮ
# ═══════════════════════════════════════════════════════════════

show_menu() {
    clear
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║        🤖 REMNAWAVE BEDOLAGA BOT — УПРАВЛЕНИЕ 🤖             ║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${WHITE}Директория:${NC} ${CYAN}$INSTALL_DIR${NC}"
    echo
    
    # Быстрый статус
    if docker ps --format '{{.Names}}' | grep -q "remnawave_bot"; then
        echo -e "${WHITE}Статус:${NC} ${GREEN}● Бот работает${NC}"
    else
        echo -e "${WHITE}Статус:${NC} ${RED}○ Бот остановлен${NC}"
    fi
    echo
    
    echo -e "${WHITE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}Выберите действие:${NC}"
    echo
    echo -e "  ${CYAN}1)${NC} 📋 Логи              ${CYAN}6)${NC} 💾 Создать бэкап"
    echo -e "  ${CYAN}2)${NC} 📊 Статус            ${CYAN}7)${NC} 🏥 Диагностика"
    echo -e "  ${CYAN}3)${NC} 🔄 Перезапуск        ${CYAN}8)${NC} ⚙️  Настройки"
    echo -e "  ${CYAN}4)${NC} ▶️  Запуск            ${CYAN}9)${NC} 📦 Обновить бота"
    echo -e "  ${CYAN}5)${NC} ⏹️  Остановка"
    echo
    echo -e "  ${CYAN}i)${NC} 🔧 Установщик        ${CYAN}0)${NC} 🗑️  Удаление"
    echo -e "  ${CYAN}q)${NC} Выход"
    echo
}

interactive_menu() {
    while true; do
        show_menu
        read -p "Ваш выбор: " choice
        
        case $choice in
            1) do_logs ;;
            2) do_status; read -p "Нажмите Enter..." ;;
            3) do_restart; read -p "Нажмите Enter..." ;;
            4) do_start; read -p "Нажмите Enter..." ;;
            5) do_stop; read -p "Нажмите Enter..." ;;
            6) do_backup; read -p "Нажмите Enter..." ;;
            7) do_health; read -p "Нажмите Enter..." ;;
            8) do_config ;;
            9) do_update; read -p "Нажмите Enter..." ;;
            i|I|install) do_install; read -p "Нажмите Enter..." ;;
            0) do_uninstall; break ;;
            q|Q|exit) echo -e "${GREEN}До свидания!${NC}"; exit 0 ;;
            *) echo -e "${RED}Неверный выбор${NC}"; sleep 1 ;;
        esac
    done
}

show_help() {
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║        🤖 REMNAWAVE BEDOLAGA BOT — СПРАВКА 🤖                ║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${WHITE}Использование:${NC}"
    echo -e "  ${CYAN}bot${NC}              — Интерактивное меню"
    echo -e "  ${CYAN}bot <команда>${NC}   — Выполнить команду напрямую"
    echo
    echo -e "${WHITE}Команды:${NC}"
    echo -e "  ${GREEN}logs${NC}       — Просмотр логов бота"
    echo -e "  ${GREEN}status${NC}     — Статус контейнеров"
    echo -e "  ${GREEN}restart${NC}    — Перезапуск бота"
    echo -e "  ${GREEN}start${NC}      — Запуск бота"
    echo -e "  ${GREEN}stop${NC}       — Остановка бота"
    echo -e "  ${GREEN}update${NC}     — Обновление бота (git pull + rebuild)"
    echo -e "  ${GREEN}backup${NC}     — Создание резервной копии"
    echo -e "  ${GREEN}health${NC}     — Диагностика системы"
    echo -e "  ${GREEN}config${NC}     — Изменение настроек"
    echo -e "  ${GREEN}install${NC}    — Запустить установщик (переустановка)"
    echo -e "  ${GREEN}uninstall${NC}  — Удаление бота"
    echo
    echo -e "${WHITE}Директория бота:${NC} $INSTALL_DIR"
    echo -e "${WHITE}Скрипты установщика:${NC} $INSTALLER_DIR"
}

# ═══════════════════════════════════════════════════════════════
# ТОЧКА ВХОДА
# ═══════════════════════════════════════════════════════════════

case "$1" in
    logs)       do_logs ;;
    status)     do_status ;;
    restart)    do_restart ;;
    start)      do_start ;;
    stop)       do_stop ;;
    update|upgrade) do_update ;;
    backup)     do_backup ;;
    health|check|diag) do_health ;;
    config|configure|settings) do_config ;;
    install|reinstall|setup) do_install ;;
    uninstall|remove) do_uninstall ;;
    help|--help|-h) show_help ;;
    "")         interactive_menu ;;
    *)
        echo -e "${RED}❌ Неизвестная команда: $1${NC}"
        echo -e "Используйте ${CYAN}bot help${NC} для справки"
        exit 1
        ;;
esac
BOTSCRIPT
    
    # Заменяем плейсхолдеры на реальные значения
    sed -i "s|__INSTALL_DIR__|$INSTALL_DIR|g" /usr/local/bin/bot
    sed -i "s|__COMPOSE_FILE__|$compose_file|g" /usr/local/bin/bot
    
    chmod +x /usr/local/bin/bot
    
    print_success "Команда управления 'bot' создана"
    echo
    echo -e "${GREEN}🎉 Теперь вы можете управлять ботом командой:${NC}"
    echo -e "   ${WHITE}bot${NC}        — интерактивное меню"
    echo -e "   ${WHITE}bot help${NC}   — справка по командам"
}

# Вывод финальной информации
print_final_info() {
    print_step "Установка завершена!"
    
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║           🎉 УСТАНОВКА УСПЕШНО ЗАВЕРШЕНА! 🎉                 ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    echo -e "${WHITE}📁 Директория установки:${NC} ${CYAN}$INSTALL_DIR${NC}"
    echo ""
    
    echo -e "${WHITE}🎮 Управление ботом:${NC}"
    echo -e "   ${CYAN}bot${NC}          — интерактивное меню управления"
    echo -e "   ${CYAN}bot help${NC}     — справка по всем командам"
    echo -e "   ${CYAN}bot logs${NC}     — просмотр логов"
    echo -e "   ${CYAN}bot status${NC}   — статус контейнеров"
    echo -e "   ${CYAN}bot install${NC}  — запустить установщик"
    echo ""
    
    if [ -n "$WEBHOOK_DOMAIN" ]; then
        echo -e "${WHITE}🌐 Webhook:${NC} https://$WEBHOOK_DOMAIN"
    fi
    
    if [ -n "$MINIAPP_DOMAIN" ]; then
        echo -e "${WHITE}📱 Mini App:${NC} https://$MINIAPP_DOMAIN"
    fi
    
    echo ""
    echo -e "${WHITE}📝 Конфигурация:${NC} $INSTALL_DIR/.env"
    echo ""
    
    echo -e "${YELLOW}⚠️  Важно:${NC}"
    echo -e "  - Настройте бота в Telegram через @BotFather"
    if [ "$PANEL_INSTALLED_LOCALLY" != "true" ] && [ -n "$REMNAWAVE_SECRET_KEY" ]; then
        echo -e "  - Убедитесь что REMNAWAVE_SECRET_KEY совпадает с панелью eGames"
    fi
    if [ "$KEEP_EXISTING_VOLUMES" = "true" ] && [ -n "$OLD_POSTGRES_PASSWORD" ]; then
        echo -e "  - ${GREEN}Данные PostgreSQL сохранены, пароль восстановлен из старого .env${NC}"
    else
        echo -e "  - Сохраните пароль PostgreSQL из файла .env"
    fi
    echo ""
}

# Показ логов
ask_show_logs() {
    echo
    if confirm "Показать логи бота?"; then
        print_info "Показываем последние 150 строк логов (Ctrl+C для выхода)..."
        sleep 2
        cd "$INSTALL_DIR"
        if [ -f "docker-compose.local.yml" ]; then
            docker compose -f docker-compose.local.yml logs --tail=150 -f bot
        else
            docker compose logs --tail=150 -f bot
        fi
    fi
}
