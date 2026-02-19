#!/bin/bash

# Strict mode: fail fast on unhandled errors/undefined vars/pipeline failures.
set -Eeuo pipefail

# ===============================================
# 🔄 REMNAWAVE BEDOLAGA BOT - ОБНОВЛЕНИЕ
# ===============================================
# Для menu/runtime внутри bot отключается errexit точечно (set +e в циклах меню).

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m'
REPO_BRANCH="spiderman"
FORCE_INSTALL_BOT_COMMAND="${FORCE_INSTALL_BOT_COMMAND:-false}"

CABINET_REPO_URL="https://github.com/RamaPulya/bedolaga-cabinet.git"
CABINET_BRANCH="spiderman"
CABINET_DIR="/opt/bedolaga-cabinet"
CABINET_COMPOSE_FILE="docker-compose.yml"
CABINET_OVERRIDE_FILE="docker-compose.override.yml"
CABINET_SERVICE_NAME="cabinet-frontend"
CABINET_NETWORK_NAME="remnawave-network"
CABINET_CADDY_DIR="/opt/caddy-remnawave"

EXIT_OK=0
EXIT_PREFLIGHT=20
EXIT_LOCK=21
EXIT_RUNTIME=22

LOCK_FILE="${LOCK_FILE:-/var/lock/remnawave-bot.lock}"
LOCK_HELD=0
LOCK_METHOD=""
LOCK_DIR="$(dirname "$LOCK_FILE")"

if [ ! -d "$LOCK_DIR" ] || [ ! -w "$LOCK_DIR" ]; then
    LOCK_FILE="/tmp/remnawave-bot.lock"
fi

log_error() {
    echo -e "${RED}❌ $*${NC}" >&2
}

log_warn() {
    echo -e "${YELLOW}⚠️  $*${NC}" >&2
}

release_lock() {
    if [ "$LOCK_HELD" -ne 1 ]; then
        return 0
    fi

    if [ "$LOCK_METHOD" = "flock" ]; then
        flock -u 9 2>/dev/null || true
    elif [ "$LOCK_METHOD" = "file" ]; then
        rm -f "$LOCK_FILE" 2>/dev/null || true
    fi

    LOCK_HELD=0
    LOCK_METHOD=""
}

acquire_lock() {
    if [ "${BOT_SKIP_LOCK:-false}" = "true" ]; then
        return 0
    fi

    if [ "$LOCK_HELD" -eq 1 ]; then
        return 0
    fi

    local lock_dir
    lock_dir="$(dirname "$LOCK_FILE")"
    mkdir -p "$lock_dir" 2>/dev/null || true

    if command -v flock >/dev/null 2>&1; then
        exec 9>"$LOCK_FILE" || {
            log_error "Cannot open lock file: $LOCK_FILE"
            return "$EXIT_LOCK"
        }
        if ! flock -n 9; then
            log_error "Another bot operation is already running (lock: $LOCK_FILE)"
            return "$EXIT_LOCK"
        fi
        LOCK_HELD=1
        LOCK_METHOD="flock"
        return 0
    fi

    if ( set -o noclobber; echo "$$" > "$LOCK_FILE" ) 2>/dev/null; then
        LOCK_HELD=1
        LOCK_METHOD="file"
        return 0
    fi

    log_error "Another bot operation is already running (lock: $LOCK_FILE)"
    return "$EXIT_LOCK"
}

require_command() {
    local cmd="$1"
    if ! command -v "$cmd" >/dev/null 2>&1; then
        log_error "Required command not found: $cmd"
        return "$EXIT_PREFLIGHT"
    fi
}

check_disk_free_mb() {
    local target="$1"
    local min_mb="$2"
    local avail_kb
    avail_kb="$(df -Pk "$target" 2>/dev/null | awk 'NR==2{print $4}')"
    if [ -z "$avail_kb" ]; then
        log_error "Cannot check free disk space for: $target"
        return "$EXIT_PREFLIGHT"
    fi

    local min_kb=$((min_mb * 1024))
    if [ "$avail_kb" -lt "$min_kb" ]; then
        log_error "Not enough disk space in $target (required ${min_mb}MB, available $((avail_kb / 1024))MB)"
        return "$EXIT_PREFLIGHT"
    fi
}

ensure_writable_path() {
    local target="$1"
    local probe="$target"
    if [ ! -d "$probe" ]; then
        probe="$(dirname "$probe")"
    fi

    if [ ! -d "$probe" ] || [ ! -w "$probe" ]; then
        log_error "No write access to: $probe"
        return "$EXIT_PREFLIGHT"
    fi
}

check_system_paths_for_root() {
    local action="$1"
    local p
    for p in /opt /usr/local/bin; do
        if ! ensure_writable_path "$p"; then
            log_error "Action '$action' requires write access to: $p"
            return "$EXIT_PREFLIGHT"
        fi
    done
}

check_network_github() {
    if ! git ls-remote --heads https://github.com/RamaPulya/bot_auto_install.git >/dev/null 2>&1; then
        log_error "Network check failed: cannot reach GitHub repository"
        return "$EXIT_PREFLIGHT"
    fi
}

ensure_docker_access() {
    if ! docker info >/dev/null 2>&1; then
        log_error "Docker daemon is unavailable for current user"
        return "$EXIT_PREFLIGHT"
    fi
}

preflight_action() {
    local action="$1"
    local need_lock="${2:-false}"
    local need_network="${3:-false}"
    local need_root="${4:-false}"
    local need_docker="${5:-false}"
    local need_git="${6:-false}"
    local min_disk_mb="${7:-128}"
    local write_target="${8:-$INSTALL_DIR}"
    local need_write="${9:-false}"

    require_command df || return $?
    if [ "$need_git" = "true" ] || [ "$need_network" = "true" ]; then
        require_command git || return $?
    fi
    if [ "$need_docker" = "true" ]; then
        require_command docker || return $?
        ensure_docker_access || return $?
    fi

    if [ "$need_root" = "true" ] && [ "$(id -u)" -ne 0 ]; then
        log_error "Action '$action' must be run as root/sudo"
        return "$EXIT_PREFLIGHT"
    fi
    if [ "$need_root" = "true" ]; then
        check_system_paths_for_root "$action" || return $?
    fi

    local disk_target="$write_target"
    if [ ! -e "$disk_target" ]; then
        disk_target="$(dirname "$disk_target")"
    fi

    check_disk_free_mb "$disk_target" "$min_disk_mb" || return $?
    if [ "$need_write" = "true" ]; then
        ensure_writable_path "$write_target" || return $?
    fi

    if [ "$need_network" = "true" ]; then
        check_network_github || return $?
    fi

    if [ "$need_lock" = "true" ]; then
        acquire_lock || return $?
    fi

    return 0
}

cleanup_script() {
    release_lock
}

on_err() {
    local rc=$?
    log_error "Execution failed (exit code $rc)"
    exit "$rc"
}

trap cleanup_script EXIT INT TERM
trap on_err ERR

# ═══════════════════════════════════════════════════════════════
# ФУНКЦИИ (определяем ДО использования)
# ═══════════════════════════════════════════════════════════════

# Автоопределение директории установки
find_install_dir() {
    if [ -d "/opt/remnawave-bedolaga-telegram-bot" ]; then
        echo "/opt/remnawave-bedolaga-telegram-bot"
    elif [ -d "/root/remnawave-bedolaga-telegram-bot" ]; then
        echo "/root/remnawave-bedolaga-telegram-bot"
    elif [ -f "./docker-compose.yml" ] && [ -f "./.env" ]; then
        pwd
    else
        echo ""
    fi
}

# Функция обновления бота
upgrade_bot() {
    preflight_action "upgrade-bot" true false false true true 1024 "$INSTALL_DIR" true || return $?

    echo
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}📦 ОБНОВЛЕНИЕ БОТА${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    
    cd "$INSTALL_DIR"
    
    # Создание бэкапа
    echo -e "${CYAN}💾 Создание бэкапа...${NC}"
    BACKUP_DIR="$INSTALL_DIR/data/backups"
    mkdir -p "$BACKUP_DIR"
    cp .env "$BACKUP_DIR/.env_$(date +%Y%m%d_%H%M%S)" 2>/dev/null || true
    
    # Текущая версия
    CURRENT_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
    echo -e "${WHITE}Текущая версия:${NC} $CURRENT_COMMIT"
    
    # Обновление кода
    echo -e "${CYAN}📥 Получение обновлений (ветка: ${REPO_BRANCH})...${NC}"

    if [ ! -d ".git" ]; then
        echo -e "${RED}❌ Git-репозиторий не найден в ${INSTALL_DIR}${NC}"
        echo -e "${YELLOW}Похоже бот установлен не через git clone. Обновление кода пропущено.${NC}"
    else
        # Если репозиторий shallow (частая причина 'grafted' и не обновляется) — расширяем историю
        git fetch --unshallow 2>/dev/null || true

        if ! git fetch origin "${REPO_BRANCH}" --prune --tags; then
            echo -e "${YELLOW}⚠️  Не удалось выполнить git fetch origin ${REPO_BRANCH}${NC}"
        fi
        git fetch origin "${REPO_BRANCH}:refs/remotes/origin/${REPO_BRANCH}" --update-head-ok >/dev/null 2>&1 || true

        REMOTE_REF=""
        if git show-ref --verify --quiet "refs/remotes/origin/${REPO_BRANCH}"; then
            REMOTE_REF="origin/${REPO_BRANCH}"
        elif git rev-parse --verify --quiet FETCH_HEAD >/dev/null; then
            REMOTE_REF="FETCH_HEAD"
        fi

        if [ -n "$REMOTE_REF" ]; then
            git checkout -B "${REPO_BRANCH}" "$REMOTE_REF" 2>/dev/null || git checkout "${REPO_BRANCH}" 2>/dev/null || true
            if ! git reset --hard "$REMOTE_REF"; then
                echo -e "${YELLOW}⚠️  Не удалось выполнить git reset --hard $REMOTE_REF${NC}"
            fi
        else
            echo -e "${YELLOW}⚠️  Не найдена ветка ${REPO_BRANCH} после fetch.${NC}"
        fi
    fi
    
    NEW_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
    echo -e "${WHITE}Новая версия:${NC} $NEW_COMMIT"
    
    if [ "$CURRENT_COMMIT" = "$NEW_COMMIT" ]; then
        echo -e "${GREEN}✅ Уже актуальная версия${NC}"
    else
        echo -e "${GREEN}✅ Код обновлён: $CURRENT_COMMIT → $NEW_COMMIT${NC}"
    fi
    
    # Пересборка контейнеров
    echo -e "${CYAN}🐳 Пересборка контейнеров...${NC}"
    if ! docker compose -f "$COMPOSE_FILE" down; then
        echo -e "${RED}⚠️  Ошибка остановки контейнеров перед обновлением${NC}"
        return "$EXIT_RUNTIME"
    fi
    if ! docker compose -f "$COMPOSE_FILE" build --no-cache; then
        echo -e "${RED}⚠️  Ошибка сборки контейнеров${NC}"
        return "$EXIT_RUNTIME"
    fi
    
    if docker compose -f "$COMPOSE_FILE" up -d; then
        echo -e "${GREEN}✅ Бот обновлён и запущен${NC}"
    else
        echo -e "${RED}⚠️  Ошибка запуска контейнеров!${NC}"
        echo -e "${YELLOW}Проверьте: docker compose -f $COMPOSE_FILE logs${NC}"
        echo -e "${YELLOW}Возможно нужно создать сеть: docker network create remnawave-network${NC}"
        return "$EXIT_RUNTIME"
    fi
}

# Функция установки команды bot
install_bot_command() {
    preflight_action "install-bot-command" true false true false false 128 "/usr/local/bin" true || return $?

    echo
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}🎮 УСТАНОВКА КОМАНДЫ 'bot'${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    
    if [ -f "/usr/local/bin/bot" ] && [ "$FORCE_INSTALL_BOT_COMMAND" != "true" ]; then
        echo -e "${YELLOW}Команда 'bot' уже существует. Обновить? (y/n) [y]:${NC}"
        read -n 1 -r REPLY < /dev/tty
        echo
        REPLY=${REPLY:-y}
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}Пропущено${NC}"
            return
        fi
    fi
    
    echo -e "${CYAN}📝 Создание команды 'bot'...${NC}"
    
    # Создаём скрипт bot
    if [ "$(id -u)" -ne 0 ] && [ ! -w "/usr/local/bin" ]; then
        echo -e "${RED}❌ Нет прав на запись в /usr/local/bin${NC}"
        echo -e "${YELLOW}Запустите обновление от root (sudo) и повторите.${NC}"
        return 1
    fi

    if ! cat > /usr/local/bin/bot << BOTEOF
#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# 🤖 REMNAWAVE BEDOLAGA BOT - КОМАНДА УПРАВЛЕНИЯ
# ═══════════════════════════════════════════════════════════════

INSTALL_DIR="$INSTALL_DIR"
COMPOSE_FILE="$COMPOSE_FILE"
INSTALLER_DIR="$INSTALL_DIR/.installer"
REPO_BRANCH="spiderman"

CABINET_REPO_URL="https://github.com/RamaPulya/bedolaga-cabinet.git"
CABINET_BRANCH="spiderman"
CABINET_DIR="/opt/bedolaga-cabinet"
CABINET_COMPOSE_FILE="docker-compose.yml"
CABINET_OVERRIDE_FILE="docker-compose.override.yml"
CABINET_SERVICE_NAME="cabinet-frontend"
CABINET_NETWORK_NAME="remnawave-network"
CABINET_CADDY_DIR="/opt/caddy-remnawave"

set -Eeuo pipefail

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m'

EXIT_PREFLIGHT=20
EXIT_LOCK=21
EXIT_RUNTIME=22

LOCK_FILE="\${LOCK_FILE:-/var/lock/remnawave-bot.lock}"
LOCK_HELD=0
LOCK_METHOD=""
LOCK_DIR=\$(dirname "\$LOCK_FILE")

if [ ! -d "\$LOCK_DIR" ] || [ ! -w "\$LOCK_DIR" ]; then
    LOCK_FILE="/tmp/remnawave-bot.lock"
fi

bot_log_error() {
    echo -e "\${RED}❌ \$*\${NC}" >&2
}

release_lock() {
    if [ "\$LOCK_HELD" -ne 1 ]; then
        return 0
    fi

    if [ "\$LOCK_METHOD" = "flock" ]; then
        flock -u 8 2>/dev/null || true
    elif [ "\$LOCK_METHOD" = "file" ]; then
        rm -f "\$LOCK_FILE" 2>/dev/null || true
    fi

    LOCK_HELD=0
    LOCK_METHOD=""
}

acquire_lock() {
    if [ "\${BOT_SKIP_LOCK:-false}" = "true" ]; then
        return 0
    fi

    if [ "\$LOCK_HELD" -eq 1 ]; then
        return 0
    fi

    local lock_dir
    lock_dir="\$(dirname "\$LOCK_FILE")"
    mkdir -p "\$lock_dir" 2>/dev/null || true

    if command -v flock >/dev/null 2>&1; then
        exec 8>"\$LOCK_FILE" || {
            bot_log_error "Cannot open lock file: \$LOCK_FILE"
            return "\$EXIT_LOCK"
        }
        if ! flock -n 8; then
            bot_log_error "Another bot operation is already running (lock: \$LOCK_FILE)"
            return "\$EXIT_LOCK"
        fi
        LOCK_HELD=1
        LOCK_METHOD="flock"
        return 0
    fi

    if ( set -o noclobber; echo "\$\$" > "\$LOCK_FILE" ) 2>/dev/null; then
        LOCK_HELD=1
        LOCK_METHOD="file"
        return 0
    fi

    bot_log_error "Another bot operation is already running (lock: \$LOCK_FILE)"
    return "\$EXIT_LOCK"
}

require_command() {
    local cmd="\$1"
    if ! command -v "\$cmd" >/dev/null 2>&1; then
        bot_log_error "Required command not found: \$cmd"
        return "\$EXIT_PREFLIGHT"
    fi
}

check_disk_free_mb() {
    local target="\$1"
    local min_mb="\$2"
    local avail_kb
    avail_kb="\$(df -Pk "\$target" 2>/dev/null | awk 'NR==2{print \$4}')"
    if [ -z "\$avail_kb" ]; then
        bot_log_error "Cannot check free disk space for: \$target"
        return "\$EXIT_PREFLIGHT"
    fi

    local min_kb=\$((min_mb * 1024))
    if [ "\$avail_kb" -lt "\$min_kb" ]; then
        bot_log_error "Not enough disk space in \$target (required \${min_mb}MB, available \$((avail_kb / 1024))MB)"
        return "\$EXIT_PREFLIGHT"
    fi
}

ensure_writable_path() {
    local target="\$1"
    local probe="\$target"
    if [ ! -d "\$probe" ]; then
        probe="\$(dirname "\$probe")"
    fi

    if [ ! -d "\$probe" ] || [ ! -w "\$probe" ]; then
        bot_log_error "No write access to: \$probe"
        return "\$EXIT_PREFLIGHT"
    fi
}

check_system_paths_for_root() {
    local action="\$1"
    local p
    for p in /opt /usr/local/bin; do
        if ! ensure_writable_path "\$p"; then
            bot_log_error "Action '\$action' requires write access to: \$p"
            return "\$EXIT_PREFLIGHT"
        fi
    done
}

check_network_github() {
    if ! git ls-remote --heads https://github.com/RamaPulya/bot_auto_install.git >/dev/null 2>&1; then
        bot_log_error "Network check failed: cannot reach GitHub repository"
        return "\$EXIT_PREFLIGHT"
    fi
}

ensure_docker_access() {
    if ! docker info >/dev/null 2>&1; then
        bot_log_error "Docker daemon is unavailable for current user"
        return "\$EXIT_PREFLIGHT"
    fi
}

preflight_action() {
    local action="\$1"
    local need_lock="\${2:-false}"
    local need_network="\${3:-false}"
    local need_root="\${4:-false}"
    local need_docker="\${5:-false}"
    local need_git="\${6:-false}"
    local min_disk_mb="\${7:-128}"
    local write_target="\${8:-\$INSTALL_DIR}"
    local need_write="\${9:-false}"

    require_command df || return \$?
    if [ "\$need_git" = "true" ] || [ "\$need_network" = "true" ]; then
        require_command git || return \$?
    fi
    if [ "\$need_docker" = "true" ]; then
        require_command docker || return \$?
        ensure_docker_access || return \$?
    fi

    if [ "\$need_root" = "true" ] && [ "\$(id -u)" -ne 0 ]; then
        bot_log_error "Action '\$action' must be run as root/sudo"
        return "\$EXIT_PREFLIGHT"
    fi
    if [ "\$need_root" = "true" ]; then
        check_system_paths_for_root "\$action" || return \$?
    fi

    local disk_target="\$write_target"
    if [ ! -e "\$disk_target" ]; then
        disk_target="\$(dirname "\$disk_target")"
    fi

    check_disk_free_mb "\$disk_target" "\$min_disk_mb" || return \$?
    if [ "\$need_write" = "true" ]; then
        ensure_writable_path "\$write_target" || return \$?
    fi

    if [ "\$need_network" = "true" ]; then
        check_network_github || return \$?
    fi

    if [ "\$need_lock" = "true" ]; then
        acquire_lock || return \$?
    fi

    return 0
}

cleanup_runtime() {
    release_lock
}

trap cleanup_runtime EXIT INT TERM

check_install_dir() {
    if [ ! -d "\$INSTALL_DIR" ]; then
        echo -e "\${RED}❌ Директория бота не найдена: \$INSTALL_DIR\${NC}"
        exit 1
    fi
    cd "\$INSTALL_DIR"
}

do_logs() {
    check_install_dir
    preflight_action "logs" false false false true false 128 "\$INSTALL_DIR" false || return \$?
    echo -e "\${CYAN}📋 Логи бота (Ctrl+C для выхода)...\${NC}"
    docker compose -f "\$COMPOSE_FILE" logs -f --tail=150 bot
}

do_status() {
    check_install_dir
    preflight_action "status" false false false true false 128 "\$INSTALL_DIR" false || return \$?
    echo -e "\${CYAN}═══════════════════════════════════════════════════════════════\${NC}"
    echo -e "\${WHITE}📊 СТАТУС КОНТЕЙНЕРОВ\${NC}"
    echo -e "\${CYAN}═══════════════════════════════════════════════════════════════\${NC}"
    echo
    docker compose -f "\$COMPOSE_FILE" ps
    echo
    echo -e "\${WHITE}📈 Использование ресурсов:\${NC}"
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" 2>/dev/null | grep -E "remnawave|postgres|redis" || echo "Контейнеры не запущены"
}

do_restart() {
    check_install_dir
    preflight_action "restart" true false false true false 256 "\$INSTALL_DIR" true || return \$?
    echo -e "\${CYAN}🔄 Перезапуск бота (применяем .env)...\${NC}"
    
    # Проверяем и создаём сеть если нужно
    if grep -q "external: true" "\$COMPOSE_FILE" 2>/dev/null; then
        if ! docker network ls --format '{{.Name}}' | grep -q "remnawave-network"; then
            echo -e "\${YELLOW}Создаём сеть remnawave-network...\${NC}"
            docker network create remnawave-network 2>/dev/null || true
        fi
    fi
    
    docker compose -f "\$COMPOSE_FILE" up -d --force-recreate 2>&1
    sleep 3
    if docker ps --format '{{.Names}}' | grep -q "remnawave_bot"; then
        echo -e "\${GREEN}✅ Бот перезапущен\${NC}"
    else
        echo -e "\${RED}❌ Бот не запустился! Проверьте логи: bot logs\${NC}"
        return 1
    fi
}

do_start() {
    check_install_dir
    preflight_action "start" true false false true false 256 "\$INSTALL_DIR" true || return \$?
    echo -e "\${CYAN}▶️  Запуск бота...\${NC}"
    
    # Проверяем и создаём сеть если нужно
    if grep -q "external: true" "\$COMPOSE_FILE" 2>/dev/null; then
        if ! docker network ls --format '{{.Name}}' | grep -q "remnawave-network"; then
            echo -e "\${YELLOW}Создаём сеть remnawave-network...\${NC}"
            docker network create remnawave-network 2>/dev/null || true
        fi
    fi
    
    if docker compose -f "\$COMPOSE_FILE" up -d 2>&1; then
        sleep 3
        if docker ps --format '{{.Names}}' | grep -q "remnawave_bot"; then
            echo -e "\${GREEN}✅ Бот запущен\${NC}"
        else
            echo -e "\${RED}❌ Бот не запустился! Проверьте логи: bot logs\${NC}"
            return 1
        fi
    else
        echo -e "\${RED}❌ Ошибка запуска!\${NC}"
        return 1
    fi
}

do_stop() {
    check_install_dir
    preflight_action "stop" true false false true false 128 "\$INSTALL_DIR" true || return \$?
    echo -e "\${CYAN}⏹️  Остановка бота...\${NC}"
    if ! docker compose -f "\$COMPOSE_FILE" down; then
        echo -e "\${RED}❌ Не удалось остановить контейнеры\${NC}"
        return 1
    fi
    echo -e "\${GREEN}✅ Бот остановлен\${NC}"
}

do_update() {
    check_install_dir
    preflight_action "update" true true false true true 1024 "\$INSTALL_DIR" true || return \$?
    echo -e "\${CYAN}📦 Обновление бота...\${NC}"
    cp .env ".env.backup_\$(date +%Y%m%d_%H%M%S)" 2>/dev/null

    echo -e "\${CYAN}📥 Обновление кода (ветка: \$REPO_BRANCH)...\${NC}"
    if [ -d ".git" ]; then
        git fetch --unshallow 2>/dev/null || true
        if ! git fetch origin "\$REPO_BRANCH" --prune --tags; then
            echo -e "\${YELLOW}⚠️  Не удалось получить обновления из GitHub\${NC}"
        fi
        git fetch origin "\$REPO_BRANCH:refs/remotes/origin/\$REPO_BRANCH" --update-head-ok >/dev/null 2>&1 || true
        TARGET_REF=""
        if git show-ref --verify --quiet "refs/remotes/origin/\$REPO_BRANCH"; then
            TARGET_REF="origin/\$REPO_BRANCH"
        elif git rev-parse --verify --quiet FETCH_HEAD >/dev/null; then
            TARGET_REF="FETCH_HEAD"
        fi
        if [ -n "\$TARGET_REF" ]; then
            git checkout -B "\$REPO_BRANCH" "origin/\$REPO_BRANCH" 2>/dev/null || git checkout "\$REPO_BRANCH" 2>/dev/null || true
            if ! git reset --hard "origin/\$REPO_BRANCH"; then
                echo -e "\${YELLOW}⚠️  Не удалось обновить код до origin/\$REPO_BRANCH\${NC}"
            fi
        else
            echo -e "\${YELLOW}⚠️  В origin нет ветки \$REPO_BRANCH\${NC}"
        fi
    else
        echo -e "\${YELLOW}⚠️  Git-репозиторий не найден — обновление кода пропущено\${NC}"
    fi
    if ! docker compose -f "\$COMPOSE_FILE" down; then
        echo -e "\${RED}❌ Не удалось остановить контейнеры перед обновлением\${NC}"
        return 1
    fi
    if ! docker compose -f "\$COMPOSE_FILE" build --no-cache; then
        echo -e "\${RED}❌ Не удалось пересобрать контейнеры\${NC}"
        return 1
    fi
    if ! docker compose -f "\$COMPOSE_FILE" up -d; then
        echo -e "\${RED}❌ Не удалось запустить контейнеры после обновления\${NC}"
        return 1
    fi
    echo -e "\${GREEN}✅ Обновление завершено\${NC}"
}

show_update_info() {
    check_install_dir
    echo -e "\${CYAN}═══════════════════════════════════════════════════════════════\${NC}"
    echo -e "\${WHITE}📦 ОБНОВЛЕНИЕ БОТА\${NC}"
    echo -e "\${CYAN}═══════════════════════════════════════════════════════════════\${NC}"
    echo

    if [ ! -d ".git" ]; then
        echo -e "\${RED}❌ Git-репозиторий не найден\${NC}"
        return 1
    fi

    if ! git fetch origin "\$REPO_BRANCH" >/dev/null 2>&1; then
        echo -e "\${YELLOW}⚠️  Не удалось получить обновления из GitHub\${NC}"
    fi

    LOCAL_HASH=\$(git rev-parse --short HEAD 2>/dev/null || echo "?")
    LOCAL_DATE=\$(git log -1 --date=short --format=%ad 2>/dev/null || echo "?")
    REMOTE_HASH=\$(git rev-parse --short "origin/\$REPO_BRANCH" 2>/dev/null || echo "?")
    REMOTE_DATE=\$(git log -1 "origin/\$REPO_BRANCH" --date=short --format=%ad 2>/dev/null || echo "?")
    BEHIND=\$(git rev-list --count "HEAD..origin/\$REPO_BRANCH" 2>/dev/null || echo "0")

    echo -e "\${WHITE}Локальная версия:\${NC} \${CYAN}\$LOCAL_HASH\${NC} | \$LOCAL_DATE"
    echo -e "\${WHITE}Удаленная версия:\${NC} \${CYAN}\$REMOTE_HASH\${NC} | \$REMOTE_DATE"
    echo
    if [ "\$BEHIND" -gt 0 ] 2>/dev/null; then
        echo -e "\${YELLOW}Доступно обновлений: \$BEHIND\${NC}"
    else
        echo -e "\${GREEN}Обновлений нет — вы на актуальной версии\${NC}"
    fi
    echo
    echo -e "\${WHITE}Последние коммиты (origin/\$REPO_BRANCH):\${NC}"
    git log -n 5 --date=short --pretty=format:"%h | %ad | %an | %s" "origin/\$REPO_BRANCH" 2>/dev/null || echo "Нет данных"
    echo
}

update_menu() {
    set +e
    while true; do
        show_update_info || true
        echo -e "\${WHITE}Выберите действие:\${NC}"
        echo -e "  \${CYAN}1)\${NC} 📦 Обновить бота"
        echo -e "  \${CYAN}0)\${NC} Назад"
        echo
        read -p "Ваш выбор: " choice
        case \$choice in
            1) do_update; read -p "Нажмите Enter..." ;;
            0) return ;;
            *) echo -e "\${RED}Неверный выбор\${NC}"; sleep 1 ;;
        esac
    done
}

update_installer() {
    preflight_action "update-installer" true true true false true 256 "\$INSTALL_DIR" true || return \$?

    echo
    echo -e "\${CYAN}═══════════════════════════════════════════════════════════════\${NC}"
    echo -e "\${WHITE}🔧 ОБНОВЛЕНИЕ СКРИПТОВ УСТАНОВЩИКА\${NC}"
    echo -e "\${CYAN}═══════════════════════════════════════════════════════════════\${NC}"
    
    echo -e "\${CYAN}📥 Скачивание скриптов установщика...\${NC}"
    
    TEMP_DIR=\$(mktemp -d)
    git clone --depth 1 --single-branch --branch spiderman https://github.com/RamaPulya/bot_auto_install.git "\$TEMP_DIR" 2>/dev/null
    
    if [ -d "\$TEMP_DIR/scripts" ]; then
        if [ ! -d "\$INSTALL_DIR" ] || [ ! -w "\$INSTALL_DIR" ]; then
            echo -e "\${RED}❌ Нет прав на запись в \$INSTALL_DIR. Запустите bot от root (sudo).\${NC}"
            rm -rf "\$TEMP_DIR"
            return 1
        fi

        rm -rf "\$INSTALLER_DIR" 2>/dev/null || true
        if ! cp -r "\$TEMP_DIR/scripts" "\$INSTALLER_DIR"; then
            echo -e "\${RED}❌ Не удалось обновить скрипты установщика (ошибка записи в \$INSTALLER_DIR)\${NC}"
            rm -rf "\$TEMP_DIR"
            return 1
        fi
        chmod +x "\$INSTALLER_DIR"/*.sh 2>/dev/null
        chmod +x "\$INSTALLER_DIR"/lib/*.sh 2>/dev/null
        
        VERSION=\$(cat "\$INSTALLER_DIR/VERSION" 2>/dev/null || echo "?")
        echo -e "\${GREEN}✅ Скрипты установщика обновлены (v\$VERSION)\${NC}"

        # Автообновление команды bot на новую версию скриптов
        if [ -x "\$INSTALLER_DIR/upgrade.sh" ]; then
            if BOT_SKIP_LOCK=true FORCE_INSTALL_BOT_COMMAND=true bash "\$INSTALLER_DIR/upgrade.sh" --install-bot-command --force >/dev/null 2>&1; then
                echo -e "\${GREEN}✅ Команда bot пересоздана автоматически\${NC}"
            else
                echo -e "\${YELLOW}⚠️  Не удалось пересоздать команду bot автоматически\${NC}"
                echo -e "\${YELLOW}   Выполните: bash \$INSTALLER_DIR/upgrade.sh --install-bot-command --force\${NC}"
            fi
        fi
    else
        echo -e "\${RED}❌ Ошибка загрузки\${NC}"
        return 1
    fi
    
    rm -rf "\$TEMP_DIR"
}

do_backup() {
    check_install_dir
    preflight_action "backup" true false false true false 256 "\$INSTALL_DIR" true || return \$?
    local BACKUP_DIR="\$INSTALL_DIR/data/backups"
    local TIMESTAMP=\$(date +%Y%m%d_%H%M%S)
    local BACKUP_NAME="backup_\$TIMESTAMP"
    mkdir -p "\$BACKUP_DIR/\$BACKUP_NAME"
    
    echo -e "\${CYAN}╔══════════════════════════════════════════════════════════════╗\${NC}"
    echo -e "\${CYAN}║           💾 СОЗДАНИЕ РЕЗЕРВНОЙ КОПИИ 💾                     ║\${NC}"
    echo -e "\${CYAN}╚══════════════════════════════════════════════════════════════╝\${NC}"
    echo
    
    # 1. PostgreSQL
    echo -e "\${WHITE}1/4 PostgreSQL...\${NC}"
    if docker compose -f "\$COMPOSE_FILE" exec -T postgres pg_dump -U remnawave_user remnawave_bot > "\$BACKUP_DIR/\$BACKUP_NAME/database.sql" 2>/dev/null; then
        local DB_SIZE=\$(du -h "\$BACKUP_DIR/\$BACKUP_NAME/database.sql" | cut -f1)
        echo -e "    \${GREEN}✅ database.sql (\$DB_SIZE)\${NC}"
    else
        echo -e "    \${RED}❌ Ошибка бэкапа PostgreSQL\${NC}"
    fi
    
    # 2. Redis
    echo -e "\${WHITE}2/4 Redis...\${NC}"
    if docker compose -f "\$COMPOSE_FILE" exec -T redis redis-cli BGSAVE >/dev/null 2>&1; then
        sleep 2
        docker compose -f "\$COMPOSE_FILE" exec -T redis cat /data/dump.rdb > "\$BACKUP_DIR/\$BACKUP_NAME/redis.rdb" 2>/dev/null
        if [ -s "\$BACKUP_DIR/\$BACKUP_NAME/redis.rdb" ]; then
            local REDIS_SIZE=\$(du -h "\$BACKUP_DIR/\$BACKUP_NAME/redis.rdb" | cut -f1)
            echo -e "    \${GREEN}✅ redis.rdb (\$REDIS_SIZE)\${NC}"
        else
            echo -e "    \${YELLOW}⚠️  Redis пуст или недоступен\${NC}"
            rm -f "\$BACKUP_DIR/\$BACKUP_NAME/redis.rdb"
        fi
    else
        echo -e "    \${YELLOW}⚠️  Redis недоступен\${NC}"
    fi
    
    # 3. Конфигурация
    echo -e "\${WHITE}3/4 Конфигурация...\${NC}"
    cp .env "\$BACKUP_DIR/\$BACKUP_NAME/.env" 2>/dev/null && echo -e "    \${GREEN}✅ .env\${NC}"
    cp docker-compose*.yml "\$BACKUP_DIR/\$BACKUP_NAME/" 2>/dev/null && echo -e "    \${GREEN}✅ docker-compose.yml\${NC}"
    
    # 4. Данные (QR-коды и т.д.)
    echo -e "\${WHITE}4/4 Данные...\${NC}"
    if [ -d "data" ] && [ "\$(ls -A data 2>/dev/null)" ]; then
        tar -czf "\$BACKUP_DIR/\$BACKUP_NAME/data.tar.gz" data 2>/dev/null
        if [ -f "\$BACKUP_DIR/\$BACKUP_NAME/data.tar.gz" ]; then
            local DATA_SIZE=\$(du -h "\$BACKUP_DIR/\$BACKUP_NAME/data.tar.gz" | cut -f1)
            echo -e "    \${GREEN}✅ data.tar.gz (\$DATA_SIZE)\${NC}"
        fi
    else
        echo -e "    \${YELLOW}⚠️  Папка data пуста\${NC}"
    fi
    
    # Итог
    echo
    local TOTAL_SIZE=\$(du -sh "\$BACKUP_DIR/\$BACKUP_NAME" | cut -f1)
    echo -e "\${GREEN}═══════════════════════════════════════════════════════════════\${NC}"
    echo -e "\${GREEN}✅ Бэкап создан: \$BACKUP_DIR/\$BACKUP_NAME\${NC}"
    echo -e "\${GREEN}   Размер: \$TOTAL_SIZE\${NC}"
    echo -e "\${GREEN}═══════════════════════════════════════════════════════════════\${NC}"
    
    # Удаляем старые бэкапы (оставляем 5 последних)
    ls -dt "\$BACKUP_DIR"/backup_* 2>/dev/null | tail -n +6 | xargs -r rm -rf
}

do_health() {
    check_install_dir
    preflight_action "health" false false false true false 128 "\$INSTALL_DIR" false || return \$?
    echo -e "\${CYAN}╔══════════════════════════════════════════════════════════════╗\${NC}"
    echo -e "\${CYAN}║           🏥 ДИАГНОСТИКА СИСТЕМЫ 🏥                          ║\${NC}"
    echo -e "\${CYAN}╚══════════════════════════════════════════════════════════════╝\${NC}"
    echo
    
    echo -e "\${WHITE}🐳 Контейнеры:\${NC}"
    docker compose -f "\$COMPOSE_FILE" ps
    echo
    
    echo -e "\${WHITE}📊 Сервисы:\${NC}"
    docker ps --format '{{.Names}}' | grep -q "remnawave_bot" && echo -e "  \${GREEN}✅ Bot: работает\${NC}" || echo -e "  \${RED}❌ Bot: не запущен\${NC}"
    docker compose -f "\$COMPOSE_FILE" exec -T postgres pg_isready -U remnawave_user >/dev/null 2>&1 && echo -e "  \${GREEN}✅ PostgreSQL: работает\${NC}" || echo -e "  \${RED}❌ PostgreSQL: не отвечает\${NC}"
    docker compose -f "\$COMPOSE_FILE" exec -T redis redis-cli ping >/dev/null 2>&1 && echo -e "  \${GREEN}✅ Redis: работает\${NC}" || echo -e "  \${RED}❌ Redis: не отвечает\${NC}"
    
    echo
    echo -e "\${WHITE}📋 Последние логи:\${NC}"
    docker compose -f "\$COMPOSE_FILE" logs --tail=10 bot 2>/dev/null
}

do_config() {
    check_install_dir
    preflight_action "config" true false false false false 128 "\$INSTALL_DIR" true || return \$?
    \${EDITOR:-nano} "\$INSTALL_DIR/.env"
    echo -e "\${YELLOW}Перезапустите бота для применения: bot restart\${NC}"
}

ensure_cabinet_network() {
    if ! docker network ls --format '{{.Name}}' | grep -q "^\$CABINET_NETWORK_NAME\$"; then
        echo -e "\${YELLOW}Создаём Docker-сеть \$CABINET_NETWORK_NAME...\${NC}"
        docker network create "\$CABINET_NETWORK_NAME" >/dev/null 2>&1 || true
    fi
}

ensure_cabinet_override() {
    mkdir -p "\$CABINET_DIR"
    cat > "\$CABINET_DIR/\$CABINET_OVERRIDE_FILE" << 'CABINETOVR'
services:
  cabinet-frontend:
    networks:
      - remnawave-network

networks:
  remnawave-network:
    external: true
CABINETOVR
}

sync_cabinet_repo() {
    echo -e "\${CYAN}📦 Синхронизация репозитория кабинета (\$CABINET_BRANCH)...\${NC}"

    if [ -d "\$CABINET_DIR/.git" ]; then
        cd "\$CABINET_DIR" || return 1
        rm -f .git/index.lock .git/shallow.lock .git/FETCH_HEAD.lock .git/HEAD.lock 2>/dev/null || true
        git remote set-url origin "\$CABINET_REPO_URL" >/dev/null 2>&1 || true
        if ! git fetch --prune origin; then
            echo -e "\${RED}❌ Не удалось выполнить git fetch для кабинета\${NC}"
            return 1
        fi
        if ! git show-ref --verify --quiet "refs/remotes/origin/\$CABINET_BRANCH"; then
            echo -e "\${RED}❌ В origin нет ветки \$CABINET_BRANCH для кабинета\${NC}"
            return 1
        fi
        git checkout -B "\$CABINET_BRANCH" "origin/\$CABINET_BRANCH" 2>/dev/null || git checkout "\$CABINET_BRANCH" 2>/dev/null || true
        if ! git reset --hard "origin/\$CABINET_BRANCH"; then
            echo -e "\${RED}❌ Не удалось выполнить git reset --hard origin/\$CABINET_BRANCH\${NC}"
            return 1
        fi
    elif [ -d "\$CABINET_DIR" ] && [ -n "\$(ls -A "\$CABINET_DIR" 2>/dev/null)" ]; then
        echo -e "\${RED}❌ \$CABINET_DIR существует и не является git-репозиторием.\${NC}"
        echo -e "\${YELLOW}Очистите директорию вручную и повторите установку.\${NC}"
        return 1
    else
        mkdir -p "\$(dirname "\$CABINET_DIR")"
        if ! git clone --single-branch --branch "\$CABINET_BRANCH" "\$CABINET_REPO_URL" "\$CABINET_DIR"; then
            echo -e "\${RED}❌ Не удалось клонировать репозиторий кабинета\${NC}"
            return 1
        fi
    fi

    return 0
}

resolve_cabinet_container_id() {
    local container_id=""
    if [ -f "\$CABINET_DIR/\$CABINET_COMPOSE_FILE" ]; then
        container_id=\$(docker compose -f "\$CABINET_DIR/\$CABINET_COMPOSE_FILE" -f "\$CABINET_DIR/\$CABINET_OVERRIDE_FILE" ps -q "\$CABINET_SERVICE_NAME" 2>/dev/null | head -n 1)
    fi
    if [ -z "\$container_id" ]; then
        container_id=\$(docker ps -aq --filter "name=^cabinet_frontend\$" | head -n 1)
    fi
    echo "\$container_id"
}

cabinet_connected_to_network() {
    local container_id="\$1"
    if [ -z "\$container_id" ]; then
        return 1
    fi

    local net_list=""
    net_list=\$(docker inspect "\$container_id" --format '{{range \$k, \$v := .NetworkSettings.Networks}}{{printf "%s " \$k}}{{end}}' 2>/dev/null)
    echo "\$net_list" | grep -qw "\$CABINET_NETWORK_NAME"
}

deploy_cabinet_frontend() {
    if [ ! -f "\$CABINET_DIR/\$CABINET_COMPOSE_FILE" ]; then
        echo -e "\${RED}❌ Не найден \$CABINET_DIR/\$CABINET_COMPOSE_FILE\${NC}"
        return 1
    fi

    ensure_cabinet_network
    ensure_cabinet_override

    echo -e "\${CYAN}🐳 Запуск cabinet-frontend...\${NC}"
    if ! docker compose -f "\$CABINET_DIR/\$CABINET_COMPOSE_FILE" -f "\$CABINET_DIR/\$CABINET_OVERRIDE_FILE" up -d --build --force-recreate "\$CABINET_SERVICE_NAME"; then
        echo -e "\${RED}❌ Не удалось запустить cabinet-frontend\${NC}"
        return 1
    fi

    sleep 2
    local container_id=""
    container_id=\$(resolve_cabinet_container_id)
    if cabinet_connected_to_network "\$container_id"; then
        echo -e "\${GREEN}✅ cabinet_frontend подключён к \$CABINET_NETWORK_NAME\${NC}"
        return 0
    fi

    echo -e "\${RED}❌ cabinet_frontend не подключён к \$CABINET_NETWORK_NAME\${NC}"
    return 1
}

do_cabinet_install() {
    preflight_action "cabinet-install" true true true true true 512 "\$CABINET_DIR" true || return \$?
    echo
    echo -e "\${CYAN}╔═══════════════════════════════════════════════════════════════════════════════╗\${NC}"
    echo -e "\${WHITE}👤 УСТАНОВКА КАБИНЕТА\${NC}"
    echo -e "\${CYAN}╚═══════════════════════════════════════════════════════════════════════════════╝\${NC}"

    if ! sync_cabinet_repo; then
        return 1
    fi
    if ! deploy_cabinet_frontend; then
        return 1
    fi
    do_cabinet_status
}

do_cabinet_update() {
    preflight_action "cabinet-update" true true true true true 512 "\$CABINET_DIR" true || return \$?
    echo
    echo -e "\${CYAN}╔═══════════════════════════════════════════════════════════════════════════════╗\${NC}"
    echo -e "\${WHITE}🔄 ОБНОВЛЕНИЕ КАБИНЕТА\${NC}"
    echo -e "\${CYAN}╚═══════════════════════════════════════════════════════════════════════════════╝\${NC}"

    if ! sync_cabinet_repo; then
        return 1
    fi
    if ! deploy_cabinet_frontend; then
        return 1
    fi
    do_cabinet_status
}

do_cabinet_status() {
    preflight_action "cabinet-status" false false false true true 128 "\$CABINET_DIR" false || return \$?
    echo
    echo -e "\${CYAN}╔═══════════════════════════════════════════════════════════════════════════════╗\${NC}"
    echo -e "\${WHITE}📊 СТАТУС КАБИНЕТА\${NC}"
    echo -e "\${CYAN}╚═══════════════════════════════════════════════════════════════════════════════╝\${NC}"

    if [ -d "\$CABINET_DIR/.git" ]; then
        local branch=""
        local local_hash=""
        local local_date=""
        local dirty="clean"
        branch=\$(git -C "\$CABINET_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "?")
        local_hash=\$(git -C "\$CABINET_DIR" rev-parse --short HEAD 2>/dev/null || echo "?")
        local_date=\$(git -C "\$CABINET_DIR" log -1 --date=short --format=%ad 2>/dev/null || echo "?")
        [ -n "\$(git -C "\$CABINET_DIR" status --porcelain 2>/dev/null)" ] && dirty="dirty"

        git -C "\$CABINET_DIR" fetch --prune origin >/dev/null 2>&1 || true
        local remote_hash=""
        local behind="0"
        remote_hash=\$(git -C "\$CABINET_DIR" rev-parse --short "origin/\$CABINET_BRANCH" 2>/dev/null || echo "?")
        behind=\$(git -C "\$CABINET_DIR" rev-list --count "HEAD..origin/\$CABINET_BRANCH" 2>/dev/null || echo "0")

        echo -e "\${WHITE}Repo:\${NC} \${CYAN}\$CABINET_DIR\${NC}"
        echo -e "\${WHITE}Branch:\${NC} \${CYAN}\$branch\${NC}"
        echo -e "\${WHITE}Local:\${NC} \${CYAN}\$local_hash\${NC} | \$local_date"
        echo -e "\${WHITE}Remote:\${NC} \${CYAN}\$remote_hash\${NC}"
        echo -e "\${WHITE}Behind:\${NC} \${CYAN}\$behind\${NC}"
        echo -e "\${WHITE}Git status:\${NC} \${CYAN}\$dirty\${NC}"
    else
        echo -e "\${YELLOW}Кабинет не установлен: \$CABINET_DIR\${NC}"
    fi

    echo
    if docker network ls --format '{{.Name}}' | grep -q "^\$CABINET_NETWORK_NAME\$"; then
        echo -e "\${WHITE}Docker network:\${NC} \${GREEN}\$CABINET_NETWORK_NAME (exists)\${NC}"
    else
        echo -e "\${WHITE}Docker network:\${NC} \${RED}\$CABINET_NETWORK_NAME (missing)\${NC}"
    fi

    if [ -f "\$CABINET_DIR/\$CABINET_COMPOSE_FILE" ]; then
        docker compose -f "\$CABINET_DIR/\$CABINET_COMPOSE_FILE" -f "\$CABINET_DIR/\$CABINET_OVERRIDE_FILE" ps "\$CABINET_SERVICE_NAME" 2>/dev/null || true
    fi

    local container_id=""
    container_id=\$(resolve_cabinet_container_id)
    if cabinet_connected_to_network "\$container_id"; then
        echo -e "\${WHITE}Network attach:\${NC} \${GREEN}cabinet_frontend -> \$CABINET_NETWORK_NAME\${NC}"
    else
        echo -e "\${WHITE}Network attach:\${NC} \${RED}cabinet_frontend is not attached to \$CABINET_NETWORK_NAME\${NC}"
    fi
}

do_cabinet_logs() {
    preflight_action "cabinet-logs" false false false true false 64 "\$CABINET_DIR" false || return \$?
    if [ ! -f "\$CABINET_DIR/\$CABINET_COMPOSE_FILE" ]; then
        echo -e "\${YELLOW}Cabinet compose не найден: \$CABINET_DIR/\$CABINET_COMPOSE_FILE\${NC}"
        return 1
    fi

    local compose_args=("-f" "\$CABINET_DIR/\$CABINET_COMPOSE_FILE")
    if [ -f "\$CABINET_DIR/\$CABINET_OVERRIDE_FILE" ]; then
        compose_args+=("-f" "\$CABINET_DIR/\$CABINET_OVERRIDE_FILE")
    fi

    echo -e "\${CYAN}📋 Логи cabinet_frontend (Ctrl+C для выхода)...\${NC}"
    docker compose "\${compose_args[@]}" logs -f --tail=200 "\$CABINET_SERVICE_NAME"
}

do_cabinet_caddy_check() {
    preflight_action "cabinet-caddy-check" false false false false false 128 "\$CABINET_CADDY_DIR" false || return \$?
    echo
    echo -e "\${CYAN}🔎 Проверка Caddy для кабинета...\${NC}"

    if [ ! -d "\$CABINET_CADDY_DIR" ]; then
        echo -e "\${YELLOW}Директория Caddy не найдена: \$CABINET_CADDY_DIR\${NC}"
        return 0
    fi

    local caddy_env="\$CABINET_CADDY_DIR/.env"
    local caddy_file="\$CABINET_CADDY_DIR/Caddyfile"

    if [ -f "\$caddy_env" ]; then
        local cabinet_domain=""
        cabinet_domain=\$(grep -E '^CABINET_DOMAIN=' "\$caddy_env" 2>/dev/null | tail -n 1 | cut -d'=' -f2- | tr -d '"' | tr -d "'" | tr -d ' ')
        if [ -n "\$cabinet_domain" ]; then
            echo -e "\${GREEN}✅ CABINET_DOMAIN задан: \$cabinet_domain\${NC}"
        else
            echo -e "\${YELLOW}⚠️  CABINET_DOMAIN не найден в \$caddy_env\${NC}"
        fi
    else
        echo -e "\${YELLOW}⚠️  Не найден файл \$caddy_env\${NC}"
    fi

    if [ -f "\$caddy_file" ]; then
        grep -q "reverse_proxy cabinet_frontend:80" "\$caddy_file" && echo -e "\${GREEN}✅ Найден reverse_proxy cabinet_frontend:80\${NC}" || echo -e "\${YELLOW}⚠️  В Caddyfile нет reverse_proxy cabinet_frontend:80\${NC}"
        grep -q "handle /api/\\*" "\$caddy_file" && echo -e "\${GREEN}✅ Найден блок handle /api/*\${NC}" || echo -e "\${YELLOW}⚠️  В Caddyfile нет блока handle /api/*\${NC}"
    else
        echo -e "\${YELLOW}⚠️  Не найден файл \$caddy_file\${NC}"
    fi

    echo -e "\${WHITE}Подсказка:\${NC} cd \$CABINET_CADDY_DIR && docker compose up -d --force-recreate caddy"
}

do_cabinet_caddy_recreate() {
    preflight_action "cabinet-caddy-recreate" true false false true false 128 "\$CABINET_CADDY_DIR" true || return \$?
    if [ ! -f "\$CABINET_CADDY_DIR/docker-compose.yml" ]; then
        echo -e "\${YELLOW}Caddy compose не найден в \$CABINET_CADDY_DIR\${NC}"
        return 1
    fi
    echo -e "\${CYAN}🔄 Пересоздание Caddy...\${NC}"
    if (cd "\$CABINET_CADDY_DIR" && docker compose up -d --force-recreate caddy); then
        echo -e "\${GREEN}✅ Caddy пересоздан\${NC}"
    else
        echo -e "\${RED}❌ Не удалось пересоздать Caddy\${NC}"
        return 1
    fi
}

cabinet_menu() {
    set +e
    while true; do
        clear
        echo
        echo -e "\${WHITE}Кабинет:\${NC}"
        echo -e "  \${CYAN}1)\${NC} 📥 Установить кабинет"
        echo -e "  \${CYAN}2)\${NC} 🔄 Обновить кабинет"
        echo -e "  \${CYAN}3)\${NC} 📊 Статус кабинета"
        echo -e "  \${CYAN}4)\${NC} 📋 Логи кабинета"
        echo -e "  \${CYAN}5)\${NC} 🌐 Проверка Caddy (cabinet)"
        echo -e "  \${CYAN}6)\${NC} 🔁 Пересоздать Caddy"
        echo -e "  \${CYAN}0)\${NC} ↩ Назад"
        echo
        read -p "Ваш выбор: " cabinet_choice
        case \$cabinet_choice in
            1) do_cabinet_install; read -p "Нажмите Enter..." ;;
            2) do_cabinet_update; read -p "Нажмите Enter..." ;;
            3) do_cabinet_status; read -p "Нажмите Enter..." ;;
            4) do_cabinet_logs ;;
            5) do_cabinet_caddy_check; read -p "Нажмите Enter..." ;;
            6) do_cabinet_caddy_recreate; read -p "Нажмите Enter..." ;;
            0) return ;;
            *) echo -e "\${RED}Неверный выбор\${NC}"; sleep 1 ;;
        esac
    done
}

do_install() {
    preflight_action "install" true false true false false 256 "\$INSTALL_DIR" true || return \$?
    local INSTALLER_DIR="\$INSTALL_DIR/.installer"
    
    echo -e "\${PURPLE}╔══════════════════════════════════════════════════════════════╗\${NC}"
    echo -e "\${PURPLE}║           🔧 УСТАНОВЩИК БОТА 🔧                              ║\${NC}"
    echo -e "\${PURPLE}╚══════════════════════════════════════════════════════════════╝\${NC}"
    echo
    
    if [ -d "\$INSTALLER_DIR" ] && [ -f "\$INSTALLER_DIR/install.sh" ]; then
        local VERSION=\$(cat "\$INSTALLER_DIR/VERSION" 2>/dev/null || echo "?")
        echo -e "\${GREEN}✅ Найдены локальные скрипты установщика (v\$VERSION)\${NC}"
        echo
        echo -e "\${WHITE}Варианты:\${NC}"
        echo -e "  \${CYAN}1)\${NC} Запустить установщик"
        echo -e "  \${CYAN}2)\${NC} Обновить скрипты установщика"
        echo -e "  \${CYAN}3)\${NC} Скачать и запустить с GitHub"
        echo -e "  \${CYAN}0)\${NC} Отмена"
        echo
        read -p "Ваш выбор [1]: " choice
        choice=\${choice:-1}
        
        case \$choice in
            1)
                echo -e "\${CYAN}🚀 Запуск установщика...\${NC}"
                sudo bash "\$INSTALLER_DIR/install.sh"
                ;;
            2)
                echo -e "\${CYAN}📥 Обновление скриптов...\${NC}"
                local TEMP_DIR=\$(mktemp -d)
                git clone --depth 1 --single-branch --branch spiderman https://github.com/RamaPulya/bot_auto_install.git "\$TEMP_DIR" 2>/dev/null
                if [ -d "\$TEMP_DIR/scripts" ]; then
                    rm -rf "\$INSTALLER_DIR"
                    cp -r "\$TEMP_DIR/scripts" "\$INSTALLER_DIR"
                    chmod +x "\$INSTALLER_DIR"/*.sh 2>/dev/null
                    chmod +x "\$INSTALLER_DIR"/lib/*.sh 2>/dev/null
                    local NEW_VER=\$(cat "\$INSTALLER_DIR/VERSION" 2>/dev/null || echo "?")
                    echo -e "\${GREEN}✅ Обновлено до v\$NEW_VER\${NC}"
                fi
                rm -rf "\$TEMP_DIR"
                ;;
            3)
                echo -e "\${CYAN}📥 Скачивание с GitHub...\${NC}"
                curl -fsSL https://raw.githubusercontent.com/RamaPulya/bot_auto_install/spiderman/scripts/quick-install.sh | sudo bash
                ;;
            0)
                return
                ;;
        esac
    else
        echo -e "\${YELLOW}⚠️  Локальные скрипты не найдены\${NC}"
        echo
        echo -e "\${WHITE}Варианты:\${NC}"
        echo -e "  \${CYAN}1)\${NC} Скачать и запустить с GitHub"
        echo -e "  \${CYAN}2)\${NC} Скачать скрипты локально"
        echo -e "  \${CYAN}0)\${NC} Отмена"
        echo
        read -p "Ваш выбор [1]: " choice
        choice=\${choice:-1}
        
        case \$choice in
            1)
                curl -fsSL https://raw.githubusercontent.com/RamaPulya/bot_auto_install/spiderman/scripts/quick-install.sh | sudo bash
                ;;
            2)
                mkdir -p "\$INSTALLER_DIR"
                local TEMP_DIR=\$(mktemp -d)
                git clone --depth 1 --single-branch --branch spiderman https://github.com/RamaPulya/bot_auto_install.git "\$TEMP_DIR" 2>/dev/null
                if [ -d "\$TEMP_DIR/scripts" ]; then
                    cp -r "\$TEMP_DIR/scripts"/* "\$INSTALLER_DIR/"
                    chmod +x "\$INSTALLER_DIR"/*.sh 2>/dev/null
                    chmod +x "\$INSTALLER_DIR"/lib/*.sh 2>/dev/null
                    echo -e "\${GREEN}✅ Скрипты сохранены в \$INSTALLER_DIR\${NC}"
                fi
                rm -rf "\$TEMP_DIR"
                ;;
            0)
                return
                ;;
        esac
    fi
}

do_uninstall() {
    check_install_dir
    preflight_action "uninstall" true false true true false 128 "\$INSTALL_DIR" true || return \$?
    echo
    echo -e "\${RED}═══════════════════════════════════════════════════════════════\${NC}"
    echo -e "\${WHITE}🗑️  УДАЛЕНИЕ БОТА\${NC}"
    echo -e "\${RED}═══════════════════════════════════════════════════════════════\${NC}"
    echo
    echo -e "\${YELLOW}⚠️  ВНИМАНИЕ! Это действие удалит:\${NC}"
    echo -e "   - Docker контейнеры бота"
    echo -e "   - Данные PostgreSQL и Redis (опционально)"
    echo
    
    read -p "Введите 'yes' для подтверждения: " CONFIRM
    if [ "\$CONFIRM" != "yes" ]; then
        echo -e "\${GREEN}Удаление отменено\${NC}"
        return
    fi
    
    echo -e "\${CYAN}🛑 Остановка контейнеров...\${NC}"
    docker compose -f "\$COMPOSE_FILE" down
    
    read -p "Удалить данные (volumes)? (y/n): " -n 1 -r
    echo
    if [[ \$REPLY =~ ^[Yy]\$ ]]; then
        echo -e "\${CYAN}💾 Удаление volumes...\${NC}"
        docker compose -f "\$COMPOSE_FILE" down -v
        docker volume ls -q | grep -E "bedolaga|remnawave.*bot" | xargs -r docker volume rm 2>/dev/null
        echo -e "\${GREEN}✅ Volumes удалены\${NC}"
    fi
    
    if [ -f "/usr/local/bin/bot" ]; then
        rm -f /usr/local/bin/bot
        echo -e "\${GREEN}✅ Команда 'bot' удалена\${NC}"
    fi
    
    echo
    echo -e "\${GREEN}✅ Удаление завершено\${NC}"
    echo -e "\${YELLOW}Директория \$INSTALL_DIR оставлена. Удалите вручную:\${NC}"
    echo -e "\${CYAN}rm -rf \$INSTALL_DIR\${NC}"
}

show_version() {
    check_install_dir
    preflight_action "version" false false false false false 64 "\$INSTALL_DIR" false || return \$?

    local INSTALLER_VERSION="?"
    if [ -f "\$INSTALLER_DIR/VERSION" ]; then
        INSTALLER_VERSION=\$(cat "\$INSTALLER_DIR/VERSION" 2>/dev/null || echo "?")
    fi

    local LOCAL_HASH="?"
    local LOCAL_DATE="?"
    local REMOTE_HASH="?"
    local REMOTE_DATE="?"
    local BEHIND="?"

    if [ -d ".git" ]; then
        git fetch origin "\$REPO_BRANCH" >/dev/null 2>&1 || true
        LOCAL_HASH=\$(git rev-parse --short HEAD 2>/dev/null || echo "?")
        LOCAL_DATE=\$(git log -1 --date=short --format=%ad 2>/dev/null || echo "?")
        REMOTE_HASH=\$(git rev-parse --short "origin/\$REPO_BRANCH" 2>/dev/null || echo "?")
        REMOTE_DATE=\$(git log -1 "origin/\$REPO_BRANCH" --date=short --format=%ad 2>/dev/null || echo "?")
        BEHIND=\$(git rev-list --count "HEAD..origin/\$REPO_BRANCH" 2>/dev/null || echo "0")
    fi

    echo
    echo -e "\${CYAN}═══════════════════════════════════════════════════════════════\${NC}"
    echo -e "\${WHITE}ℹ️ Версии\${NC}"
    echo -e "\${CYAN}═══════════════════════════════════════════════════════════════\${NC}"
    echo -e "\${WHITE}Installer:\${NC} \${CYAN}v\$INSTALLER_VERSION\${NC}"
    echo -e "\${WHITE}Branch:\${NC} \${CYAN}\$REPO_BRANCH\${NC}"
    echo -e "\${WHITE}Local:\${NC} \${CYAN}\$LOCAL_HASH\${NC} | \$LOCAL_DATE"
    echo -e "\${WHITE}Remote:\${NC} \${CYAN}\$REMOTE_HASH\${NC} | \$REMOTE_DATE"
    echo -e "\${WHITE}Behind:\${NC} \${CYAN}\$BEHIND\${NC}"
}

show_menu() {
    clear
    echo -e "\${PURPLE}╔══════════════════════════════════════════════════════════════╗\${NC}"
    echo -e "\${PURPLE}║        🤖 REMNAWAVE BEDOLAGA BOT — УПРАВЛЕНИЕ 🤖             ║\${NC}"
    echo -e "\${PURPLE}╚══════════════════════════════════════════════════════════════╝\${NC}"
    echo
    echo -e "\${WHITE}Директория:\${NC} \${CYAN}\$INSTALL_DIR\${NC}"
    echo
    
    if docker ps --format '{{.Names}}' | grep -q "remnawave_bot"; then
        echo -e "\${WHITE}Статус:\${NC} \${GREEN}● Бот работает\${NC}"
    else
        echo -e "\${WHITE}Статус:\${NC} \${RED}○ Бот остановлен\${NC}"
    fi
    echo
    
    echo -e "\${WHITE}═══════════════════════════════════════════════════════════════\${NC}"
    echo
    printf "  \${CYAN}%-3s\${NC} %-20s \${CYAN}%-3s\${NC} %s\n" "1)" "📋 Логи" "6)" "💾 Создать бэкап"
    printf "  \${CYAN}%-3s\${NC} %-20s \${CYAN}%-3s\${NC} %s\n" "2)" "📊 Статус" "7)" "🏥 Диагностика"
    printf "  \${CYAN}%-3s\${NC} %-20s \${CYAN}%-3s\${NC} %s\n" "3)" "🔄 Перезапуск" "8)" "⚙ Редактировать .env"
    printf "  \${CYAN}%-3s\${NC} %-20s \${CYAN}%-3s\${NC} %s\n" "4)" "▶ Запуск" "9)" "📦 Обновить бота"
    printf "  \${CYAN}%-3s\${NC} %-20s \${CYAN}%-3s\${NC} %s\n" "5)" "⏹ Остановка" "10)" "🛠 Обновить скрипт"
    printf "  \${CYAN}%-3s\${NC} %-20s \${CYAN}%-3s\${NC} %s\n" "i)" "🔧 Установщик" "L)" "🗑 Удаление"
    echo
    echo -e "  \${CYAN}11)\${NC} ℹ Версия"
    echo -e "  \${CYAN}12)\${NC} 🧩 Cabinet"
    echo -e "  \${CYAN}q)\${NC} 🚪 Выход"
    echo
}

interactive_menu() {
    set +e
    while true; do
        show_menu
        read -p "Ваш выбор: " choice
        
        case \$choice in
            1) do_logs ;;
            2) do_status; read -p "Нажмите Enter..." ;;
            3) do_restart; read -p "Нажмите Enter..." ;;
            4) do_start; read -p "Нажмите Enter..." ;;
            5) do_stop; read -p "Нажмите Enter..." ;;
            6) do_backup; read -p "Нажмите Enter..." ;;
            7) do_health; read -p "Нажмите Enter..." ;;
            8) do_config ;;
            9) update_menu ;;
            10) update_installer; read -p "Нажмите Enter..." ;;
            11) show_version; read -p "Нажмите Enter..." ;;
            12) cabinet_menu ;;
            i|I) do_install; read -p "Нажмите Enter..." ;;
            l|L) do_uninstall; break ;;
            q|Q|exit) echo -e "\${GREEN}До свидания!\${NC}"; exit 0 ;;
            *) echo -e "\${RED}Неверный выбор\${NC}"; sleep 1 ;;
        esac
    done
}

show_help() {
    echo -e "\${PURPLE}╔══════════════════════════════════════════════════════════════╗\${NC}"
    echo -e "\${PURPLE}║        🤖 REMNAWAVE BEDOLAGA BOT — СПРАВКА 🤖                ║\${NC}"
    echo -e "\${PURPLE}╚══════════════════════════════════════════════════════════════╝\${NC}"
    echo
    echo -e "\${WHITE}Использование:\${NC}"
    echo -e "  \${CYAN}bot\${NC}              — Интерактивное меню"
    echo -e "  \${CYAN}bot <команда>\${NC}   — Выполнить команду"
    echo
    echo -e "\${WHITE}Команды:\${NC}"
    echo -e "  \${GREEN}logs\${NC}       — Просмотр логов"
    echo -e "  \${GREEN}status\${NC}     — Статус контейнеров"
    echo -e "  \${GREEN}restart\${NC}    — Перезапуск"
    echo -e "  \${GREEN}start\${NC}      — Запуск"
    echo -e "  \${GREEN}stop\${NC}       — Остановка"
    echo -e "  \${GREEN}update\${NC}     — Обновление бота"
    echo -e "  \${GREEN}backup\${NC}     — Резервная копия"
    echo -e "  \${GREEN}health\${NC}     — Диагностика"
    echo -e "  \${GREEN}config\${NC}     — Редактировать .env"
    echo -e "  \${GREEN}install\${NC}    — Запустить установщик"
    echo -e "  \${GREEN}installer\${NC}  — Обновить скрипты установщика"
    echo -e "  \${GREEN}cabinet-install\${NC}  — Установить кабинет"
    echo -e "  \${GREEN}cabinet-update\${NC}   — Обновить кабинет"
    echo -e "  \${GREEN}cabinet-status\${NC}   — Статус кабинета"
    echo -e "  \${GREEN}cabinet-logs\${NC}     — Логи cabinet_frontend"
    echo -e "  \${GREEN}cabinet-caddy\${NC}    — Проверка Caddy для кабинета"
    echo -e "  \${GREEN}cabinet-caddy-recreate\${NC} — Пересоздать Caddy"
    echo -e "  \${GREEN}uninstall\${NC}  — Удаление бота"
}

CMD="\${1:-}"
case "\$CMD" in
    logs)       do_logs ;;
    status)     do_status ;;
    restart)    do_restart ;;
    start)      do_start ;;
    stop)       do_stop ;;
    update|upgrade) do_update ;;
    backup)     do_backup ;;
    health|check) do_health ;;
    config|edit) do_config ;;
    install|setup|reinstall) do_install ;;
    installer|installer-update) update_installer ;;
    cabinet)    cabinet_menu ;;
    cabinet-install|cabinet-setup) do_cabinet_install ;;
    cabinet-update|cabinet-upgrade) do_cabinet_update ;;
    cabinet-status|cabinet-info) do_cabinet_status ;;
    cabinet-logs|cabinet-log) do_cabinet_logs ;;
    cabinet-caddy) do_cabinet_caddy_check ;;
    cabinet-caddy-recreate) do_cabinet_caddy_recreate ;;
    uninstall|remove) do_uninstall ;;
    help|--help|-h) show_help ;;
    version|ver) show_version ;;
    "")         interactive_menu ;;
    *)
        echo -e "\${RED}❌ Неизвестная команда: \$CMD\${NC}"
        echo "Используйте: bot help"
        exit 1
        ;;
esac
BOTEOF

    then
        echo -e "${RED}❌ Не удалось записать /usr/local/bin/bot${NC}"
        return 1
    fi

    if ! chmod +x /usr/local/bin/bot; then
        echo -e "${RED}❌ Не удалось выдать права на /usr/local/bin/bot${NC}"
        return 1
    fi
    if [ -d "/usr/bin" ]; then
        ln -sfn /usr/local/bin/bot /usr/bin/bot 2>/dev/null || true
    fi
    
    echo -e "${GREEN}✅ Команда 'bot' установлена!${NC}"
    echo
    echo -e "${WHITE}Теперь доступно:${NC}"
    echo -e "  ${CYAN}bot${NC}        — интерактивное меню"
    echo -e "  ${CYAN}bot help${NC}   — справка"
}

# Функция обновления скриптов установщика
update_installer() {
    preflight_action "installer-update" true true true false true 256 "$INSTALL_DIR" true || return $?
    echo
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}🔧 ОБНОВЛЕНИЕ СКРИПТОВ УСТАНОВЩИКА${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    
    INSTALLER_DIR="$INSTALL_DIR/.installer"
    
    echo -e "${CYAN}📥 Скачивание скриптов установщика...${NC}"
    
    TEMP_DIR=$(mktemp -d)
    git clone --depth 1 --single-branch --branch spiderman https://github.com/RamaPulya/bot_auto_install.git "$TEMP_DIR" 2>/dev/null
    
    if [ -d "$TEMP_DIR/scripts" ]; then
        if [ ! -d "$INSTALL_DIR" ] || [ ! -w "$INSTALL_DIR" ]; then
            echo -e "${RED}❌ Нет прав на запись в $INSTALL_DIR. Запустите bot от root (sudo).${NC}"
            rm -rf "$TEMP_DIR"
            return 1
        fi

        rm -rf "$INSTALLER_DIR" 2>/dev/null || true
        if ! cp -r "$TEMP_DIR/scripts" "$INSTALLER_DIR"; then
            echo -e "${RED}❌ Не удалось обновить скрипты установщика (ошибка записи в $INSTALLER_DIR)${NC}"
            rm -rf "$TEMP_DIR"
            return 1
        fi
        chmod +x "$INSTALLER_DIR"/*.sh 2>/dev/null
        chmod +x "$INSTALLER_DIR"/lib/*.sh 2>/dev/null
        
        VERSION=$(cat "$INSTALLER_DIR/VERSION" 2>/dev/null || echo "?")
        echo -e "${GREEN}✅ Скрипты установщика обновлены (v$VERSION)${NC}"
        if [ -x "$INSTALLER_DIR/upgrade.sh" ]; then
            if BOT_SKIP_LOCK=true FORCE_INSTALL_BOT_COMMAND=true bash "$INSTALLER_DIR/upgrade.sh" --install-bot-command --force >/dev/null 2>&1; then
                echo -e "${GREEN}✅ Команда bot пересоздана автоматически${NC}"
            else
                echo -e "${YELLOW}⚠️  Не удалось пересоздать команду bot автоматически${NC}"
                echo -e "${YELLOW}   Выполните: bash $INSTALLER_DIR/upgrade.sh --install-bot-command --force${NC}"
            fi
        fi
    else
        echo -e "${RED}❌ Ошибка загрузки${NC}"
        return 1
    fi
    
    rm -rf "$TEMP_DIR"
}

# ═══════════════════════════════════════════════════════════════
# ОСНОВНОЙ КОД
# ═══════════════════════════════════════════════════════════════

INSTALL_DIR=$(find_install_dir)

if [ -z "$INSTALL_DIR" ]; then
    echo -e "${RED}❌ Директория бота не найдена!${NC}"
    echo -e "${YELLOW}Проверьте /opt/remnawave-bedolaga-telegram-bot${NC}"
    exit 1
fi

# Определяем compose файл
COMPOSE_FILE="docker-compose.yml"
if [ -f "$INSTALL_DIR/docker-compose.local.yml" ]; then
    COMPOSE_FILE="docker-compose.local.yml"
elif [ -f "$INSTALL_DIR/.install_config" ]; then
    source "$INSTALL_DIR/.install_config" 2>/dev/null
fi

# Проверяем наличие external network в compose файле
if command -v docker >/dev/null 2>&1 && grep -q "external: true" "$INSTALL_DIR/$COMPOSE_FILE" 2>/dev/null; then
    NETWORK_NAME=$(grep -A1 "external: true" "$INSTALL_DIR/$COMPOSE_FILE" | grep "name:" | awk '{print $2}' || echo "remnawave-network")
    if ! docker network ls --format '{{.Name}}' | grep -q "^${NETWORK_NAME}$"; then
        echo -e "${YELLOW}⚠️  Обнаружена external network: $NETWORK_NAME${NC}"
        echo -e "${YELLOW}   Сеть не найдена. Создаём...${NC}"
        docker network create "$NETWORK_NAME" 2>/dev/null || true
    fi
fi

if [ "${1:-}" = "--install-bot-command" ]; then
    if [ "${2:-}" = "--force" ]; then
        FORCE_INSTALL_BOT_COMMAND="true"
    fi
    install_bot_command
    exit $?
fi

echo -e "${PURPLE}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║     🔄 REMNAWAVE BEDOLAGA BOT - ОБНОВЛЕНИЕ 🔄               ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${WHITE}📁 Директория:${NC} ${CYAN}$INSTALL_DIR${NC}"
echo

# Проверка наличия команды bot
if [ -f "/usr/local/bin/bot" ]; then
    echo -e "${GREEN}✅ Команда 'bot' установлена${NC}"
else
    echo -e "${YELLOW}⚠️  Команда 'bot' не найдена${NC}"
fi

# Главное меню
echo
echo -e "${WHITE}Что вы хотите сделать?${NC}"
echo
echo -e "  ${CYAN}1)${NC} 📦 Обновить бота (git pull + rebuild)"
echo -e "  ${CYAN}2)${NC} 🎮 Установить команду 'bot'"
echo -e "  ${CYAN}3)${NC} 🔧 Обновить скрипты установщика"
echo -e "  ${CYAN}4)${NC} 📋 Всё вместе (рекомендуется)"
echo -e "  ${CYAN}0)${NC} Отмена"
echo
read -p "Ваш выбор [4]: " CHOICE < /dev/tty
CHOICE=${CHOICE:-4}

case $CHOICE in
    1)
        upgrade_bot
        ;;
    2)
        install_bot_command
        ;;
    3)
        update_installer
        ;;
    4)
        upgrade_bot
        install_bot_command
        update_installer
        ;;
    0)
        echo -e "${YELLOW}Отменено${NC}"
        exit 0
        ;;
    *)
        echo -e "${RED}Неверный выбор${NC}"
        exit 1
        ;;
esac

# Финальное сообщение
echo
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     ✅ ОБНОВЛЕНИЕ ЗАВЕРШЕНО!                                 ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo
echo -e "${WHITE}Используйте команду ${CYAN}bot${NC} для управления ботом${NC}"
echo
