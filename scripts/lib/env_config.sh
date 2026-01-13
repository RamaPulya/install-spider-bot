#!/bin/bash

# ===============================================
# 📄 СОЗДАНИЕ КОНФИГУРАЦИОННЫХ ФАЙЛОВ
# ===============================================

# Создание .env файла
create_env_file() {
    print_step "Создание файла конфигурации .env"
    
    cd "$INSTALL_DIR"
    
    # Определяем ADMIN_NOTIFICATIONS_ENABLED
    if [ -n "$ADMIN_NOTIFICATIONS_CHAT_ID" ]; then
        ADMIN_NOTIFICATIONS_ENABLED="true"
    else
        ADMIN_NOTIFICATIONS_ENABLED="false"
    fi
    
    # При переустановке с сохранением volumes — используем старый пароль из бэкапа
    if [ "$KEEP_EXISTING_VOLUMES" = "true" ] && [ -n "$OLD_POSTGRES_PASSWORD" ]; then
        POSTGRES_PASSWORD="$OLD_POSTGRES_PASSWORD"
        print_info "Используется сохранённый пароль PostgreSQL"
    fi
    
    cat > .env << EOF
# ===============================================
# 🤖 REMNAWAVE BEDOLAGA BOT CONFIGURATION
# ===============================================
# Сгенерировано автоустановщиком: $(date)
# ===============================================

# ===== TELEGRAM BOT =====
BOT_TOKEN=${BOT_TOKEN}
ADMIN_IDS=${ADMIN_IDS}
SUPPORT_USERNAME=@support

# ===== УВЕДОМЛЕНИЯ =====
ADMIN_NOTIFICATIONS_ENABLED=${ADMIN_NOTIFICATIONS_ENABLED}
EOF

    # Добавляем ADMIN_NOTIFICATIONS_CHAT_ID только если он не пустой
    if [ -n "$ADMIN_NOTIFICATIONS_CHAT_ID" ]; then
        echo "ADMIN_NOTIFICATIONS_CHAT_ID=${ADMIN_NOTIFICATIONS_CHAT_ID}" >> .env
    fi
    
    # Продолжаем .env файл - DATABASE секция
    cat >> .env << EOF

# ===== DATABASE =====
DATABASE_MODE=auto
POSTGRES_HOST=postgres
POSTGRES_PORT=5432
POSTGRES_DB=remnawave_bot
POSTGRES_USER=remnawave_user
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}

# ===== REDIS =====
REDIS_URL=redis://redis:6379/0
EOF

    # Добавляем REMNAWAVE API настройки
    cat >> .env << EOF

# ===== REMNAWAVE API =====
REMNAWAVE_API_URL=${REMNAWAVE_API_URL}
REMNAWAVE_API_KEY=${REMNAWAVE_API_KEY}
REMNAWAVE_AUTH_TYPE=${REMNAWAVE_AUTH_TYPE:-api_key}
EOF

    # Добавляем Basic Auth параметры если выбран этот тип
    if [ "$REMNAWAVE_AUTH_TYPE" == "basic_auth" ]; then
        cat >> .env << EOF
REMNAWAVE_USERNAME=${REMNAWAVE_USERNAME}
REMNAWAVE_PASSWORD=${REMNAWAVE_PASSWORD}
EOF
    fi

    # Добавляем REMNAWAVE_SECRET_KEY если указан (для eGames)
    if [ -n "$REMNAWAVE_SECRET_KEY" ]; then
        echo "REMNAWAVE_SECRET_KEY=${REMNAWAVE_SECRET_KEY}" >> .env
    fi

    cat >> .env << EOF

# ===== ПОДПИСКИ =====
TRIAL_DURATION_DAYS=3
TRIAL_TRAFFIC_LIMIT_GB=10
TRIAL_DEVICE_LIMIT=1
DEFAULT_DEVICE_LIMIT=3
MAX_DEVICES_LIMIT=15

# ===== ПЕРИОДЫ И ЦЕНЫ =====
AVAILABLE_SUBSCRIPTION_PERIODS=30,90,180
AVAILABLE_RENEWAL_PERIODS=30,90,180
PRICE_14_DAYS=7000
PRICE_30_DAYS=10000
PRICE_60_DAYS=25900
PRICE_90_DAYS=36900
PRICE_180_DAYS=69900
PRICE_360_DAYS=109900

# ===== ТРАФИК =====
TRAFFIC_SELECTION_MODE=selectable
TRAFFIC_PACKAGES_CONFIG="5:2000:false,10:3500:false,25:7000:false,50:11000:true,100:15000:true,250:17000:false,500:19000:false,1000:19500:true,0:20000:true"

# ===== РЕФЕРАЛЬНАЯ СИСТЕМА =====
REFERRAL_PROGRAM_ENABLED=true
REFERRAL_MINIMUM_TOPUP_KOPEKS=10000
REFERRAL_FIRST_TOPUP_BONUS_KOPEKS=10000
REFERRAL_INVITER_BONUS_KOPEKS=10000
REFERRAL_COMMISSION_PERCENT=25

# ===== TELEGRAM STARS =====
TELEGRAM_STARS_ENABLED=true
TELEGRAM_STARS_RATE_RUB=1.79

# ===== ИНТЕРФЕЙС =====
ENABLE_LOGO_MODE=true
LOGO_FILE=vpn_logo.png
MAIN_MENU_MODE=default
DEFAULT_LANGUAGE=ru
AVAILABLE_LANGUAGES=ru,en
LANGUAGE_SELECTION_ENABLED=true

# ===== WEBHOOK & WEB API =====
BOT_RUN_MODE=${BOT_RUN_MODE}
EOF

    # Добавляем WEBHOOK_URL только если не пустой
    if [ -n "$WEBHOOK_URL" ]; then
        echo "WEBHOOK_URL=${WEBHOOK_URL}" >> .env
    fi
    
    cat >> .env << EOF
WEBHOOK_PATH=/webhook
WEBHOOK_SECRET_TOKEN=${WEBHOOK_SECRET_TOKEN}
WEBHOOK_DROP_PENDING_UPDATES=true

WEB_API_ENABLED=${WEB_API_ENABLED}
WEB_API_HOST=0.0.0.0
WEB_API_PORT=8080
WEB_API_ALLOWED_ORIGINS=*
WEB_API_DOCS_ENABLED=false
WEB_API_DEFAULT_TOKEN=${WEB_API_DEFAULT_TOKEN}

# ===== БЭКАПЫ =====
BACKUP_AUTO_ENABLED=true
BACKUP_INTERVAL_HOURS=24
BACKUP_TIME=03:00
BACKUP_MAX_KEEP=7
BACKUP_COMPRESSION=true
BACKUP_LOCATION=/app/data/backups

# ===== МОНИТОРИНГ =====
MONITORING_INTERVAL=60
MAINTENANCE_MODE=false
MAINTENANCE_AUTO_ENABLE=true
MAINTENANCE_MONITORING_ENABLED=true

# ===== ПРОВЕРКА ОБНОВЛЕНИЙ =====
VERSION_CHECK_ENABLED=true
VERSION_CHECK_REPO=RamaPulya/remnawave-bedolaga-telegram-bot
VERSION_CHECK_INTERVAL_HOURS=1

# ===== ЛОГИРОВАНИЕ =====
LOG_LEVEL=INFO
LOG_FILE=logs/bot.log
TZ=Europe/Moscow
EOF

    chmod 600 .env
    print_success "Файл .env создан"
}

# Проверка Mini App
setup_miniapp_files() {
    if [ -z "$MINIAPP_DOMAIN" ]; then
        return 0
    fi
    
    print_step "Проверка Mini App"
    
    cd "$INSTALL_DIR"
    
    # Проверяем наличие папки miniapp в репозитории бота
    if [ -d "$INSTALL_DIR/miniapp" ]; then
        print_success "Mini App найден в $INSTALL_DIR/miniapp"
        print_info "Бот будет отдавать статику Mini App на порту 8080"
    else
        print_warning "Папка miniapp не найдена в репозитории!"
        echo -e "${YELLOW}Возможно репозиторий устарел. Обновите его:${NC}"
        echo -e "${CYAN}  cd $INSTALL_DIR && git pull${NC}"
    fi
}
