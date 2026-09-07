#!/bin/bash

# ===============================================
# 🚀 REMNAWAVE BEDOLAGA BOT - АВТОУСТАНОВЩИК
# ===============================================
# Версия: 1.2.0
# Автор: Bedolaga Team
# GitHub: https://github.com/RamaPulya/spiderbot
# 
# Изменения v1.2.0:
# - Модульная архитектура (разделение на файлы)
# - Firewall настройка по запросу (опционально)
# - Поддержка eGames с REMNAWAVE_SECRET_KEY
# - Улучшенная standalone установка
# ===============================================

set -e

# Определяем директорию скрипта
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# URL репозитория бота
REPO_URL="https://github.com/RamaPulya/spiderbot.git"
# Основной поток SpiderManVPN — merge-ветка. Legacy `spiderman` доступна
# только как явный выбор в меню управления.
REPO_BRANCH="spiderman-merge"

# ===============================================
# ПОДКЛЮЧЕНИЕ МОДУЛЕЙ
# ===============================================

# Проверка наличия модулей
if [ ! -d "$SCRIPT_DIR/lib" ]; then
    echo "❌ Директория модулей не найдена: $SCRIPT_DIR/lib"
    echo "   Убедитесь что скрипт скачан полностью."
    exit 1
fi

# Список модулей
MODULES=(
    "utils.sh"
    "packages.sh"
    "interactive.sh"
    "docker_setup.sh"
    "env_config.sh"
    "nginx_setup.sh"
    "caddy_setup.sh"
    "final.sh"
)

# Подключаем модули с проверкой
for module in "${MODULES[@]}"; do
    if [ ! -f "$SCRIPT_DIR/lib/$module" ]; then
        echo "❌ Модуль не найден: $SCRIPT_DIR/lib/$module"
        echo "   Убедитесь что все файлы скачаны."
        exit 1
    fi
    source "$SCRIPT_DIR/lib/$module" || {
        echo "❌ Ошибка загрузки модуля: $module"
        exit 1
    }
done

# ===============================================
# ГЛАВНАЯ ФУНКЦИЯ
# ===============================================

main() {
    # Приветствие
    print_banner
    
    # Проверки
    check_root
    detect_os
    
    echo -e "${WHITE}Этот скрипт установит Remnawave Bedolaga Telegram Bot${NC}"
    echo -e "${YELLOW}Убедитесь, что у вас есть:${NC}"
    echo -e "  - BOT_TOKEN от @BotFather"
    echo -e "  - ADMIN_ID (ваш Telegram ID)"
    echo -e "  - REMNAWAVE_API_KEY из панели Remnawave"
    echo -e "  - DNS записи для доменов (если нужен webhook)"
    echo ""
    
    if ! confirm "Начать установку?"; then
        echo "Установка отменена"
        exit 0
    fi

    # Настройка токена для private GitHub репозиториев (опционально)
    setup_installer_auth_token
    
    # Обновление системы
    update_system
    
    # Установка базовых пакетов
    install_base_packages
    
    # Установка Docker
    install_docker
    
    # Выбор директории установки
    select_install_dir
    
    # Проверка типа установки (локальная панель или отдельный сервер)
    check_remnawave_panel
    
    # Проверка существующих volumes PostgreSQL (ДО интерактивной настройки!)
    # Это определяет, нужно ли спрашивать пароль PostgreSQL
    check_postgres_volume
    
    # Клонирование репозитория
    clone_repository
    
    # Создание директорий
    create_directories
    
    # Интерактивная настройка
    interactive_setup
    
    # Создание .env файла
    create_env_file
    
    # Настройка Mini App
    setup_miniapp_files
    
    # Настройка Caddy (если используется панель + Caddy на сервере)
    setup_caddy
    
    # Настройка Nginx (если есть домены для webhook/miniapp)
    if [ "${USE_CADDY:-false}" != "true" ]; then
        setup_nginx
    fi
    
    # Настройка Firewall (ОПЦИОНАЛЬНО)
    setup_firewall
    
    # Запуск Docker контейнеров
    start_docker
    
    # Создание скриптов управления
    create_management_scripts
    
    # Финальная информация
    print_final_info
    
    # Показать логи
    ask_show_logs
}

# ===============================================
# ЗАПУСК
# ===============================================

main "$@"
