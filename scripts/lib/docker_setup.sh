#!/bin/bash

# ===============================================
# 🐳 DOCKER НАСТРОЙКА И УПРАВЛЕНИЕ
# ===============================================

# Клонирование репозитория
clone_repository() {
    print_step "Клонирование репозитория"
    
    if [ -d "$INSTALL_DIR" ]; then
        print_warning "Директория $INSTALL_DIR уже существует"
        if confirm "Удалить и клонировать заново?"; then
            rm -rf "$INSTALL_DIR"
        else
            print_info "Используем существующую директорию"
            cd "$INSTALL_DIR"
            if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
                git remote set-url origin "$REPO_URL" 2>/dev/null || true
                if [ -n "$REPO_BRANCH" ]; then
                    git fetch origin "$REPO_BRANCH" 2>/dev/null || true
                    git checkout "$REPO_BRANCH" 2>/dev/null || git checkout -b "$REPO_BRANCH" "origin/$REPO_BRANCH" 2>/dev/null || true
                    git pull origin "$REPO_BRANCH" || true
                else
                    git pull origin main || true
                fi
            else
                print_warning "Текущая директория не является git-репозиторием. Обновление пропущено."
            fi
            return
        fi
    fi
    
    if [ -n "$REPO_BRANCH" ]; then
        git clone --depth 1 --single-branch --branch "$REPO_BRANCH" "$REPO_URL" "$INSTALL_DIR"
    else
        git clone "$REPO_URL" "$INSTALL_DIR"
    fi
    cd "$INSTALL_DIR"
    print_success "Репозиторий клонирован в $INSTALL_DIR"
}

# Создание необходимых директорий
create_directories() {
    print_step "Создание директорий"
    
    cd "$INSTALL_DIR"
    mkdir -p ./logs ./data ./data/backups ./data/referral_qr ./locales
    chmod -R 755 ./logs ./data ./locales
    chown -R 1000:1000 ./logs ./data ./locales 2>/dev/null || true
    
    print_success "Директории созданы"
}

# Проверка существующего volume PostgreSQL
check_postgres_volume() {
    # Сбрасываем флаги
    export KEEP_EXISTING_VOLUMES="false"
    export OLD_POSTGRES_PASSWORD=""
    
    # ВАЖНО: Сохраняем пароль из существующего .env ДО git clone!
    if [ -f "$INSTALL_DIR/.env" ]; then
        OLD_POSTGRES_PASSWORD=$(grep "^POSTGRES_PASSWORD=" "$INSTALL_DIR/.env" 2>/dev/null | cut -d'=' -f2- | tr -d '"' | tr -d "'")
        if [ -n "$OLD_POSTGRES_PASSWORD" ]; then
            print_info "Сохранён пароль PostgreSQL из существующего .env"
        fi
    fi
    
    # Ищем ВСЕ postgres volumes связанные с ботом
    local found_volumes=$(docker volume ls -q 2>/dev/null | grep -E "(postgres|bot)" | grep -v "remnawave_postgres" || true)
    
    # Также проверяем по известным именам
    local project_name=$(basename "$INSTALL_DIR" | tr '[:upper:]' '[:lower:]' | tr -dc 'a-z0-9')
    local known_volumes=(
        "${project_name}_postgres_data"
        "remnawave-bedolaga-telegram-bot_postgres_data"
        "remnawavebedolagatelegrambot_postgres_data"
        "remnawave_bot_postgres_data"
    )
    
    for vol in "${known_volumes[@]}"; do
        if docker volume inspect "$vol" &>/dev/null; then
            found_volumes="$found_volumes $vol"
        fi
    done
    
    # Убираем дубликаты
    found_volumes=$(echo "$found_volumes" | tr ' ' '\n' | sort -u | grep -v "^$" || true)
    
    if [ -z "$found_volumes" ]; then
        print_info "Существующих postgres volumes не найдено — будет создана новая БД"
        return 0
    fi
    
    echo
    print_warning "⚠️  Обнаружены существующие Docker volumes PostgreSQL:"
    echo "$found_volumes" | while read vol; do
        [ -n "$vol" ] && echo -e "${CYAN}   - $vol${NC}"
    done
    echo
    
    # Разная логика в зависимости от того, найден ли старый пароль
    if [ -n "$OLD_POSTGRES_PASSWORD" ]; then
        # Пароль найден — можно сохранить данные
        echo -e "${GREEN}   ✅ Найден пароль PostgreSQL из старого .env${NC}"
        echo
        echo -e "${WHITE}   Варианты:${NC}"
        echo -e "${CYAN}   1)${NC} Сохранить данные (рекомендуется)"
        echo -e "${CYAN}   2)${NC} Удалить volumes и начать с чистой БД"
        echo
        read -p "   Выберите (1/2) [1]: " vol_choice < /dev/tty
        vol_choice=${vol_choice:-1}
        
        case $vol_choice in
            2)
                delete_postgres_volumes "$found_volumes"
                ;;
            *)
                print_success "Данные сохранены. Пароль PostgreSQL будет восстановлен."
                export KEEP_EXISTING_VOLUMES="true"
                ;;
        esac
    else
        # Пароль НЕ найден — данные сохранить НЕВОЗМОЖНО
        echo -e "${RED}   ❌ Пароль PostgreSQL НЕ НАЙДЕН!${NC}"
        echo -e "${YELLOW}   Без пароля невозможно подключиться к существующей базе.${NC}"
        echo -e "${YELLOW}   Volumes будут удалены для создания новой БД.${NC}"
        echo
        
        if confirm "   Удалить volumes и начать с чистой базы?"; then
            delete_postgres_volumes "$found_volumes"
        else
            echo -e "${RED}   Установка отменена. Найдите старый .env с паролем или удалите volumes вручную:${NC}"
            echo -e "${CYAN}   docker volume rm $found_volumes${NC}"
            exit 1
        fi
    fi
}

# Функция удаления volumes
delete_postgres_volumes() {
    local found_volumes="$1"
    
    print_warning "Удаление volumes..."
    
    # Используем down -v для гарантированного удаления volumes
    cd "$INSTALL_DIR" 2>/dev/null || true
    docker compose -f docker-compose.local.yml down -v 2>/dev/null || true
    docker compose down -v 2>/dev/null || true
    
    # Дополнительно удаляем volumes по имени
    echo "$found_volumes" | while read vol; do
        if [ -n "$vol" ]; then
            print_info "Удаляем: $vol"
            docker volume rm "$vol" 2>/dev/null || true
        fi
    done
    
    # Ещё раз по известным паттернам
    docker volume ls -q 2>/dev/null | grep -E "postgres.*bot|bot.*postgres" | xargs -r docker volume rm 2>/dev/null || true
    
    print_success "Volumes удалены. Будет создана новая база."
    # Флаг остаётся false — будет спрошен новый пароль
}

# Создание стандартного docker-compose.yml для отдельной установки
create_standalone_compose() {
    print_info "Создание docker-compose.yml для отдельной установки..."
    
    cat > docker-compose.yml << 'STANDALONEEOF'
services:
  postgres:
    image: postgres:15-alpine
    container_name: remnawave_bot_db
    restart: unless-stopped
    environment:
      POSTGRES_DB: ${POSTGRES_DB:-remnawave_bot}
      POSTGRES_USER: ${POSTGRES_USER:-remnawave_user}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-secure_password_123}
      POSTGRES_INITDB_ARGS: "--encoding=UTF8 --locale=C"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - bot_network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER:-remnawave_user} -d ${POSTGRES_DB:-remnawave_bot}"]
      interval: 30s
      timeout: 5s
      retries: 5
      start_period: 30s

  redis:
    image: redis:7-alpine
    container_name: remnawave_bot_redis
    restart: unless-stopped
    command: redis-server --appendonly yes --maxmemory 256mb --maxmemory-policy allkeys-lru
    volumes:
      - redis_data:/data
    networks:
      - bot_network
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 30s
      timeout: 10s
      retries: 3

  bot:
    build: .
    container_name: remnawave_bot
    restart: unless-stopped
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    env_file:
      - .env
    environment:
      DOCKER_ENV: "true"
      DATABASE_MODE: "auto"
      POSTGRES_HOST: "postgres"
      POSTGRES_PORT: "5432"
      POSTGRES_DB: "${POSTGRES_DB:-remnawave_bot}"
      POSTGRES_USER: "${POSTGRES_USER:-remnawave_user}"
      POSTGRES_PASSWORD: "${POSTGRES_PASSWORD:-secure_password_123}"
      REDIS_URL: "redis://redis:6379/0"
      TZ: "Europe/Moscow"
      LOCALES_PATH: "${LOCALES_PATH:-/app/locales}"
    volumes:
      - ./logs:/app/logs:rw
      - ./data:/app/data:rw
      - ./locales:/app/locales:rw
      - /etc/timezone:/etc/timezone:ro
      - /etc/localtime:/etc/localtime:ro
      - ./vpn_logo.png:/app/vpn_logo.png:ro
    ports:
      - "${WEB_API_PORT:-8080}:8080"
    networks:
      - bot_network
    healthcheck:
      test: ["CMD-SHELL", "wget -q --spider http://localhost:8080/health || exit 1"]
      interval: 60s
      timeout: 10s
      retries: 3
      start_period: 30s

volumes:
  postgres_data:
    driver: local
  redis_data:
    driver: local

networks:
  bot_network:
    name: remnawave_bot_network
    driver: bridge
STANDALONEEOF
    print_success "Создан docker-compose.yml для отдельной установки"
}

# Создание docker-compose.local.yml для установки с панелью
create_local_compose() {
    print_info "Создание docker-compose.local.yml для подключения к панели..."
    
    local network_name="${REMNAWAVE_DOCKER_NETWORK:-remnawave-network}"
    
    cat > docker-compose.local.yml << EOF
services:
  postgres:
    image: postgres:15-alpine
    container_name: remnawave_bot_db
    restart: unless-stopped
    environment:
      POSTGRES_DB: \${POSTGRES_DB:-remnawave_bot}
      POSTGRES_USER: \${POSTGRES_USER:-remnawave_user}
      POSTGRES_PASSWORD: \${POSTGRES_PASSWORD:-secure_password_123}
      POSTGRES_INITDB_ARGS: "--encoding=UTF8 --locale=C"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - bot_network
      - remnawave_network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U \${POSTGRES_USER:-remnawave_user} -d \${POSTGRES_DB:-remnawave_bot}"]
      interval: 30s
      timeout: 5s
      retries: 5
      start_period: 30s

  redis:
    image: redis:7-alpine
    container_name: remnawave_bot_redis
    restart: unless-stopped
    command: redis-server --appendonly yes --maxmemory 256mb --maxmemory-policy allkeys-lru
    volumes:
      - redis_data:/data
    networks:
      - bot_network
      - remnawave_network
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 30s
      timeout: 10s
      retries: 3

  bot:
    build: .
    container_name: remnawave_bot
    restart: unless-stopped
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    env_file:
      - .env
    environment:
      DOCKER_ENV: "true"
      DATABASE_MODE: "auto"
      POSTGRES_HOST: "postgres"
      POSTGRES_PORT: "5432"
      POSTGRES_DB: "\${POSTGRES_DB:-remnawave_bot}"
      POSTGRES_USER: "\${POSTGRES_USER:-remnawave_user}"
      POSTGRES_PASSWORD: "\${POSTGRES_PASSWORD:-secure_password_123}"
      REDIS_URL: "redis://redis:6379/0"
      TZ: "Europe/Moscow"
      LOCALES_PATH: "\${LOCALES_PATH:-/app/locales}"
    volumes:
      - ./logs:/app/logs:rw
      - ./data:/app/data:rw
      - ./locales:/app/locales:rw
      - /etc/timezone:/etc/timezone:ro
      - /etc/localtime:/etc/localtime:ro
      - ./vpn_logo.png:/app/vpn_logo.png:ro
    ports:
      - "\${WEB_API_PORT:-8080}:8080"
    networks:
      - bot_network
      - remnawave_network
    healthcheck:
      test: ["CMD-SHELL", "wget -q --spider http://localhost:8080/health || exit 1"]
      interval: 60s
      timeout: 10s
      retries: 3
      start_period: 30s

volumes:
  postgres_data:
    driver: local
  redis_data:
    driver: local

networks:
  bot_network:
    name: remnawave_bot_network
    driver: bridge
  remnawave_network:
    name: $network_name
    external: true
EOF
    
    # Проверяем что имя сети записалось правильно
    if grep -q "name: $network_name" docker-compose.local.yml; then
        print_success "Создан docker-compose.local.yml (сеть: $network_name)"
    else
        print_warning "Проверьте сеть в docker-compose.local.yml"
    fi
}

# Запуск Docker контейнеров
start_docker() {
    print_step "Запуск Docker контейнеров"
    
    cd "$INSTALL_DIR"
    
    # Сначала останавливаем существующие контейнеры
    print_info "Остановка существующих контейнеров..."
    docker compose down 2>/dev/null || true
    docker compose -f docker-compose.local.yml down 2>/dev/null || true
    
    # check_postgres_volume уже вызван в main() до interactive_setup
    
    # Выбор docker-compose файла
    COMPOSE_FILE="docker-compose.yml"
    
    if [ "$PANEL_INSTALLED_LOCALLY" = "true" ]; then
        # Бот на одном сервере с панелью
        print_info "Настройка подключения к сети панели Remnawave..."
        
        # Проверяем и подготавливаем сеть
        prepare_panel_network
        
        # Создаём compose для локальной установки
        create_local_compose
        COMPOSE_FILE="docker-compose.local.yml"
        print_info "Используем docker-compose.local.yml"
    else
        # Бот на отдельном сервере
        print_info "Отдельная установка бота (standalone)..."
        
        if [ ! -f "docker-compose.yml" ]; then
            print_warning "docker-compose.yml не найден, создаём..."
            create_standalone_compose
        fi
        COMPOSE_FILE="docker-compose.yml"
        print_info "Используем docker-compose.yml"
    fi
    
    # Сборка и запуск
    print_info "Запуск: docker compose -f $COMPOSE_FILE up -d --build"
    docker compose -f "$COMPOSE_FILE" up -d --build
    
    print_info "Ожидание запуска контейнеров..."
    sleep 10
    
    # Проверка статуса
    docker compose -f "$COMPOSE_FILE" ps
    
    # Принудительное подключение к сети панели после запуска
    if [ "$PANEL_INSTALLED_LOCALLY" = "true" ]; then
        ensure_network_connection
        verify_panel_connection
    fi
    
    # Создаём скрипт-обёртку для docker compose
    if [ "$COMPOSE_FILE" != "docker-compose.yml" ]; then
        cat > dc.sh << EOF
#!/bin/bash
cd "$INSTALL_DIR"
docker compose -f $COMPOSE_FILE "\$@"
EOF
        chmod +x dc.sh
        print_info "Создан скрипт dc.sh для удобного управления"
    fi
    
    print_success "Контейнеры запущены"
}

# Принудительное подключение контейнеров к сети панели
ensure_network_connection() {
    local network="${REMNAWAVE_DOCKER_NETWORK:-remnawave-network}"
    
    print_info "Проверка подключения контейнеров к сети $network..."
    
    # Пробуем найти сеть панели автоматически если указанная не найдена
    if ! docker network inspect "$network" &>/dev/null; then
        print_warning "Сеть $network не найдена, ищем сеть панели..."
        
        # Способ 1: По имени контейнера remnawave
        local panel_network=$(docker inspect remnawave --format '{{range $net, $_ := .NetworkSettings.Networks}}{{$net}}{{"\n"}}{{end}}' 2>/dev/null | grep -v "^$" | head -1)
        
        if [ -n "$panel_network" ] && [ "$panel_network" != "host" ] && [ "$panel_network" != "none" ]; then
            network="$panel_network"
            print_info "Найдена сеть панели: $network"
        else
            # Способ 2: Поиск по паттерну
            local found_net=$(docker network ls --format '{{.Name}}' | grep -i "remnawave" | grep -v "bot" | head -1)
            if [ -n "$found_net" ]; then
                network="$found_net"
                print_info "Найдена сеть: $network"
            else
                print_error "Не удалось найти сеть панели Remnawave!"
                print_info "Доступные сети:"
                docker network ls --format "  - {{.Name}}"
                return 1
            fi
        fi
    fi
    
    # Подключаем контейнеры бота к сети панели
    local containers=("remnawave_bot" "remnawave_bot_db" "remnawave_bot_redis")
    local connected=0
    
    for container in "${containers[@]}"; do
        if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
            # Проверяем, подключен ли уже
            local current_nets=$(docker inspect "$container" --format '{{range $net, $config := .NetworkSettings.Networks}}{{$net}} {{end}}' 2>/dev/null)
            
            if echo "$current_nets" | grep -q "$network"; then
                print_info "$container уже подключен к $network"
            else
                print_info "Подключаем $container к сети $network..."
                if docker network connect "$network" "$container" 2>/dev/null; then
                    print_success "$container подключен"
                    ((connected++))
                else
                    print_warning "Не удалось подключить $container"
                fi
            fi
        fi
    done
    
    if [ $connected -gt 0 ]; then
        print_success "Контейнеры подключены к сети панели"
    fi
}

# Проверка связи с панелью (быстрая)
verify_panel_connection() {
    print_info "Проверка связи с панелью Remnawave..."
    
    # Ждём пока контейнер запустится
    sleep 3
    
    # Быстрая проверка DNS (занимает <1 сек)
    if docker exec remnawave_bot getent hosts remnawave >/dev/null 2>&1; then
        local panel_ip=$(docker exec remnawave_bot getent hosts remnawave 2>/dev/null | awk '{print $1}')
        print_success "Связь с панелью установлена!"
        echo -e "${GREEN}   remnawave -> $panel_ip:3000${NC}"
    else
        print_error "❌ DNS remnawave НЕ НАЙДЕН!"
        echo
        echo -e "${YELLOW}   Контейнеры бота не видят панель Remnawave.${NC}"
        echo -e "${YELLOW}   Выполните команды для исправления:${NC}"
        echo
        echo -e "${CYAN}   # Узнать сеть панели:${NC}"
        echo -e "${WHITE}   docker inspect remnawave --format '{{range \$net, \$_ := .NetworkSettings.Networks}}{{\$net}}{{end}}'${NC}"
        echo
        echo -e "${CYAN}   # Подключить бота к этой сети (замените NETWORK_NAME):${NC}"
        echo -e "${WHITE}   docker network connect NETWORK_NAME remnawave_bot${NC}"
        echo -e "${WHITE}   docker network connect NETWORK_NAME remnawave_bot_db${NC}"
        echo -e "${WHITE}   docker network connect NETWORK_NAME remnawave_bot_redis${NC}"
        echo
        echo -e "${CYAN}   # Или перезапустите установку с правильным именем сети${NC}"
    fi
}

# Подготовка сети панели
prepare_panel_network() {
    local network="${REMNAWAVE_DOCKER_NETWORK:-remnawave-network}"
    
    # Проверяем существует ли сеть
    if docker network inspect "$network" &>/dev/null; then
        print_info "Сеть $network уже существует"
    else
        print_warning "Сеть $network не найдена"
        print_info "Создаём сеть $network..."
        docker network create "$network" 2>/dev/null || true
        
        if docker network inspect "$network" &>/dev/null; then
            print_success "Сеть $network создана"
        else
            print_error "Не удалось создать сеть $network"
        fi
    fi
}
