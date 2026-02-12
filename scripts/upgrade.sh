#!/bin/bash

# ===============================================
# рџ”„ REMNAWAVE BEDOLAGA BOT - РћР‘РќРћР’Р›Р•РќРР•
# ===============================================
# РќР• РёСЃРїРѕР»СЊР·СѓРµРј set -e С‡С‚РѕР±С‹ РїСЂРѕРґРѕР»Р¶РёС‚СЊ РїСЂРё РѕС€РёР±РєР°С…

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m'
REPO_BRANCH="spiderman"

# в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђ
# Р¤РЈРќРљР¦РР (РѕРїСЂРµРґРµР»СЏРµРј Р”Рћ РёСЃРїРѕР»СЊР·РѕРІР°РЅРёСЏ)
# в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђ

# РђРІС‚РѕРѕРїСЂРµРґРµР»РµРЅРёРµ РґРёСЂРµРєС‚РѕСЂРёРё СѓСЃС‚Р°РЅРѕРІРєРё
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

# Р¤СѓРЅРєС†РёСЏ РѕР±РЅРѕРІР»РµРЅРёСЏ Р±РѕС‚Р°
upgrade_bot() {
    echo
    echo -e "${CYAN}в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђ${NC}"
    echo -e "${WHITE}рџ“¦ РћР‘РќРћР’Р›Р•РќРР• Р‘РћРўРђ${NC}"
    echo -e "${CYAN}в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђ${NC}"
    
    cd "$INSTALL_DIR"
    
    # РЎРѕР·РґР°РЅРёРµ Р±СЌРєР°РїР°
    echo -e "${CYAN}рџ’ѕ РЎРѕР·РґР°РЅРёРµ Р±СЌРєР°РїР°...${NC}"
    BACKUP_DIR="$INSTALL_DIR/data/backups"
    mkdir -p "$BACKUP_DIR"
    cp .env "$BACKUP_DIR/.env_$(date +%Y%m%d_%H%M%S)" 2>/dev/null || true
    
    # РўРµРєСѓС‰Р°СЏ РІРµСЂСЃРёСЏ
    CURRENT_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
    echo -e "${WHITE}РўРµРєСѓС‰Р°СЏ РІРµСЂСЃРёСЏ:${NC} $CURRENT_COMMIT"
    
    # РћР±РЅРѕРІР»РµРЅРёРµ РєРѕРґР°
    echo -e "${CYAN}рџ“Ґ РџРѕР»СѓС‡РµРЅРёРµ РѕР±РЅРѕРІР»РµРЅРёР№ (РІРµС‚РєР°: ${REPO_BRANCH})...${NC}"

    if [ ! -d ".git" ]; then
        echo -e "${RED}вќЊ Git-СЂРµРїРѕР·РёС‚РѕСЂРёР№ РЅРµ РЅР°Р№РґРµРЅ РІ ${INSTALL_DIR}${NC}"
        echo -e "${YELLOW}РџРѕС…РѕР¶Рµ Р±РѕС‚ СѓСЃС‚Р°РЅРѕРІР»РµРЅ РЅРµ С‡РµСЂРµР· git clone. РћР±РЅРѕРІР»РµРЅРёРµ РєРѕРґР° РїСЂРѕРїСѓС‰РµРЅРѕ.${NC}"
    else
        # Р•СЃР»Рё СЂРµРїРѕР·РёС‚РѕСЂРёР№ shallow (С‡Р°СЃС‚Р°СЏ РїСЂРёС‡РёРЅР° 'grafted' Рё РЅРµ РѕР±РЅРѕРІР»СЏРµС‚СЃСЏ) вЂ” СЂР°СЃС€РёСЂСЏРµРј РёСЃС‚РѕСЂРёСЋ
        git fetch --unshallow 2>/dev/null || true

        if ! git fetch origin "${REPO_BRANCH}" --prune --tags; then
            echo -e "${YELLOW}вљ пёЏ  РќРµ СѓРґР°Р»РѕСЃСЊ РІС‹РїРѕР»РЅРёС‚СЊ git fetch origin ${REPO_BRANCH}${NC}"
        fi

        if git show-ref --verify --quiet "refs/remotes/origin/${REPO_BRANCH}"; then
            git checkout -B "${REPO_BRANCH}" "origin/${REPO_BRANCH}" 2>/dev/null || git checkout "${REPO_BRANCH}" 2>/dev/null || true
            if ! git reset --hard "origin/${REPO_BRANCH}"; then
                echo -e "${YELLOW}вљ пёЏ  РќРµ СѓРґР°Р»РѕСЃСЊ РІС‹РїРѕР»РЅРёС‚СЊ git reset --hard origin/${REPO_BRANCH}${NC}"
            fi
        else
            echo -e "${YELLOW}вљ пёЏ  Р’ origin РЅРµС‚ РІРµС‚РєРё ${REPO_BRANCH}. РџСЂРѕРІРµСЂСЊС‚Рµ REPO_BRANCH РІ СЃРєСЂРёРїС‚Рµ.${NC}"
        fi
    fi
    
    NEW_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
    echo -e "${WHITE}РќРѕРІР°СЏ РІРµСЂСЃРёСЏ:${NC} $NEW_COMMIT"
    
    if [ "$CURRENT_COMMIT" = "$NEW_COMMIT" ]; then
        echo -e "${GREEN}вњ… РЈР¶Рµ Р°РєС‚СѓР°Р»СЊРЅР°СЏ РІРµСЂСЃРёСЏ${NC}"
    else
        echo -e "${GREEN}вњ… РљРѕРґ РѕР±РЅРѕРІР»С‘РЅ: $CURRENT_COMMIT в†’ $NEW_COMMIT${NC}"
    fi
    
    # РџРµСЂРµСЃР±РѕСЂРєР° РєРѕРЅС‚РµР№РЅРµСЂРѕРІ
    echo -e "${CYAN}рџђі РџРµСЂРµСЃР±РѕСЂРєР° РєРѕРЅС‚РµР№РЅРµСЂРѕРІ...${NC}"
    docker compose -f "$COMPOSE_FILE" down || true
    docker compose -f "$COMPOSE_FILE" build --no-cache
    
    if docker compose -f "$COMPOSE_FILE" up -d; then
        echo -e "${GREEN}вњ… Р‘РѕС‚ РѕР±РЅРѕРІР»С‘РЅ Рё Р·Р°РїСѓС‰РµРЅ${NC}"
    else
        echo -e "${RED}вљ пёЏ  РћС€РёР±РєР° Р·Р°РїСѓСЃРєР° РєРѕРЅС‚РµР№РЅРµСЂРѕРІ!${NC}"
        echo -e "${YELLOW}РџСЂРѕРІРµСЂСЊС‚Рµ: docker compose -f $COMPOSE_FILE logs${NC}"
        echo -e "${YELLOW}Р’РѕР·РјРѕР¶РЅРѕ РЅСѓР¶РЅРѕ СЃРѕР·РґР°С‚СЊ СЃРµС‚СЊ: docker network create remnawave-network${NC}"
    fi
}

# Р¤СѓРЅРєС†РёСЏ СѓСЃС‚Р°РЅРѕРІРєРё РєРѕРјР°РЅРґС‹ bot
install_bot_command() {
    echo
    echo -e "${CYAN}в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђ${NC}"
    echo -e "${WHITE}рџЋ® РЈРЎРўРђРќРћР’РљРђ РљРћРњРђРќР”Р« 'bot'${NC}"
    echo -e "${CYAN}в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђ${NC}"
    
    if [ -f "/usr/local/bin/bot" ]; then
        echo -e "${YELLOW}РљРѕРјР°РЅРґР° 'bot' СѓР¶Рµ СЃСѓС‰РµСЃС‚РІСѓРµС‚. РћР±РЅРѕРІРёС‚СЊ? (y/n) [y]:${NC}"
        read -n 1 -r REPLY < /dev/tty
        echo
        REPLY=${REPLY:-y}
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}РџСЂРѕРїСѓС‰РµРЅРѕ${NC}"
            return
        fi
    fi
    
    echo -e "${CYAN}рџ“ќ РЎРѕР·РґР°РЅРёРµ РєРѕРјР°РЅРґС‹ 'bot'...${NC}"
    
    # РЎРѕР·РґР°С‘Рј СЃРєСЂРёРїС‚ bot
    cat > /usr/local/bin/bot << BOTEOF
#!/bin/bash
# в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђ
# рџ¤– REMNAWAVE BEDOLAGA BOT - РљРћРњРђРќР”Рђ РЈРџР РђР’Р›Р•РќРРЇ
# в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђ

INSTALL_DIR="$INSTALL_DIR"
COMPOSE_FILE="$COMPOSE_FILE"
INSTALLER_DIR="$INSTALL_DIR/.installer"
REPO_BRANCH="spiderman"

# Р¦РІРµС‚Р°
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m'

check_install_dir() {
    if [ ! -d "\$INSTALL_DIR" ]; then
        echo -e "\${RED}вќЊ Р”РёСЂРµРєС‚РѕСЂРёСЏ Р±РѕС‚Р° РЅРµ РЅР°Р№РґРµРЅР°: \$INSTALL_DIR\${NC}"
        exit 1
    fi
    cd "\$INSTALL_DIR"
}

do_logs() {
    check_install_dir
    echo -e "\${CYAN}рџ“‹ Р›РѕРіРё Р±РѕС‚Р° (Ctrl+C РґР»СЏ РІС‹С…РѕРґР°)...\${NC}"
    docker compose -f "\$COMPOSE_FILE" logs -f --tail=150 bot
}

do_status() {
    check_install_dir
    echo -e "\${CYAN}в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђ\${NC}"
    echo -e "\${WHITE}рџ“Љ РЎРўРђРўРЈРЎ РљРћРќРўР•Р™РќР•Р РћР’\${NC}"
    echo -e "\${CYAN}в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђ\${NC}"
    echo
    docker compose -f "\$COMPOSE_FILE" ps
    echo
    echo -e "\${WHITE}рџ“€ РСЃРїРѕР»СЊР·РѕРІР°РЅРёРµ СЂРµСЃСѓСЂСЃРѕРІ:\${NC}"
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" 2>/dev/null | grep -E "remnawave|postgres|redis" || echo "РљРѕРЅС‚РµР№РЅРµСЂС‹ РЅРµ Р·Р°РїСѓС‰РµРЅС‹"
}

do_restart() {
    check_install_dir
    echo -e "\${CYAN}рџ”„ РџРµСЂРµР·Р°РїСѓСЃРє Р±РѕС‚Р° (РїСЂРёРјРµРЅСЏРµРј .env)...\${NC}"
    
    # РџСЂРѕРІРµСЂСЏРµРј Рё СЃРѕР·РґР°С‘Рј СЃРµС‚СЊ РµСЃР»Рё РЅСѓР¶РЅРѕ
    if grep -q "external: true" "\$COMPOSE_FILE" 2>/dev/null; then
        if ! docker network ls --format '{{.Name}}' | grep -q "remnawave-network"; then
            echo -e "\${YELLOW}РЎРѕР·РґР°С‘Рј СЃРµС‚СЊ remnawave-network...\${NC}"
            docker network create remnawave-network 2>/dev/null || true
        fi
    fi
    
    docker compose -f "\$COMPOSE_FILE" up -d --force-recreate 2>&1
    sleep 3
    if docker ps --format '{{.Names}}' | grep -q "remnawave_bot"; then
        echo -e "\${GREEN}вњ… Р‘РѕС‚ РїРµСЂРµР·Р°РїСѓС‰РµРЅ\${NC}"
    else
        echo -e "\${RED}вќЊ Р‘РѕС‚ РЅРµ Р·Р°РїСѓСЃС‚РёР»СЃСЏ! РџСЂРѕРІРµСЂСЊС‚Рµ Р»РѕРіРё: bot logs\${NC}"
    fi
}

do_start() {
    check_install_dir
    echo -e "\${CYAN}в–¶пёЏ  Р—Р°РїСѓСЃРє Р±РѕС‚Р°...\${NC}"
    
    # РџСЂРѕРІРµСЂСЏРµРј Рё СЃРѕР·РґР°С‘Рј СЃРµС‚СЊ РµСЃР»Рё РЅСѓР¶РЅРѕ
    if grep -q "external: true" "\$COMPOSE_FILE" 2>/dev/null; then
        if ! docker network ls --format '{{.Name}}' | grep -q "remnawave-network"; then
            echo -e "\${YELLOW}РЎРѕР·РґР°С‘Рј СЃРµС‚СЊ remnawave-network...\${NC}"
            docker network create remnawave-network 2>/dev/null || true
        fi
    fi
    
    if docker compose -f "\$COMPOSE_FILE" up -d 2>&1; then
        sleep 3
        if docker ps --format '{{.Names}}' | grep -q "remnawave_bot"; then
            echo -e "\${GREEN}вњ… Р‘РѕС‚ Р·Р°РїСѓС‰РµРЅ\${NC}"
        else
            echo -e "\${RED}вќЊ Р‘РѕС‚ РЅРµ Р·Р°РїСѓСЃС‚РёР»СЃСЏ! РџСЂРѕРІРµСЂСЊС‚Рµ Р»РѕРіРё: bot logs\${NC}"
        fi
    else
        echo -e "\${RED}вќЊ РћС€РёР±РєР° Р·Р°РїСѓСЃРєР°!\${NC}"
    fi
}

do_stop() {
    check_install_dir
    echo -e "\${CYAN}вЏ№пёЏ  РћСЃС‚Р°РЅРѕРІРєР° Р±РѕС‚Р°...\${NC}"
    docker compose -f "\$COMPOSE_FILE" down
    echo -e "\${GREEN}вњ… Р‘РѕС‚ РѕСЃС‚Р°РЅРѕРІР»РµРЅ\${NC}"
}

do_update() {
    check_install_dir
    echo -e "\${CYAN}рџ“¦ РћР±РЅРѕРІР»РµРЅРёРµ Р±РѕС‚Р°...\${NC}"
    cp .env ".env.backup_\$(date +%Y%m%d_%H%M%S)" 2>/dev/null

    echo -e "\${CYAN}рџ“Ґ РћР±РЅРѕРІР»РµРЅРёРµ РєРѕРґР° (РІРµС‚РєР°: \$REPO_BRANCH)...\${NC}"
    if [ -d ".git" ]; then
        git fetch --unshallow 2>/dev/null || true
        if ! git fetch origin "\$REPO_BRANCH" --prune --tags; then
            echo -e "\${YELLOW}вљ пёЏ  РќРµ СѓРґР°Р»РѕСЃСЊ РїРѕР»СѓС‡РёС‚СЊ РѕР±РЅРѕРІР»РµРЅРёСЏ РёР· GitHub\${NC}"
        fi
        if git show-ref --verify --quiet "refs/remotes/origin/\$REPO_BRANCH"; then
            git checkout -B "\$REPO_BRANCH" "origin/\$REPO_BRANCH" 2>/dev/null || git checkout "\$REPO_BRANCH" 2>/dev/null || true
            if ! git reset --hard "origin/\$REPO_BRANCH"; then
                echo -e "\${YELLOW}вљ пёЏ  РќРµ СѓРґР°Р»РѕСЃСЊ РѕР±РЅРѕРІРёС‚СЊ РєРѕРґ РґРѕ origin/\$REPO_BRANCH\${NC}"
            fi
        else
            echo -e "\${YELLOW}вљ пёЏ  Р’ origin РЅРµС‚ РІРµС‚РєРё \$REPO_BRANCH\${NC}"
        fi
    else
        echo -e "\${YELLOW}вљ пёЏ  Git-СЂРµРїРѕР·РёС‚РѕСЂРёР№ РЅРµ РЅР°Р№РґРµРЅ вЂ” РѕР±РЅРѕРІР»РµРЅРёРµ РєРѕРґР° РїСЂРѕРїСѓС‰РµРЅРѕ\${NC}"
    fi
    docker compose -f "\$COMPOSE_FILE" down
    docker compose -f "\$COMPOSE_FILE" build --no-cache
    docker compose -f "\$COMPOSE_FILE" up -d
    echo -e "\${GREEN}вњ… РћР±РЅРѕРІР»РµРЅРёРµ Р·Р°РІРµСЂС€РµРЅРѕ\${NC}"
}

show_update_info() {
    check_install_dir
    echo -e "\${CYAN}в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђ\${NC}"
    echo -e "\${WHITE}рџ“¦ РћР‘РќРћР’Р›Р•РќРР• Р‘РћРўРђ\${NC}"
    echo -e "\${CYAN}в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђ\${NC}"
    echo

    if [ ! -d ".git" ]; then
        echo -e "\${RED}вќЊ Git-СЂРµРїРѕР·РёС‚РѕСЂРёР№ РЅРµ РЅР°Р№РґРµРЅ\${NC}"
        return 1
    fi

    if ! git fetch origin "\$REPO_BRANCH" >/dev/null 2>&1; then
        echo -e "\${YELLOW}вљ пёЏ  РќРµ СѓРґР°Р»РѕСЃСЊ РїРѕР»СѓС‡РёС‚СЊ РѕР±РЅРѕРІР»РµРЅРёСЏ РёР· GitHub\${NC}"
    fi

    LOCAL_HASH=\$(git rev-parse --short HEAD 2>/dev/null || echo "?")
    LOCAL_DATE=\$(git log -1 --date=short --format=%ad 2>/dev/null || echo "?")
    REMOTE_HASH=\$(git rev-parse --short "origin/\$REPO_BRANCH" 2>/dev/null || echo "?")
    REMOTE_DATE=\$(git log -1 "origin/\$REPO_BRANCH" --date=short --format=%ad 2>/dev/null || echo "?")
    BEHIND=\$(git rev-list --count "HEAD..origin/\$REPO_BRANCH" 2>/dev/null || echo "0")

    echo -e "\${WHITE}Р›РѕРєР°Р»СЊРЅР°СЏ РІРµСЂСЃРёСЏ:\${NC} \${CYAN}\$LOCAL_HASH\${NC} | \$LOCAL_DATE"
    echo -e "\${WHITE}РЈРґР°Р»РµРЅРЅР°СЏ РІРµСЂСЃРёСЏ:\${NC} \${CYAN}\$REMOTE_HASH\${NC} | \$REMOTE_DATE"
    echo
    if [ "\$BEHIND" -gt 0 ] 2>/dev/null; then
        echo -e "\${YELLOW}Р”РѕСЃС‚СѓРїРЅРѕ РѕР±РЅРѕРІР»РµРЅРёР№: \$BEHIND\${NC}"
    else
        echo -e "\${GREEN}РћР±РЅРѕРІР»РµРЅРёР№ РЅРµС‚ вЂ” РІС‹ РЅР° Р°РєС‚СѓР°Р»СЊРЅРѕР№ РІРµСЂСЃРёРё\${NC}"
    fi
    echo
    echo -e "\${WHITE}РџРѕСЃР»РµРґРЅРёРµ РєРѕРјРјРёС‚С‹ (origin/\$REPO_BRANCH):\${NC}"
    git log -n 5 --date=short --pretty=format:"%h | %ad | %an | %s" "origin/\$REPO_BRANCH" 2>/dev/null || echo "РќРµС‚ РґР°РЅРЅС‹С…"
    echo
}

update_menu() {
    while true; do
        show_update_info || true
        echo -e "\${WHITE}Р’С‹Р±РµСЂРёС‚Рµ РґРµР№СЃС‚РІРёРµ:\${NC}"
        echo -e "  \${CYAN}1)\${NC} рџ“¦ РћР±РЅРѕРІРёС‚СЊ Р±РѕС‚Р°"
        echo -e "  \${CYAN}0)\${NC} РќР°Р·Р°Рґ"
        echo
        read -p "Р’Р°С€ РІС‹Р±РѕСЂ: " choice
        case \$choice in
            1) do_update; read -p "РќР°Р¶РјРёС‚Рµ Enter..." ;;
            0) return ;;
            *) echo -e "\${RED}РќРµРІРµСЂРЅС‹Р№ РІС‹Р±РѕСЂ\${NC}"; sleep 1 ;;
        esac
    done
}

update_installer() {
    echo
    echo -e "\${CYAN}в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђ\${NC}"
    echo -e "\${WHITE}рџ”§ РћР‘РќРћР’Р›Р•РќРР• РЎРљР РРџРўРћР’ РЈРЎРўРђРќРћР’Р©РРљРђ\${NC}"
    echo -e "\${CYAN}в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђ\${NC}"
    
    echo -e "\${CYAN}рџ“Ґ РЎРєР°С‡РёРІР°РЅРёРµ СЃРєСЂРёРїС‚РѕРІ СѓСЃС‚Р°РЅРѕРІС‰РёРєР°...\${NC}"
    
    TEMP_DIR=\$(mktemp -d)
    git clone --depth 1 --single-branch --branch spiderman https://github.com/RamaPulya/bot_auto_install.git "\$TEMP_DIR" 2>/dev/null
    
    if [ -d "\$TEMP_DIR/scripts" ]; then
        rm -rf "\$INSTALLER_DIR" 2>/dev/null
        cp -r "\$TEMP_DIR/scripts" "\$INSTALLER_DIR"
        chmod +x "\$INSTALLER_DIR"/*.sh 2>/dev/null
        chmod +x "\$INSTALLER_DIR"/lib/*.sh 2>/dev/null
        
        VERSION=\$(cat "\$INSTALLER_DIR/VERSION" 2>/dev/null || echo "?")
        echo -e "\${GREEN}вњ… РЎРєСЂРёРїС‚С‹ СѓСЃС‚Р°РЅРѕРІС‰РёРєР° РѕР±РЅРѕРІР»РµРЅС‹ (v\$VERSION)\${NC}"
    else
        echo -e "\${RED}вќЊ РћС€РёР±РєР° Р·Р°РіСЂСѓР·РєРё\${NC}"
    fi
    
    rm -rf "\$TEMP_DIR"
}

do_backup() {
    check_install_dir
    local BACKUP_DIR="\$INSTALL_DIR/data/backups"
    local TIMESTAMP=\$(date +%Y%m%d_%H%M%S)
    local BACKUP_NAME="backup_\$TIMESTAMP"
    mkdir -p "\$BACKUP_DIR/\$BACKUP_NAME"
    
    echo -e "\${CYAN}в•”в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•—\${NC}"
    echo -e "\${CYAN}в•‘           рџ’ѕ РЎРћР—Р”РђРќРР• Р Р•Р—Р•Р Р’РќРћР™ РљРћРџРР рџ’ѕ                     в•‘\${NC}"
    echo -e "\${CYAN}в•љв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ќ\${NC}"
    echo
    
    # 1. PostgreSQL
    echo -e "\${WHITE}1/4 PostgreSQL...\${NC}"
    if docker compose -f "\$COMPOSE_FILE" exec -T postgres pg_dump -U remnawave_user remnawave_bot > "\$BACKUP_DIR/\$BACKUP_NAME/database.sql" 2>/dev/null; then
        local DB_SIZE=\$(du -h "\$BACKUP_DIR/\$BACKUP_NAME/database.sql" | cut -f1)
        echo -e "    \${GREEN}вњ… database.sql (\$DB_SIZE)\${NC}"
    else
        echo -e "    \${RED}вќЊ РћС€РёР±РєР° Р±СЌРєР°РїР° PostgreSQL\${NC}"
    fi
    
    # 2. Redis
    echo -e "\${WHITE}2/4 Redis...\${NC}"
    if docker compose -f "\$COMPOSE_FILE" exec -T redis redis-cli BGSAVE >/dev/null 2>&1; then
        sleep 2
        docker compose -f "\$COMPOSE_FILE" exec -T redis cat /data/dump.rdb > "\$BACKUP_DIR/\$BACKUP_NAME/redis.rdb" 2>/dev/null
        if [ -s "\$BACKUP_DIR/\$BACKUP_NAME/redis.rdb" ]; then
            local REDIS_SIZE=\$(du -h "\$BACKUP_DIR/\$BACKUP_NAME/redis.rdb" | cut -f1)
            echo -e "    \${GREEN}вњ… redis.rdb (\$REDIS_SIZE)\${NC}"
        else
            echo -e "    \${YELLOW}вљ пёЏ  Redis РїСѓСЃС‚ РёР»Рё РЅРµРґРѕСЃС‚СѓРїРµРЅ\${NC}"
            rm -f "\$BACKUP_DIR/\$BACKUP_NAME/redis.rdb"
        fi
    else
        echo -e "    \${YELLOW}вљ пёЏ  Redis РЅРµРґРѕСЃС‚СѓРїРµРЅ\${NC}"
    fi
    
    # 3. РљРѕРЅС„РёРіСѓСЂР°С†РёСЏ
    echo -e "\${WHITE}3/4 РљРѕРЅС„РёРіСѓСЂР°С†РёСЏ...\${NC}"
    cp .env "\$BACKUP_DIR/\$BACKUP_NAME/.env" 2>/dev/null && echo -e "    \${GREEN}вњ… .env\${NC}"
    cp docker-compose*.yml "\$BACKUP_DIR/\$BACKUP_NAME/" 2>/dev/null && echo -e "    \${GREEN}вњ… docker-compose.yml\${NC}"
    
    # 4. Р”Р°РЅРЅС‹Рµ (QR-РєРѕРґС‹ Рё С‚.Рґ.)
    echo -e "\${WHITE}4/4 Р”Р°РЅРЅС‹Рµ...\${NC}"
    if [ -d "data" ] && [ "\$(ls -A data 2>/dev/null)" ]; then
        tar -czf "\$BACKUP_DIR/\$BACKUP_NAME/data.tar.gz" data 2>/dev/null
        if [ -f "\$BACKUP_DIR/\$BACKUP_NAME/data.tar.gz" ]; then
            local DATA_SIZE=\$(du -h "\$BACKUP_DIR/\$BACKUP_NAME/data.tar.gz" | cut -f1)
            echo -e "    \${GREEN}вњ… data.tar.gz (\$DATA_SIZE)\${NC}"
        fi
    else
        echo -e "    \${YELLOW}вљ пёЏ  РџР°РїРєР° data РїСѓСЃС‚Р°\${NC}"
    fi
    
    # РС‚РѕРі
    echo
    local TOTAL_SIZE=\$(du -sh "\$BACKUP_DIR/\$BACKUP_NAME" | cut -f1)
    echo -e "\${GREEN}в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђ\${NC}"
    echo -e "\${GREEN}вњ… Р‘СЌРєР°Рї СЃРѕР·РґР°РЅ: \$BACKUP_DIR/\$BACKUP_NAME\${NC}"
    echo -e "\${GREEN}   Р Р°Р·РјРµСЂ: \$TOTAL_SIZE\${NC}"
    echo -e "\${GREEN}в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђ\${NC}"
    
    # РЈРґР°Р»СЏРµРј СЃС‚Р°СЂС‹Рµ Р±СЌРєР°РїС‹ (РѕСЃС‚Р°РІР»СЏРµРј 5 РїРѕСЃР»РµРґРЅРёС…)
    ls -dt "\$BACKUP_DIR"/backup_* 2>/dev/null | tail -n +6 | xargs -r rm -rf
}

do_health() {
    check_install_dir
    echo -e "\${CYAN}в•”в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•—\${NC}"
    echo -e "\${CYAN}в•‘           рџЏҐ Р”РРђР“РќРћРЎРўРРљРђ РЎРРЎРўР•РњР« рџЏҐ                          в•‘\${NC}"
    echo -e "\${CYAN}в•љв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ќ\${NC}"
    echo
    
    echo -e "\${WHITE}рџђі РљРѕРЅС‚РµР№РЅРµСЂС‹:\${NC}"
    docker compose -f "\$COMPOSE_FILE" ps
    echo
    
    echo -e "\${WHITE}рџ“Љ РЎРµСЂРІРёСЃС‹:\${NC}"
    docker ps --format '{{.Names}}' | grep -q "remnawave_bot" && echo -e "  \${GREEN}вњ… Bot: СЂР°Р±РѕС‚Р°РµС‚\${NC}" || echo -e "  \${RED}вќЊ Bot: РЅРµ Р·Р°РїСѓС‰РµРЅ\${NC}"
    docker compose -f "\$COMPOSE_FILE" exec -T postgres pg_isready -U remnawave_user >/dev/null 2>&1 && echo -e "  \${GREEN}вњ… PostgreSQL: СЂР°Р±РѕС‚Р°РµС‚\${NC}" || echo -e "  \${RED}вќЊ PostgreSQL: РЅРµ РѕС‚РІРµС‡Р°РµС‚\${NC}"
    docker compose -f "\$COMPOSE_FILE" exec -T redis redis-cli ping >/dev/null 2>&1 && echo -e "  \${GREEN}вњ… Redis: СЂР°Р±РѕС‚Р°РµС‚\${NC}" || echo -e "  \${RED}вќЊ Redis: РЅРµ РѕС‚РІРµС‡Р°РµС‚\${NC}"
    
    echo
    echo -e "\${WHITE}рџ“‹ РџРѕСЃР»РµРґРЅРёРµ Р»РѕРіРё:\${NC}"
    docker compose -f "\$COMPOSE_FILE" logs --tail=10 bot 2>/dev/null
}

do_config() {
    check_install_dir
    \${EDITOR:-nano} "\$INSTALL_DIR/.env"
    echo -e "\${YELLOW}РџРµСЂРµР·Р°РїСѓСЃС‚РёС‚Рµ Р±РѕС‚Р° РґР»СЏ РїСЂРёРјРµРЅРµРЅРёСЏ: bot restart\${NC}"
}

do_install() {
    local INSTALLER_DIR="\$INSTALL_DIR/.installer"
    
    echo -e "\${PURPLE}в•”в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•—\${NC}"
    echo -e "\${PURPLE}в•‘           рџ”§ РЈРЎРўРђРќРћР’Р©РРљ Р‘РћРўРђ рџ”§                              в•‘\${NC}"
    echo -e "\${PURPLE}в•љв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ќ\${NC}"
    echo
    
    if [ -d "\$INSTALLER_DIR" ] && [ -f "\$INSTALLER_DIR/install.sh" ]; then
        local VERSION=\$(cat "\$INSTALLER_DIR/VERSION" 2>/dev/null || echo "?")
        echo -e "\${GREEN}вњ… РќР°Р№РґРµРЅС‹ Р»РѕРєР°Р»СЊРЅС‹Рµ СЃРєСЂРёРїС‚С‹ СѓСЃС‚Р°РЅРѕРІС‰РёРєР° (v\$VERSION)\${NC}"
        echo
        echo -e "\${WHITE}Р’Р°СЂРёР°РЅС‚С‹:\${NC}"
        echo -e "  \${CYAN}1)\${NC} Р—Р°РїСѓСЃС‚РёС‚СЊ СѓСЃС‚Р°РЅРѕРІС‰РёРє"
        echo -e "  \${CYAN}2)\${NC} РћР±РЅРѕРІРёС‚СЊ СЃРєСЂРёРїС‚С‹ СѓСЃС‚Р°РЅРѕРІС‰РёРєР°"
        echo -e "  \${CYAN}3)\${NC} РЎРєР°С‡Р°С‚СЊ Рё Р·Р°РїСѓСЃС‚РёС‚СЊ СЃ GitHub"
        echo -e "  \${CYAN}0)\${NC} РћС‚РјРµРЅР°"
        echo
        read -p "Р’Р°С€ РІС‹Р±РѕСЂ [1]: " choice
        choice=\${choice:-1}
        
        case \$choice in
            1)
                echo -e "\${CYAN}рџљЂ Р—Р°РїСѓСЃРє СѓСЃС‚Р°РЅРѕРІС‰РёРєР°...\${NC}"
                sudo bash "\$INSTALLER_DIR/install.sh"
                ;;
            2)
                echo -e "\${CYAN}рџ“Ґ РћР±РЅРѕРІР»РµРЅРёРµ СЃРєСЂРёРїС‚РѕРІ...\${NC}"
                local TEMP_DIR=\$(mktemp -d)
                git clone --depth 1 --single-branch --branch spiderman https://github.com/RamaPulya/bot_auto_install.git "\$TEMP_DIR" 2>/dev/null
                if [ -d "\$TEMP_DIR/scripts" ]; then
                    rm -rf "\$INSTALLER_DIR"
                    cp -r "\$TEMP_DIR/scripts" "\$INSTALLER_DIR"
                    chmod +x "\$INSTALLER_DIR"/*.sh 2>/dev/null
                    chmod +x "\$INSTALLER_DIR"/lib/*.sh 2>/dev/null
                    local NEW_VER=\$(cat "\$INSTALLER_DIR/VERSION" 2>/dev/null || echo "?")
                    echo -e "\${GREEN}вњ… РћР±РЅРѕРІР»РµРЅРѕ РґРѕ v\$NEW_VER\${NC}"
                fi
                rm -rf "\$TEMP_DIR"
                ;;
            3)
                echo -e "\${CYAN}рџ“Ґ РЎРєР°С‡РёРІР°РЅРёРµ СЃ GitHub...\${NC}"
                curl -fsSL https://raw.githubusercontent.com/RamaPulya/bot_auto_install/spiderman/scripts/quick-install.sh | sudo bash
                ;;
            0)
                return
                ;;
        esac
    else
        echo -e "\${YELLOW}вљ пёЏ  Р›РѕРєР°Р»СЊРЅС‹Рµ СЃРєСЂРёРїС‚С‹ РЅРµ РЅР°Р№РґРµРЅС‹\${NC}"
        echo
        echo -e "\${WHITE}Р’Р°СЂРёР°РЅС‚С‹:\${NC}"
        echo -e "  \${CYAN}1)\${NC} РЎРєР°С‡Р°С‚СЊ Рё Р·Р°РїСѓСЃС‚РёС‚СЊ СЃ GitHub"
        echo -e "  \${CYAN}2)\${NC} РЎРєР°С‡Р°С‚СЊ СЃРєСЂРёРїС‚С‹ Р»РѕРєР°Р»СЊРЅРѕ"
        echo -e "  \${CYAN}0)\${NC} РћС‚РјРµРЅР°"
        echo
        read -p "Р’Р°С€ РІС‹Р±РѕСЂ [1]: " choice
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
                    echo -e "\${GREEN}вњ… РЎРєСЂРёРїС‚С‹ СЃРѕС…СЂР°РЅРµРЅС‹ РІ \$INSTALLER_DIR\${NC}"
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
    echo
    echo -e "\${RED}в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђ\${NC}"
    echo -e "\${WHITE}рџ—‘пёЏ  РЈР”РђР›Р•РќРР• Р‘РћРўРђ\${NC}"
    echo -e "\${RED}в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђ\${NC}"
    echo
    echo -e "\${YELLOW}вљ пёЏ  Р’РќРРњРђРќРР•! Р­С‚Рѕ РґРµР№СЃС‚РІРёРµ СѓРґР°Р»РёС‚:\${NC}"
    echo -e "   - Docker РєРѕРЅС‚РµР№РЅРµСЂС‹ Р±РѕС‚Р°"
    echo -e "   - Р”Р°РЅРЅС‹Рµ PostgreSQL Рё Redis (РѕРїС†РёРѕРЅР°Р»СЊРЅРѕ)"
    echo
    
    read -p "Р’РІРµРґРёС‚Рµ 'yes' РґР»СЏ РїРѕРґС‚РІРµСЂР¶РґРµРЅРёСЏ: " CONFIRM
    if [ "\$CONFIRM" != "yes" ]; then
        echo -e "\${GREEN}РЈРґР°Р»РµРЅРёРµ РѕС‚РјРµРЅРµРЅРѕ\${NC}"
        return
    fi
    
    echo -e "\${CYAN}рџ›‘ РћСЃС‚Р°РЅРѕРІРєР° РєРѕРЅС‚РµР№РЅРµСЂРѕРІ...\${NC}"
    docker compose -f "\$COMPOSE_FILE" down
    
    read -p "РЈРґР°Р»РёС‚СЊ РґР°РЅРЅС‹Рµ (volumes)? (y/n): " -n 1 -r
    echo
    if [[ \$REPLY =~ ^[Yy]\$ ]]; then
        echo -e "\${CYAN}рџ’ѕ РЈРґР°Р»РµРЅРёРµ volumes...\${NC}"
        docker compose -f "\$COMPOSE_FILE" down -v
        docker volume ls -q | grep -E "bedolaga|remnawave.*bot" | xargs -r docker volume rm 2>/dev/null
        echo -e "\${GREEN}вњ… Volumes СѓРґР°Р»РµРЅС‹\${NC}"
    fi
    
    if [ -f "/usr/local/bin/bot" ]; then
        rm -f /usr/local/bin/bot
        echo -e "\${GREEN}вњ… РљРѕРјР°РЅРґР° 'bot' СѓРґР°Р»РµРЅР°\${NC}"
    fi
    
    echo
    echo -e "\${GREEN}вњ… РЈРґР°Р»РµРЅРёРµ Р·Р°РІРµСЂС€РµРЅРѕ\${NC}"
    echo -e "\${YELLOW}Р”РёСЂРµРєС‚РѕСЂРёСЏ \$INSTALL_DIR РѕСЃС‚Р°РІР»РµРЅР°. РЈРґР°Р»РёС‚Рµ РІСЂСѓС‡РЅСѓСЋ:\${NC}"
    echo -e "\${CYAN}rm -rf \$INSTALL_DIR\${NC}"
}

show_menu() {
    clear
    echo -e "\${PURPLE}в•”в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•—\${NC}"
    echo -e "\${PURPLE}в•‘        рџ¤– REMNAWAVE BEDOLAGA BOT вЂ” РЈРџР РђР’Р›Р•РќРР• рџ¤–             в•‘\${NC}"
    echo -e "\${PURPLE}в•љв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ќ\${NC}"
    echo
    echo -e "\${WHITE}Р”РёСЂРµРєС‚РѕСЂРёСЏ:\${NC} \${CYAN}\$INSTALL_DIR\${NC}"
    echo
    
    if docker ps --format '{{.Names}}' | grep -q "remnawave_bot"; then
        echo -e "\${WHITE}РЎС‚Р°С‚СѓСЃ:\${NC} \${GREEN}в—Џ Р‘РѕС‚ СЂР°Р±РѕС‚Р°РµС‚\${NC}"
    else
        echo -e "\${WHITE}РЎС‚Р°С‚СѓСЃ:\${NC} \${RED}в—‹ Р‘РѕС‚ РѕСЃС‚Р°РЅРѕРІР»РµРЅ\${NC}"
    fi
    echo
    
    echo -e "\${WHITE}в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђ\${NC}"
    echo
    echo -e "  \${CYAN}1)\${NC} рџ“‹ Р›РѕРіРё              \${CYAN}6)\${NC} рџ’ѕ РЎРѕР·РґР°С‚СЊ Р±СЌРєР°Рї"
    echo -e "  \${CYAN}2)\${NC} рџ“Љ РЎС‚Р°С‚СѓСЃ            \${CYAN}7)\${NC} рџЏҐ Р”РёР°РіРЅРѕСЃС‚РёРєР°"
    echo -e "  \${CYAN}3)\${NC} рџ”„ РџРµСЂРµР·Р°РїСѓСЃРє        \${CYAN}8)\${NC} вљ™пёЏ  Р РµРґР°РєС‚РёСЂРѕРІР°С‚СЊ .env"
    echo -e "  \${CYAN}4)\${NC} в–¶пёЏ  Р—Р°РїСѓСЃРє            \${CYAN}9)\${NC} рџ“¦ РћР±РЅРѕРІРёС‚СЊ Р±РѕС‚Р°"
    echo -e "  \${CYAN}5)\${NC} вЏ№пёЏ  РћСЃС‚Р°РЅРѕРІРєР°         \${CYAN}10)\${NC} рџ› пёЏ РћР±РЅРѕРІРёС‚СЊ СЃРєСЂРёРїС‚"
    echo -e "  \${CYAN}i)\${NC} рџ”§ РЈСЃС‚Р°РЅРѕРІС‰РёРє        \${CYAN}L)\${NC} рџ—‘пёЏ  РЈРґР°Р»РµРЅРёРµ"
    echo
    echo -e "  \${CYAN}q)\${NC} Р’С‹С…РѕРґ"
    echo
}

interactive_menu() {
    while true; do
        show_menu
        read -p "Р’Р°С€ РІС‹Р±РѕСЂ: " choice
        
        case \$choice in
            1) do_logs ;;
            2) do_status; read -p "РќР°Р¶РјРёС‚Рµ Enter..." ;;
            3) do_restart; read -p "РќР°Р¶РјРёС‚Рµ Enter..." ;;
            4) do_start; read -p "РќР°Р¶РјРёС‚Рµ Enter..." ;;
            5) do_stop; read -p "РќР°Р¶РјРёС‚Рµ Enter..." ;;
            6) do_backup; read -p "РќР°Р¶РјРёС‚Рµ Enter..." ;;
            7) do_health; read -p "РќР°Р¶РјРёС‚Рµ Enter..." ;;
            8) do_config ;;
            9) update_menu ;;
            10) update_installer; read -p "РќР°Р¶РјРёС‚Рµ Enter..." ;;
            i|I) do_install; read -p "РќР°Р¶РјРёС‚Рµ Enter..." ;;
            l|L) do_uninstall; break ;;
            q|Q|exit) echo -e "\${GREEN}Р”Рѕ СЃРІРёРґР°РЅРёСЏ!\${NC}"; exit 0 ;;
            *) echo -e "\${RED}РќРµРІРµСЂРЅС‹Р№ РІС‹Р±РѕСЂ\${NC}"; sleep 1 ;;
        esac
    done
}

show_help() {
    echo -e "\${PURPLE}в•”в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•—\${NC}"
    echo -e "\${PURPLE}в•‘        рџ¤– REMNAWAVE BEDOLAGA BOT вЂ” РЎРџР РђР’РљРђ рџ¤–                в•‘\${NC}"
    echo -e "\${PURPLE}в•љв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ќ\${NC}"
    echo
    echo -e "\${WHITE}РСЃРїРѕР»СЊР·РѕРІР°РЅРёРµ:\${NC}"
    echo -e "  \${CYAN}bot\${NC}              вЂ” РРЅС‚РµСЂР°РєС‚РёРІРЅРѕРµ РјРµРЅСЋ"
    echo -e "  \${CYAN}bot <РєРѕРјР°РЅРґР°>\${NC}   вЂ” Р’С‹РїРѕР»РЅРёС‚СЊ РєРѕРјР°РЅРґСѓ"
    echo
    echo -e "\${WHITE}РљРѕРјР°РЅРґС‹:\${NC}"
    echo -e "  \${GREEN}logs\${NC}       вЂ” РџСЂРѕСЃРјРѕС‚СЂ Р»РѕРіРѕРІ"
    echo -e "  \${GREEN}status\${NC}     вЂ” РЎС‚Р°С‚СѓСЃ РєРѕРЅС‚РµР№РЅРµСЂРѕРІ"
    echo -e "  \${GREEN}restart\${NC}    вЂ” РџРµСЂРµР·Р°РїСѓСЃРє"
    echo -e "  \${GREEN}start\${NC}      вЂ” Р—Р°РїСѓСЃРє"
    echo -e "  \${GREEN}stop\${NC}       вЂ” РћСЃС‚Р°РЅРѕРІРєР°"
    echo -e "  \${GREEN}update\${NC}     вЂ” РћР±РЅРѕРІР»РµРЅРёРµ Р±РѕС‚Р°"
    echo -e "  \${GREEN}backup\${NC}     вЂ” Р РµР·РµСЂРІРЅР°СЏ РєРѕРїРёСЏ"
    echo -e "  \${GREEN}health\${NC}     вЂ” Р”РёР°РіРЅРѕСЃС‚РёРєР°"
    echo -e "  \${GREEN}config\${NC}     вЂ” Р РµРґР°РєС‚РёСЂРѕРІР°С‚СЊ .env"
    echo -e "  \${GREEN}install\${NC}    вЂ” Р—Р°РїСѓСЃС‚РёС‚СЊ СѓСЃС‚Р°РЅРѕРІС‰РёРє"
    echo -e "  \${GREEN}installer\${NC}  вЂ” РћР±РЅРѕРІРёС‚СЊ СЃРєСЂРёРїС‚С‹ СѓСЃС‚Р°РЅРѕРІС‰РёРєР°"
    echo -e "  \${GREEN}uninstall\${NC}  вЂ” РЈРґР°Р»РµРЅРёРµ Р±РѕС‚Р°"
}

case "\$1" in
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
    uninstall|remove) do_uninstall ;;
    help|--help|-h) show_help ;;
    "")         interactive_menu ;;
    *)
        echo -e "\${RED}вќЊ РќРµРёР·РІРµСЃС‚РЅР°СЏ РєРѕРјР°РЅРґР°: \$1\${NC}"
        echo "РСЃРїРѕР»СЊР·СѓР№С‚Рµ: bot help"
        exit 1
        ;;
esac
BOTEOF

    chmod +x /usr/local/bin/bot
    
    echo -e "${GREEN}вњ… РљРѕРјР°РЅРґР° 'bot' СѓСЃС‚Р°РЅРѕРІР»РµРЅР°!${NC}"
    echo
    echo -e "${WHITE}РўРµРїРµСЂСЊ РґРѕСЃС‚СѓРїРЅРѕ:${NC}"
    echo -e "  ${CYAN}bot${NC}        вЂ” РёРЅС‚РµСЂР°РєС‚РёРІРЅРѕРµ РјРµРЅСЋ"
    echo -e "  ${CYAN}bot help${NC}   вЂ” СЃРїСЂР°РІРєР°"
}

# Р¤СѓРЅРєС†РёСЏ РѕР±РЅРѕРІР»РµРЅРёСЏ СЃРєСЂРёРїС‚РѕРІ СѓСЃС‚Р°РЅРѕРІС‰РёРєР°
update_installer() {
    echo
    echo -e "${CYAN}в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђ${NC}"
    echo -e "${WHITE}рџ”§ РћР‘РќРћР’Р›Р•РќРР• РЎРљР РРџРўРћР’ РЈРЎРўРђРќРћР’Р©РРљРђ${NC}"
    echo -e "${CYAN}в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђ${NC}"
    
    INSTALLER_DIR="$INSTALL_DIR/.installer"
    
    echo -e "${CYAN}рџ“Ґ РЎРєР°С‡РёРІР°РЅРёРµ СЃРєСЂРёРїС‚РѕРІ СѓСЃС‚Р°РЅРѕРІС‰РёРєР°...${NC}"
    
    TEMP_DIR=$(mktemp -d)
    git clone --depth 1 --single-branch --branch spiderman https://github.com/RamaPulya/bot_auto_install.git "$TEMP_DIR" 2>/dev/null
    
    if [ -d "$TEMP_DIR/scripts" ]; then
        rm -rf "$INSTALLER_DIR" 2>/dev/null
        cp -r "$TEMP_DIR/scripts" "$INSTALLER_DIR"
        chmod +x "$INSTALLER_DIR"/*.sh 2>/dev/null
        chmod +x "$INSTALLER_DIR"/lib/*.sh 2>/dev/null
        
        VERSION=$(cat "$INSTALLER_DIR/VERSION" 2>/dev/null || echo "?")
        echo -e "${GREEN}вњ… РЎРєСЂРёРїС‚С‹ СѓСЃС‚Р°РЅРѕРІС‰РёРєР° РѕР±РЅРѕРІР»РµРЅС‹ (v$VERSION)${NC}"
    else
        echo -e "${RED}вќЊ РћС€РёР±РєР° Р·Р°РіСЂСѓР·РєРё${NC}"
    fi
    
    rm -rf "$TEMP_DIR"
}

# в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђ
# РћРЎРќРћР’РќРћР™ РљРћР”
# в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђ

INSTALL_DIR=$(find_install_dir)

if [ -z "$INSTALL_DIR" ]; then
    echo -e "${RED}вќЊ Р”РёСЂРµРєС‚РѕСЂРёСЏ Р±РѕС‚Р° РЅРµ РЅР°Р№РґРµРЅР°!${NC}"
    echo -e "${YELLOW}РџСЂРѕРІРµСЂСЊС‚Рµ /opt/remnawave-bedolaga-telegram-bot${NC}"
    exit 1
fi

# РћРїСЂРµРґРµР»СЏРµРј compose С„Р°Р№Р»
COMPOSE_FILE="docker-compose.yml"
if [ -f "$INSTALL_DIR/docker-compose.local.yml" ]; then
    COMPOSE_FILE="docker-compose.local.yml"
elif [ -f "$INSTALL_DIR/.install_config" ]; then
    source "$INSTALL_DIR/.install_config" 2>/dev/null
fi

# РџСЂРѕРІРµСЂСЏРµРј РЅР°Р»РёС‡РёРµ external network РІ compose С„Р°Р№Р»Рµ
if grep -q "external: true" "$INSTALL_DIR/$COMPOSE_FILE" 2>/dev/null; then
    NETWORK_NAME=$(grep -A1 "external: true" "$INSTALL_DIR/$COMPOSE_FILE" | grep "name:" | awk '{print $2}' || echo "remnawave-network")
    if ! docker network ls --format '{{.Name}}' | grep -q "^${NETWORK_NAME}$"; then
        echo -e "${YELLOW}вљ пёЏ  РћР±РЅР°СЂСѓР¶РµРЅР° external network: $NETWORK_NAME${NC}"
        echo -e "${YELLOW}   РЎРµС‚СЊ РЅРµ РЅР°Р№РґРµРЅР°. РЎРѕР·РґР°С‘Рј...${NC}"
        docker network create "$NETWORK_NAME" 2>/dev/null || true
    fi
fi

echo -e "${PURPLE}"
echo "в•”в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•—"
echo "в•‘     рџ”„ REMNAWAVE BEDOLAGA BOT - РћР‘РќРћР’Р›Р•РќРР• рџ”„               в•‘"
echo "в•љв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ќ"
echo -e "${NC}"

echo -e "${WHITE}рџ“Ѓ Р”РёСЂРµРєС‚РѕСЂРёСЏ:${NC} ${CYAN}$INSTALL_DIR${NC}"
echo

# РџСЂРѕРІРµСЂРєР° РЅР°Р»РёС‡РёСЏ РєРѕРјР°РЅРґС‹ bot
if [ -f "/usr/local/bin/bot" ]; then
    echo -e "${GREEN}вњ… РљРѕРјР°РЅРґР° 'bot' СѓСЃС‚Р°РЅРѕРІР»РµРЅР°${NC}"
else
    echo -e "${YELLOW}вљ пёЏ  РљРѕРјР°РЅРґР° 'bot' РЅРµ РЅР°Р№РґРµРЅР°${NC}"
fi

# Р“Р»Р°РІРЅРѕРµ РјРµРЅСЋ
echo
echo -e "${WHITE}Р§С‚Рѕ РІС‹ С…РѕС‚РёС‚Рµ СЃРґРµР»Р°С‚СЊ?${NC}"
echo
echo -e "  ${CYAN}1)${NC} рџ“¦ РћР±РЅРѕРІРёС‚СЊ Р±РѕС‚Р° (git pull + rebuild)"
echo -e "  ${CYAN}2)${NC} рџЋ® РЈСЃС‚Р°РЅРѕРІРёС‚СЊ РєРѕРјР°РЅРґСѓ 'bot'"
echo -e "  ${CYAN}3)${NC} рџ”§ РћР±РЅРѕРІРёС‚СЊ СЃРєСЂРёРїС‚С‹ СѓСЃС‚Р°РЅРѕРІС‰РёРєР°"
echo -e "  ${CYAN}4)${NC} рџ“‹ Р’СЃС‘ РІРјРµСЃС‚Рµ (СЂРµРєРѕРјРµРЅРґСѓРµС‚СЃСЏ)"
echo -e "  ${CYAN}0)${NC} РћС‚РјРµРЅР°"
echo
read -p "Р’Р°С€ РІС‹Р±РѕСЂ [4]: " CHOICE < /dev/tty
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
        echo -e "${YELLOW}РћС‚РјРµРЅРµРЅРѕ${NC}"
        exit 0
        ;;
    *)
        echo -e "${RED}РќРµРІРµСЂРЅС‹Р№ РІС‹Р±РѕСЂ${NC}"
        exit 1
        ;;
esac

# Р¤РёРЅР°Р»СЊРЅРѕРµ СЃРѕРѕР±С‰РµРЅРёРµ
echo
echo -e "${GREEN}в•”в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•—${NC}"
echo -e "${GREEN}в•‘     вњ… РћР‘РќРћР’Р›Р•РќРР• Р—РђР’Р•Р РЁР•РќРћ!                                 в•‘${NC}"
echo -e "${GREEN}в•љв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ќ${NC}"
echo
echo -e "${WHITE}РСЃРїРѕР»СЊР·СѓР№С‚Рµ РєРѕРјР°РЅРґСѓ ${CYAN}bot${NC} РґР»СЏ СѓРїСЂР°РІР»РµРЅРёСЏ Р±РѕС‚РѕРј${NC}"
echo




