#!/bin/bash

# ===============================================
# 🛠️  УТИЛИТЫ И ФУНКЦИИ ВЫВОДА
# ===============================================

# Цвета для вывода
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export PURPLE='\033[0;35m'
export CYAN='\033[0;36m'
export WHITE='\033[1;37m'
export NC='\033[0m' # No Color

AUTH_ENV_LOADED=0
INSTALLER_ENV_FILE="${INSTALLER_ENV_FILE:-/root/.config/bedolaga/installer.env}"

load_installer_auth_env() {
    if [ "$AUTH_ENV_LOADED" -eq 1 ]; then
        return 0
    fi

    local env_file=""
    for env_file in "$INSTALLER_ENV_FILE" "/etc/bedolaga/installer.env"; do
        if [ -n "$env_file" ] && [ -r "$env_file" ]; then
            # shellcheck disable=SC1090
            source "$env_file" || true
            break
        fi
    done

    AUTH_ENV_LOADED=1
}

build_auth_repo_url() {
    local repo_url="$1"
    load_installer_auth_env

    if [ -n "${GITHUB_TOKEN:-}" ] && [[ "$repo_url" == https://github.com/* ]]; then
        echo "${repo_url/https:\/\/github.com\//https:\/\/${GITHUB_TOKEN}@github.com\/}"
    else
        echo "$repo_url"
    fi
}

git_with_auth() {
    load_installer_auth_env
    if [ -n "${GITHUB_TOKEN:-}" ]; then
        if GIT_TERMINAL_PROMPT=0 git \
            -c credential.helper= \
            -c core.askPass=true \
            -c "url.https://x-access-token:${GITHUB_TOKEN}@github.com/.insteadOf=https://github.com/" \
            "$@"; then
            return 0
        fi
    fi
    GIT_TERMINAL_PROMPT=0 git \
        -c credential.helper= \
        -c core.askPass=true \
        "$@"
}

curl_with_auth() {
    load_installer_auth_env
    if [ -n "${GITHUB_TOKEN:-}" ]; then
        curl -fsSL -H "Authorization: Bearer ${GITHUB_TOKEN}" "$@"
    else
        curl -fsSL "$@"
    fi
}

# Функции вывода
print_banner() {
    clear
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                                                              ║"
    echo "║     🤖 REMNAWAVE BEDOLAGA BOT - АВТОУСТАНОВЩИК 🤖           ║"
    echo "║                                                              ║"
    echo "║     Telegram бот для управления VPN подписками              ║"
    echo "║     через Remnawave API                                     ║"
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_step() {
    echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}✅ $1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Улучшенная функция подтверждения (y/n)
confirm() {
    local prompt="${1:-Продолжить?}"
    local default="${2:-n}"
    local response
    local suffix="(y/n)"

    if [ "$default" = "y" ]; then
        suffix="(Y/n)"
    elif [ "$default" = "n" ]; then
        suffix="(y/N)"
    fi
    
    while true; do
        read -p "$prompt $suffix: " -n 1 response < /dev/tty
        echo
        if [ -z "$response" ]; then
            response="$default"
        fi
        case "$response" in
            [yY]) return 0 ;;
            [nN]) return 1 ;;
            *)
                echo -e "${YELLOW}   Пожалуйста, введите 'y' или 'n'${NC}"
                ;;
        esac
    done
}

setup_installer_auth_token() {
    local env_file="${INSTALLER_ENV_FILE:-/root/.config/bedolaga/installer.env}"
    local token_input=""

    load_installer_auth_env

    echo
    echo -e "${WHITE}Доступ к private репозиториям GitHub:${NC}"
    if [ -n "${GITHUB_TOKEN:-}" ]; then
        echo -e "${GREEN}✅ Токен уже найден${NC} (${env_file})"
        if ! confirm "Обновить токен?" "n"; then
            print_info "Оставляем текущий токен"
            return 0
        fi
    else
        echo -e "${YELLOW}⚠️  Токен не найден${NC}"
        if ! confirm "Настроить GITHUB_TOKEN сейчас?" "y"; then
            print_warning "Пропускаем настройку токена. Для private репо clone/fetch могут не работать."
            return 0
        fi
    fi

    read -r -s -p "Введите GITHUB_TOKEN (или Enter для пропуска): " token_input < /dev/tty
    echo
    if [ -z "$token_input" ]; then
        print_warning "Токен не введён. Настройка пропущена."
        return 0
    fi

    mkdir -p "$(dirname "$env_file")"
    umask 177
    cat > "$env_file" << EOF
# Bedolaga installer auth
GITHUB_TOKEN=$token_input
EOF
    chmod 600 "$env_file" 2>/dev/null || true

    export GITHUB_TOKEN="$token_input"
    AUTH_ENV_LOADED=1
    print_success "Токен сохранён: $env_file"
}

# Генерация безопасного случайного токена (hex)
generate_token() {
    openssl rand -hex 32
}

# Генерация безопасного пароля (только буквы и цифры)
# ИСПРАВЛЕНИЕ БАГА: используем /dev/urandom напрямую для гарантированной длины
generate_safe_password() {
    local length="${1:-24}"
    tr -dc 'A-Za-z0-9' </dev/urandom | head -c "$length"
}

# Валидация домена
validate_domain() {
    local domain=$1
    
    # Проверка что домен содержит точку
    if [[ ! "$domain" =~ \. ]]; then
        return 1
    fi
    
    # Проверка что домен не содержит http:// или https://
    if [[ "$domain" =~ ^https?:// ]]; then
        return 1
    fi
    
    # Проверка формата домена (буквы, цифры, точки, дефисы)
    if [[ ! "$domain" =~ ^[a-zA-Z0-9][a-zA-Z0-9.-]+[a-zA-Z0-9]$ ]]; then
        return 1
    fi
    
    return 0
}

# Проверка DNS записи домена
check_domain_dns() {
    local domain=$1
    
    # Получаем IPv4 адрес сервера (принудительно IPv4)
    local server_ip=$(curl -4 -s ifconfig.me 2>/dev/null || curl -4 -s icanhazip.com 2>/dev/null || curl -4 -s ipv4.icanhazip.com 2>/dev/null)
    
    # Получаем IPv4 адрес домена (A-запись, не AAAA)
    local domain_ip=$(dig +short -t A "$domain" 2>/dev/null | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' | head -1)
    
    if [ -z "$server_ip" ]; then
        print_warning "Не удалось определить IPv4 сервера"
        return 1
    fi
    
    if [ -z "$domain_ip" ]; then
        print_warning "A-запись (IPv4) для $domain не найдена"
        return 1
    fi
    
    if [ "$server_ip" != "$domain_ip" ]; then
        print_warning "Домен $domain указывает на $domain_ip, а IP сервера: $server_ip"
        return 1
    fi
    
    print_success "DNS для $domain настроен правильно ($domain_ip)"
    return 0
}

# Проверка root прав
check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_error "Скрипт должен быть запущен от имени root!"
        echo -e "${YELLOW}Используйте: sudo bash install.sh${NC}"
        exit 1
    fi
}

# Определение дистрибутива
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        VERSION=$VERSION_ID
    else
        print_error "Не удалось определить операционную систему"
        exit 1
    fi
    
    case $OS in
        ubuntu|debian)
            print_info "Обнаружена ОС: $PRETTY_NAME"
            ;;
        *)
            print_warning "Скрипт оптимизирован для Ubuntu/Debian"
            if ! confirm "Продолжить установку?"; then
                exit 1
            fi
            ;;
    esac
}
