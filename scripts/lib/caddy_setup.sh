#!/bin/bash

# ===============================================
# CADDY SETUP
# ===============================================

setup_caddy() {
    USE_CADDY="false"

    if [ -z "$WEBHOOK_DOMAIN" ] && [ -z "$MINIAPP_DOMAIN" ]; then
        print_info "Домены не указаны, пропускаем настройку Caddy"
        return 0
    fi

    if [ "$PANEL_INSTALLED_LOCALLY" != "true" ]; then
        return 0
    fi

    local caddy_dir=""
    local candidates=("/opt/caddy-remnawave" "/root/caddy-remnawave")

    for candidate in "${candidates[@]}"; do
        if [ -f "$candidate/Caddyfile" ] && [ -f "$candidate/docker-compose.yml" ]; then
            caddy_dir="$candidate"
            break
        fi
    done

    if [ -z "$caddy_dir" ]; then
        print_info "Caddy для панели не найден (ожидалось /opt/caddy-remnawave)"
        return 0
    fi

    print_step "Настройка Caddy"
    if ! confirm "Найден Caddy в $caddy_dir. Настроить Caddy для бота?"; then
        print_info "Пропускаем настройку Caddy"
        return 0
    fi

    CADDY_DIR="$caddy_dir"
    CADDY_FILE="$CADDY_DIR/Caddyfile"
    CADDY_COMPOSE="$CADDY_DIR/docker-compose.yml"

    if [ ! -f "$CADDY_FILE" ]; then
        print_warning "Caddyfile не найден: $CADDY_FILE"
        return 0
    fi

    cp "$CADDY_FILE" "$CADDY_FILE.backup.$(date +%Y%m%d_%H%M%S)"
    update_caddyfile
    update_caddy_compose
    restart_caddy

    USE_CADDY="true"
}

update_caddyfile() {
    if [ -z "$WEBHOOK_DOMAIN" ] && [ -z "$MINIAPP_DOMAIN" ]; then
        return 0
    fi

    if grep -q "# === BEGIN Bedolaga Bot ===" "$CADDY_FILE" 2>/dev/null; then
        sed -i '/# === BEGIN Bedolaga Bot ===/,/# === END Bedolaga Bot ===/d' "$CADDY_FILE"
    fi

    local block_file
    block_file=$(mktemp)

    {
        echo "# === BEGIN Bedolaga Bot ==="
        if [ -n "$WEBHOOK_DOMAIN" ]; then
            cat << EOF
https://${WEBHOOK_DOMAIN} {
    reverse_proxy remnawave_bot:8080 {
        header_up X-Real-IP {remote_host}
        header_up Host {host}
        header_up X-Forwarded-Proto {scheme}
    }
    log {
        output file /var/log/caddy/bedolaga-bot.log {
            roll_size 30mb
            roll_keep 10
            roll_keep_for 720h
        }
    }
}
EOF
        fi
        if [ -n "$MINIAPP_DOMAIN" ]; then
            cat << EOF
https://${MINIAPP_DOMAIN} {
    handle /miniapp/* {
        reverse_proxy remnawave_bot:8080 {
            header_up X-Real-IP {remote_host}
            header_up Host {host}
            header_up X-Forwarded-Proto {scheme}
        }
    }
    handle /app-config.json {
        reverse_proxy remnawave_bot:8080 {
            header_up X-Real-IP {remote_host}
            header_up Host {host}
            header_up X-Forwarded-Proto {scheme}
        }
    }
    handle {
        root * /var/www/bedolaga-miniapp
        try_files {path} /index.html
        file_server
    }
    log {
        output file /var/log/caddy/bedolaga-miniapp.log {
            roll_size 30mb
            roll_keep 10
            roll_keep_for 720h
        }
    }
}
EOF
        fi
        echo "# === END Bedolaga Bot ==="
        echo ""
    } > "$block_file"

    local insert_line
    insert_line=$(grep -n "^:443" "$CADDY_FILE" | head -1 | cut -d: -f1)

    if [ -n "$insert_line" ]; then
        head -n $((insert_line - 1)) "$CADDY_FILE" > "$CADDY_FILE.tmp"
        cat "$block_file" >> "$CADDY_FILE.tmp"
        tail -n +$((insert_line)) "$CADDY_FILE" >> "$CADDY_FILE.tmp"
        mv "$CADDY_FILE.tmp" "$CADDY_FILE"
    else
        cat "$block_file" >> "$CADDY_FILE"
    fi

    rm -f "$block_file"
    print_success "Caddyfile обновлен"
}

update_caddy_compose() {
    if [ -z "$MINIAPP_DOMAIN" ]; then
        return 0
    fi

    if [ ! -f "$CADDY_COMPOSE" ]; then
        print_warning "docker-compose.yml Caddy не найден: $CADDY_COMPOSE"
        return 0
    fi

    local miniapp_mount="${INSTALL_DIR}/miniapp:/var/www/bedolaga-miniapp:ro"
    if grep -q "/var/www/bedolaga-miniapp" "$CADDY_COMPOSE" 2>/dev/null; then
        return 0
    fi

    local insert_line
    insert_line=$(grep -n "Caddyfile" "$CADDY_COMPOSE" | head -1 | cut -d: -f1)

    if [ -n "$insert_line" ]; then
        head -n "$insert_line" "$CADDY_COMPOSE" > "$CADDY_COMPOSE.tmp"
        echo "      - ${miniapp_mount}" >> "$CADDY_COMPOSE.tmp"
        tail -n +$((insert_line + 1)) "$CADDY_COMPOSE" >> "$CADDY_COMPOSE.tmp"
        mv "$CADDY_COMPOSE.tmp" "$CADDY_COMPOSE"
        print_success "Miniapp volume добавлен в docker-compose Caddy"
    else
        print_warning "Не удалось найти секцию volumes в docker-compose Caddy"
    fi
}

restart_caddy() {
    print_info "Перезапуск Caddy..."
    cd "$CADDY_DIR"
    docker compose up -d 2>/dev/null || docker-compose up -d 2>/dev/null || true
}
