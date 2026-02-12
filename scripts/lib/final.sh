#!/bin/bash

# ===============================================
# рџЏЃ Р¤РРќРђР›Р¬РќР«Р• Р¤РЈРќРљР¦РР
# ===============================================

# РљРѕРїРёСЂРѕРІР°РЅРёРµ СЃРєСЂРёРїС‚РѕРІ СѓСЃС‚Р°РЅРѕРІС‰РёРєР° РІ РґРёСЂРµРєС‚РѕСЂРёСЋ Р±РѕС‚Р°
copy_installer_scripts() {
    print_info "РЎРѕС…СЂР°РЅРµРЅРёРµ СЃРєСЂРёРїС‚РѕРІ СѓСЃС‚Р°РЅРѕРІС‰РёРєР°..."
    
    local INSTALLER_DIR="$INSTALL_DIR/.installer"
    mkdir -p "$INSTALLER_DIR"
    
    # РћРїСЂРµРґРµР»СЏРµРј РѕС‚РєСѓРґР° РєРѕРїРёСЂРѕРІР°С‚СЊ (РѕС‚РєСѓРґР° Р·Р°РїСѓС‰РµРЅ install.sh)
    local SCRIPT_SOURCE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    
    if [ -d "$SCRIPT_SOURCE" ] && [ -f "$SCRIPT_SOURCE/install.sh" ]; then
        cp -r "$SCRIPT_SOURCE"/* "$INSTALLER_DIR/" 2>/dev/null
        chmod +x "$INSTALLER_DIR"/*.sh 2>/dev/null
        chmod +x "$INSTALLER_DIR"/lib/*.sh 2>/dev/null
        print_success "РЎРєСЂРёРїС‚С‹ СѓСЃС‚Р°РЅРѕРІС‰РёРєР° СЃРѕС…СЂР°РЅРµРЅС‹ РІ $INSTALLER_DIR"
    else
        print_warning "РќРµ СѓРґР°Р»РѕСЃСЊ СЃРєРѕРїРёСЂРѕРІР°С‚СЊ СЃРєСЂРёРїС‚С‹ СѓСЃС‚Р°РЅРѕРІС‰РёРєР°"
    fi
}

# РЎРѕР·РґР°РЅРёРµ РіР»РѕР±Р°Р»СЊРЅРѕР№ РєРѕРјР°РЅРґС‹ 'bot' СЃ РёРЅС‚РµСЂР°РєС‚РёРІРЅС‹Рј РјРµРЅСЋ
create_management_scripts() {
    print_step "РЎРѕР·РґР°РЅРёРµ РєРѕРјР°РЅРґС‹ СѓРїСЂР°РІР»РµРЅРёСЏ Р±РѕС‚РѕРј"
    
    cd "$INSTALL_DIR"
    
    # РљРѕРїРёСЂСѓРµРј СЃРєСЂРёРїС‚С‹ СѓСЃС‚Р°РЅРѕРІС‰РёРєР°
    copy_installer_scripts
    
    # РћРїСЂРµРґРµР»СЏРµРј compose С„Р°Р№Р» РґР»СЏ Р·Р°РїРёСЃРё РІ СЃРєСЂРёРїС‚
    local compose_file="docker-compose.yml"
    if [ -f "docker-compose.local.yml" ]; then
        compose_file="docker-compose.local.yml"
    fi
    
    # РЎРѕР·РґР°С‘Рј РµРґРёРЅС‹Р№ СЃРєСЂРёРїС‚ СѓРїСЂР°РІР»РµРЅРёСЏ РІ /usr/local/bin/bot
    cat > /usr/local/bin/bot << 'BOTSCRIPT'
#!/bin/bash
# в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђ
# рџ¤– REMNAWAVE BEDOLAGA BOT - РљРћРњРђРќР”Рђ РЈРџР РђР’Р›Р•РќРРЇ
# в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђ

INSTALL_DIR="__INSTALL_DIR__"
COMPOSE_FILE="__COMPOSE_FILE__"
INSTALLER_DIR="__INSTALL_DIR__/.installer"

# Р¦РІРµС‚Р°
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m'
REPO_BRANCH="spiderman"

# РџСЂРѕРІРµСЂРєР° РґРёСЂРµРєС‚РѕСЂРёРё
check_install_dir() {
    if [ ! -d "$INSTALL_DIR" ]; then
        echo -e "${RED}вќЊ Р”РёСЂРµРєС‚РѕСЂРёСЏ Р±РѕС‚Р° РЅРµ РЅР°Р№РґРµРЅР°: $INSTALL_DIR${NC}"
        echo -e "${YELLOW}Р’РѕР·РјРѕР¶РЅРѕ Р±РѕС‚ Р±С‹Р» СѓРґР°Р»С‘РЅ РёР»Рё РїРµСЂРµРјРµС‰С‘РЅ${NC}"
        exit 1
    fi
    cd "$INSTALL_DIR"
}

# в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђ
# Р¤РЈРќРљР¦РР РЈРџР РђР’Р›Р•РќРРЇ
# в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђ

do_logs() {
    check_install_dir
    echo -e "${CYAN}рџ“‹ Р›РѕРіРё Р±РѕС‚Р° (Ctrl+C РґР»СЏ РІС‹С…РѕРґР°)...${NC}"
    docker compose -f "$COMPOSE_FILE" logs -f --tail=150 bot
}

do_status() {
    check_install_dir
    echo -e "${CYAN}в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђ${NC}"
    echo -e "${WHITE}рџ“Љ РЎРўРђРўРЈРЎ РљРћРќРўР•Р™РќР•Р РћР’${NC}"
    echo -e "${CYAN}в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђ${NC}"
    echo
    docker compose -f "$COMPOSE_FILE" ps
    echo
    echo -e "${WHITE}рџ“€ РСЃРїРѕР»СЊР·РѕРІР°РЅРёРµ СЂРµСЃСѓСЂСЃРѕРІ:${NC}"
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" 2>/dev/null | grep -E "remnawave|postgres|redis" || echo "РљРѕРЅС‚РµР№РЅРµСЂС‹ РЅРµ Р·Р°РїСѓС‰РµРЅС‹"
}

do_restart() {
    check_install_dir
    echo -e "${CYAN}рџ”„ РџРµСЂРµР·Р°РїСѓСЃРє Р±РѕС‚Р° (РїСЂРёРјРµРЅСЏРµРј .env)...${NC}"
    docker compose -f "$COMPOSE_FILE" up -d --force-recreate
    echo -e "${GREEN}вњ… Р‘РѕС‚ РїРµСЂРµР·Р°РїСѓС‰РµРЅ${NC}"
}

do_start() {
    check_install_dir
    echo -e "${CYAN}в–¶пёЏ  Р—Р°РїСѓСЃРє Р±РѕС‚Р°...${NC}"
    docker compose -f "$COMPOSE_FILE" up -d
    echo -e "${GREEN}вњ… Р‘РѕС‚ Р·Р°РїСѓС‰РµРЅ${NC}"
}

do_stop() {
    check_install_dir
    echo -e "${CYAN}вЏ№пёЏ  РћСЃС‚Р°РЅРѕРІРєР° Р±РѕС‚Р°...${NC}"
    docker compose -f "$COMPOSE_FILE" down
    echo -e "${GREEN}вњ… Р‘РѕС‚ РѕСЃС‚Р°РЅРѕРІР»РµРЅ${NC}"
}

do_update() {
    check_install_dir
    echo -e "${CYAN}рџ“¦ РћР±РЅРѕРІР»РµРЅРёРµ Р±РѕС‚Р°...${NC}"
    
    # РЎРѕР·РґР°С‘Рј Р±СЌРєР°Рї .env РїРµСЂРµРґ РѕР±РЅРѕРІР»РµРЅРёРµРј
    cp .env ".env.backup_$(date +%Y%m%d_%H%M%S)" 2>/dev/null
    
    echo -e "${CYAN}1/4 РџРѕР»СѓС‡РµРЅРёРµ РѕР±РЅРѕРІР»РµРЅРёР№ (РІРµС‚РєР°: $REPO_BRANCH)...${NC}"
    if [ -d ".git" ]; then
        git fetch --unshallow 2>/dev/null || true
        if ! git fetch origin "$REPO_BRANCH" --prune --tags; then
            echo -e "${YELLOW}вљ пёЏ  РќРµ СѓРґР°Р»РѕСЃСЊ РїРѕР»СѓС‡РёС‚СЊ РѕР±РЅРѕРІР»РµРЅРёСЏ РёР· GitHub${NC}"
        fi
        if git show-ref --verify --quiet "refs/remotes/origin/$REPO_BRANCH"; then
            git checkout -B "$REPO_BRANCH" "origin/$REPO_BRANCH" 2>/dev/null || git checkout "$REPO_BRANCH" 2>/dev/null || true
            if ! git reset --hard "origin/$REPO_BRANCH"; then
                echo -e "${YELLOW}вљ пёЏ  РќРµ СѓРґР°Р»РѕСЃСЊ РѕР±РЅРѕРІРёС‚СЊ РєРѕРґ РґРѕ origin/$REPO_BRANCH${NC}"
            fi
        else
            echo -e "${YELLOW}вљ пёЏ  Р’ origin РЅРµС‚ РІРµС‚РєРё $REPO_BRANCH${NC}"
        fi
    else
        echo -e "${YELLOW}вљ пёЏ  Git-СЂРµРїРѕР·РёС‚РѕСЂРёР№ РЅРµ РЅР°Р№РґРµРЅ вЂ” РѕР±РЅРѕРІР»РµРЅРёРµ РєРѕРґР° РїСЂРѕРїСѓС‰РµРЅРѕ${NC}"
    fi
    
    echo -e "${CYAN}2/4 РћСЃС‚Р°РЅРѕРІРєР° РєРѕРЅС‚РµР№РЅРµСЂРѕРІ...${NC}"
    docker compose -f "$COMPOSE_FILE" down
    
    echo -e "${CYAN}3/4 РџРµСЂРµСЃР±РѕСЂРєР° РѕР±СЂР°Р·РѕРІ...${NC}"
    docker compose -f "$COMPOSE_FILE" build --no-cache
    
    echo -e "${CYAN}4/4 Р—Р°РїСѓСЃРє РѕР±РЅРѕРІР»С‘РЅРЅРѕРіРѕ Р±РѕС‚Р°...${NC}"
    docker compose -f "$COMPOSE_FILE" up -d
    
    echo -e "${GREEN}вњ… РћР±РЅРѕРІР»РµРЅРёРµ Р·Р°РІРµСЂС€РµРЅРѕ${NC}"
}

show_update_info() {
    check_install_dir
    echo -e "${CYAN}в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђ${NC}"
    echo -e "${WHITE}рџ“¦ РћР‘РќРћР’Р›Р•РќРР• Р‘РћРўРђ${NC}"
    echo -e "${CYAN}в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђ${NC}"
    echo

    if [ ! -d ".git" ]; then
        echo -e "${RED}вќЊ Git-СЂРµРїРѕР·РёС‚РѕСЂРёР№ РЅРµ РЅР°Р№РґРµРЅ${NC}"
        return 1
    fi

    if ! git fetch origin "$REPO_BRANCH" >/dev/null 2>&1; then
        echo -e "${YELLOW}вљ пёЏ  РќРµ СѓРґР°Р»РѕСЃСЊ РїРѕР»СѓС‡РёС‚СЊ РѕР±РЅРѕРІР»РµРЅРёСЏ РёР· GitHub${NC}"
    fi

    LOCAL_HASH=$(git rev-parse --short HEAD 2>/dev/null || echo "?")
    LOCAL_DATE=$(git log -1 --date=short --format=%ad 2>/dev/null || echo "?")
    REMOTE_HASH=$(git rev-parse --short "origin/$REPO_BRANCH" 2>/dev/null || echo "?")
    REMOTE_DATE=$(git log -1 "origin/$REPO_BRANCH" --date=short --format=%ad 2>/dev/null || echo "?")
    BEHIND=$(git rev-list --count "HEAD..origin/$REPO_BRANCH" 2>/dev/null || echo "0")

    echo -e "${WHITE}Р›РѕРєР°Р»СЊРЅР°СЏ РІРµСЂСЃРёСЏ:${NC} ${CYAN}$LOCAL_HASH${NC} | $LOCAL_DATE"
    echo -e "${WHITE}РЈРґР°Р»РµРЅРЅР°СЏ РІРµСЂСЃРёСЏ:${NC} ${CYAN}$REMOTE_HASH${NC} | $REMOTE_DATE"
    echo
    if [ "$BEHIND" -gt 0 ] 2>/dev/null; then
        echo -e "${YELLOW}Р”РѕСЃС‚СѓРїРЅРѕ РѕР±РЅРѕРІР»РµРЅРёР№: $BEHIND${NC}"
    else
        echo -e "${GREEN}РћР±РЅРѕРІР»РµРЅРёР№ РЅРµС‚ вЂ” РІС‹ РЅР° Р°РєС‚СѓР°Р»СЊРЅРѕР№ РІРµСЂСЃРёРё${NC}"
    fi
    echo
    echo -e "${WHITE}РџРѕСЃР»РµРґРЅРёРµ РєРѕРјРјРёС‚С‹ (origin/$REPO_BRANCH):${NC}"
    git log -n 5 --date=short --pretty=format:"%h | %ad | %an | %s" "origin/$REPO_BRANCH" 2>/dev/null || echo "РќРµС‚ РґР°РЅРЅС‹С…"
    echo
}

update_menu() {
    while true; do
        show_update_info || true
        echo -e "${WHITE}Р’С‹Р±РµСЂРёС‚Рµ РґРµР№СЃС‚РІРёРµ:${NC}"
        echo -e "  ${CYAN}1)${NC} рџ“¦ РћР±РЅРѕРІРёС‚СЊ Р±РѕС‚Р°"
        echo -e "  ${CYAN}0)${NC} РќР°Р·Р°Рґ"
        echo
        read -p "Р’Р°С€ РІС‹Р±РѕСЂ: " choice
        case $choice in
            1) do_update; read -p "РќР°Р¶РјРёС‚Рµ Enter..." ;;
            0) return ;;
            *) echo -e "${RED}РќРµРІРµСЂРЅС‹Р№ РІС‹Р±РѕСЂ${NC}"; sleep 1 ;;
        esac
    done
}

do_backup() {
    check_install_dir
    local BACKUP_DIR="$INSTALL_DIR/data/backups"
    local TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    mkdir -p "$BACKUP_DIR"
    
    echo -e "${CYAN}рџ’ѕ РЎРѕР·РґР°РЅРёРµ СЂРµР·РµСЂРІРЅРѕР№ РєРѕРїРёРё...${NC}"
    
    # Р‘СЌРєР°Рї Р±Р°Р·С‹ РґР°РЅРЅС‹С…
    echo -e "  ${WHITE}в†’ Р‘Р°Р·Р° РґР°РЅРЅС‹С…...${NC}"
    docker compose -f "$COMPOSE_FILE" exec -T postgres pg_dump -U remnawave_user remnawave_bot > "$BACKUP_DIR/db_$TIMESTAMP.sql" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo -e "  ${GREEN}вњ… db_$TIMESTAMP.sql${NC}"
    else
        echo -e "  ${RED}вќЊ РћС€РёР±РєР° Р±СЌРєР°РїР° Р‘Р”${NC}"
    fi
    
    # Р‘СЌРєР°Рї .env
    echo -e "  ${WHITE}в†’ РљРѕРЅС„РёРіСѓСЂР°С†РёСЏ...${NC}"
    cp .env "$BACKUP_DIR/.env_$TIMESTAMP"
    echo -e "  ${GREEN}вњ… .env_$TIMESTAMP${NC}"
    
    echo
    echo -e "${GREEN}вњ… Р‘СЌРєР°Рї СЃРѕР·РґР°РЅ: $BACKUP_DIR${NC}"
    
    # РџРѕРєР°Р·С‹РІР°РµРј СЂР°Р·РјРµСЂ Р±СЌРєР°РїРѕРІ
    echo -e "${WHITE}рџ“Ѓ Р Р°Р·РјРµСЂ Р±СЌРєР°РїРѕРІ:${NC}"
    du -sh "$BACKUP_DIR" 2>/dev/null
}

do_health() {
    check_install_dir
    
    echo -e "${CYAN}в•”в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•—${NC}"
    echo -e "${CYAN}в•‘           рџЏҐ Р”РРђР“РќРћРЎРўРРљРђ РЎРРЎРўР•РњР« рџЏҐ                          в•‘${NC}"
    echo -e "${CYAN}в•љв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ќ${NC}"
    echo
    
    echo -e "${WHITE}рџђі РЎС‚Р°С‚СѓСЃ РєРѕРЅС‚РµР№РЅРµСЂРѕРІ:${NC}"
    docker compose -f "$COMPOSE_FILE" ps
    echo
    
    echo -e "${WHITE}рџ“Љ РџСЂРѕРІРµСЂРєР° СЃРµСЂРІРёСЃРѕРІ:${NC}"
    
    # Bot
    if docker ps --format '{{.Names}}' | grep -q "remnawave_bot"; then
        echo -e "  ${GREEN}вњ… Bot: СЂР°Р±РѕС‚Р°РµС‚${NC}"
    else
        echo -e "  ${RED}вќЊ Bot: РЅРµ Р·Р°РїСѓС‰РµРЅ${NC}"
    fi
    
    # PostgreSQL
    if docker compose -f "$COMPOSE_FILE" exec -T postgres pg_isready -U remnawave_user -d remnawave_bot >/dev/null 2>&1; then
        echo -e "  ${GREEN}вњ… PostgreSQL: СЂР°Р±РѕС‚Р°РµС‚${NC}"
    else
        echo -e "  ${RED}вќЊ PostgreSQL: РЅРµ РѕС‚РІРµС‡Р°РµС‚${NC}"
    fi
    
    # Redis
    if docker compose -f "$COMPOSE_FILE" exec -T redis redis-cli ping >/dev/null 2>&1; then
        echo -e "  ${GREEN}вњ… Redis: СЂР°Р±РѕС‚Р°РµС‚${NC}"
    else
        echo -e "  ${RED}вќЊ Redis: РЅРµ РѕС‚РІРµС‡Р°РµС‚${NC}"
    fi
    
    # Health endpoint
    local health_code=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/health 2>/dev/null)
    if [ "$health_code" = "200" ]; then
        echo -e "  ${GREEN}вњ… Health endpoint: РґРѕСЃС‚СѓРїРµРЅ${NC}"
    else
        echo -e "  ${YELLOW}вљ пёЏ  Health endpoint: РЅРµРґРѕСЃС‚СѓРїРµРЅ (РєРѕРґ: $health_code)${NC}"
    fi
    
    echo
    echo -e "${WHITE}рџ“€ РСЃРїРѕР»СЊР·РѕРІР°РЅРёРµ СЂРµСЃСѓСЂСЃРѕРІ:${NC}"
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" 2>/dev/null | grep -E "remnawave|postgres|redis|NAME"
    
    echo
    echo -e "${WHITE}рџ’ѕ РњРµСЃС‚Рѕ РЅР° РґРёСЃРєРµ:${NC}"
    df -h "$INSTALL_DIR" 2>/dev/null | tail -1
    
    echo
    echo -e "${WHITE}рџ“‹ РџРѕСЃР»РµРґРЅРёРµ 10 СЃС‚СЂРѕРє Р»РѕРіРѕРІ:${NC}"
    docker compose -f "$COMPOSE_FILE" logs --tail=10 bot 2>/dev/null
    
    echo
    echo -e "${GREEN}вњ… Р”РёР°РіРЅРѕСЃС‚РёРєР° Р·Р°РІРµСЂС€РµРЅР°${NC}"
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
        echo -e "${PURPLE}в•”в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•—${NC}"
        echo -e "${PURPLE}в•‘           вљ™пёЏ  РќРђРЎРўР РћР™РљР Р‘РћРўРђ вљ™пёЏ                                в•‘${NC}"
        echo -e "${PURPLE}в•љв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ќ${NC}"
        echo
        echo -e "${WHITE}РўРµРєСѓС‰Р°СЏ РєРѕРЅС„РёРіСѓСЂР°С†РёСЏ:${NC}"
        echo -e "  BOT_TOKEN:    ${CYAN}$(get_env_value BOT_TOKEN | head -c 25)...${NC}"
        echo -e "  ADMIN_IDS:    ${CYAN}$(get_env_value ADMIN_IDS)${NC}"
        echo -e "  API_URL:      ${CYAN}$(get_env_value REMNAWAVE_API_URL)${NC}"
        echo -e "  BOT_RUN_MODE: ${CYAN}$(get_env_value BOT_RUN_MODE)${NC}"
        echo
        echo -e "${WHITE}Р’С‹Р±РµСЂРёС‚Рµ РґРµР№СЃС‚РІРёРµ:${NC}"
        echo -e "  ${CYAN}1)${NC} РР·РјРµРЅРёС‚СЊ BOT_TOKEN"
        echo -e "  ${CYAN}2)${NC} РР·РјРµРЅРёС‚СЊ ADMIN_IDS"
        echo -e "  ${CYAN}3)${NC} РР·РјРµРЅРёС‚СЊ REMNAWAVE_API_KEY"
        echo -e "  ${CYAN}4)${NC} РР·РјРµРЅРёС‚СЊ REMNAWAVE_API_URL"
        echo -e "  ${CYAN}5)${NC} РћС‚РєСЂС‹С‚СЊ .env РІ СЂРµРґР°РєС‚РѕСЂРµ"
        echo -e "  ${CYAN}6)${NC} РџРµСЂРµР·Р°РїСѓСЃС‚РёС‚СЊ Р±РѕС‚Р° (РїСЂРёРјРµРЅРёС‚СЊ РёР·РјРµРЅРµРЅРёСЏ)"
        echo -e "  ${CYAN}0)${NC} РќР°Р·Р°Рґ"
        echo
        read -p "Р’Р°С€ РІС‹Р±РѕСЂ: " choice
        
        case $choice in
            1)
                read -p "РќРѕРІС‹Р№ BOT_TOKEN (Enter РґР»СЏ РѕС‚РјРµРЅС‹): " NEW_VALUE
                if [ -n "$NEW_VALUE" ]; then
                    set_env_value "BOT_TOKEN" "$NEW_VALUE"
                    echo -e "${GREEN}вњ… BOT_TOKEN РѕР±РЅРѕРІР»С‘РЅ${NC}"
                fi
                ;;
            2)
                read -p "РќРѕРІС‹Рµ ADMIN_IDS (Enter РґР»СЏ РѕС‚РјРµРЅС‹): " NEW_VALUE
                if [ -n "$NEW_VALUE" ]; then
                    set_env_value "ADMIN_IDS" "$NEW_VALUE"
                    echo -e "${GREEN}вњ… ADMIN_IDS РѕР±РЅРѕРІР»РµРЅС‹${NC}"
                fi
                ;;
            3)
                read -p "РќРѕРІС‹Р№ REMNAWAVE_API_KEY (Enter РґР»СЏ РѕС‚РјРµРЅС‹): " NEW_VALUE
                if [ -n "$NEW_VALUE" ]; then
                    set_env_value "REMNAWAVE_API_KEY" "$NEW_VALUE"
                    echo -e "${GREEN}вњ… REMNAWAVE_API_KEY РѕР±РЅРѕРІР»С‘РЅ${NC}"
                fi
                ;;
            4)
                read -p "РќРѕРІС‹Р№ REMNAWAVE_API_URL (Enter РґР»СЏ РѕС‚РјРµРЅС‹): " NEW_VALUE
                if [ -n "$NEW_VALUE" ]; then
                    set_env_value "REMNAWAVE_API_URL" "$NEW_VALUE"
                    echo -e "${GREEN}вњ… REMNAWAVE_API_URL РѕР±РЅРѕРІР»С‘РЅ${NC}"
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
                echo -e "${RED}РќРµРІРµСЂРЅС‹Р№ РІС‹Р±РѕСЂ${NC}"
                ;;
        esac
        
        [ "$choice" != "0" ] && read -p "РќР°Р¶РјРёС‚Рµ Enter..."
    done
}

update_installer_scripts() {
    echo -e "${CYAN}рџ“Ґ РћР±РЅРѕРІР»РµРЅРёРµ СЃРєСЂРёРїС‚РѕРІ СѓСЃС‚Р°РЅРѕРІС‰РёРєР°...${NC}"
    local TEMP_DIR=$(mktemp -d)
    
    git clone --depth 1 --single-branch --branch spiderman https://github.com/RamaPulya/bot_auto_install.git "$TEMP_DIR" 2>/dev/null
    
    if [ -d "$TEMP_DIR/scripts" ]; then
        # Р‘СЌРєР°Рї СЃС‚Р°СЂРѕР№ РІРµСЂСЃРёРё
        if [ -d "$INSTALLER_DIR" ]; then
            mv "$INSTALLER_DIR" "${INSTALLER_DIR}.backup_$(date +%Y%m%d_%H%M%S)" 2>/dev/null
        fi
        
        # РљРѕРїРёСЂСѓРµРј РЅРѕРІСѓСЋ РІРµСЂСЃРёСЋ
        cp -r "$TEMP_DIR/scripts" "$INSTALLER_DIR"
        chmod +x "$INSTALLER_DIR"/*.sh 2>/dev/null
        chmod +x "$INSTALLER_DIR"/lib/*.sh 2>/dev/null
        
        local NEW_VERSION=$(cat "$INSTALLER_DIR/VERSION" 2>/dev/null || echo "?")
        echo -e "${GREEN}вњ… РћР±РЅРѕРІР»РµРЅРѕ РґРѕ РІРµСЂСЃРёРё $NEW_VERSION${NC}"
        
        # РЈРґР°Р»СЏРµРј СЃС‚Р°СЂС‹Рµ Р±СЌРєР°РїС‹ (РѕСЃС‚Р°РІР»СЏРµРј РїРѕСЃР»РµРґРЅРёРµ 3)
        ls -dt "${INSTALLER_DIR}.backup_"* 2>/dev/null | tail -n +4 | xargs -r rm -rf
    else
        echo -e "${RED}вќЊ РћС€РёР±РєР° РѕР±РЅРѕРІР»РµРЅРёСЏ${NC}"
    fi
    
    rm -rf "$TEMP_DIR"
}

show_changelog() {
    echo -e "${CYAN}рџ“‹ РСЃС‚РѕСЂРёСЏ РёР·РјРµРЅРµРЅРёР№:${NC}"
    echo "в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ"
    local CHANGELOG=$(curl -fsSL --connect-timeout 5 https://raw.githubusercontent.com/RamaPulya/bot_auto_install/spiderman/CHANGELOG.md 2>/dev/null)
    if [ -n "$CHANGELOG" ]; then
        echo "$CHANGELOG" | head -40
    else
        echo "РќРµ СѓРґР°Р»РѕСЃСЊ Р·Р°РіСЂСѓР·РёС‚СЊ changelog"
    fi
    echo "в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ"
}

check_installer_updates() {
    echo -e "${CYAN}рџ”Ќ РџСЂРѕРІРµСЂРєР° РѕР±РЅРѕРІР»РµРЅРёР№ СѓСЃС‚Р°РЅРѕРІС‰РёРєР°...${NC}"
    echo
    
    # РџРѕР»СѓС‡Р°РµРј Р»РѕРєР°Р»СЊРЅСѓСЋ РІРµСЂСЃРёСЋ
    local LOCAL_VERSION="0.0.0"
    if [ -f "$INSTALLER_DIR/VERSION" ]; then
        LOCAL_VERSION=$(cat "$INSTALLER_DIR/VERSION")
    fi
    
    # РџРѕР»СѓС‡Р°РµРј РІРµСЂСЃРёСЋ СЃ GitHub
    local REMOTE_VERSION=$(curl -fsSL https://raw.githubusercontent.com/RamaPulya/bot_auto_install/spiderman/scripts/VERSION 2>/dev/null)
    
    if [ -z "$REMOTE_VERSION" ]; then
        echo -e "${RED}вќЊ РќРµ СѓРґР°Р»РѕСЃСЊ РїРѕР»СѓС‡РёС‚СЊ РІРµСЂСЃРёСЋ СЃ GitHub${NC}"
        return 1
    fi
    
    echo -e "${WHITE}Р›РѕРєР°Р»СЊРЅР°СЏ РІРµСЂСЃРёСЏ:  ${CYAN}$LOCAL_VERSION${NC}"
    echo -e "${WHITE}Р’РµСЂСЃРёСЏ РЅР° GitHub:  ${CYAN}$REMOTE_VERSION${NC}"
    echo
    
    # РЎСЂР°РІРЅРёРІР°РµРј РІРµСЂСЃРёРё
    if [ "$LOCAL_VERSION" = "$REMOTE_VERSION" ]; then
        echo -e "${GREEN}вњ… РЈ РІР°СЃ Р°РєС‚СѓР°Р»СЊРЅР°СЏ РІРµСЂСЃРёСЏ СѓСЃС‚Р°РЅРѕРІС‰РёРєР°${NC}"
        return 0
    fi
    
    # Р•СЃС‚СЊ РѕР±РЅРѕРІР»РµРЅРёРµ - РїРѕРєР°Р·С‹РІР°РµРј changelog
    echo -e "${YELLOW}рџ“¦ Р”РѕСЃС‚СѓРїРЅРѕ РѕР±РЅРѕРІР»РµРЅРёРµ!${NC}"
    echo
    
    # РџСЂРѕР±СѓРµРј РїРѕР»СѓС‡РёС‚СЊ changelog
    local CHANGELOG=$(curl -fsSL https://raw.githubusercontent.com/RamaPulya/bot_auto_install/spiderman/CHANGELOG.md 2>/dev/null | head -50)
    if [ -n "$CHANGELOG" ]; then
        echo -e "${WHITE}РР·РјРµРЅРµРЅРёСЏ:${NC}"
        echo "в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ"
        echo "$CHANGELOG" | head -30
        echo "в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ"
        echo
    fi
    
    read -p "РћР±РЅРѕРІРёС‚СЊ СѓСЃС‚Р°РЅРѕРІС‰РёРє РґРѕ РІРµСЂСЃРёРё $REMOTE_VERSION? (y/n) [y]: " -n 1 -r
    echo
    REPLY=${REPLY:-y}
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${CYAN}рџ“Ґ РћР±РЅРѕРІР»РµРЅРёРµ СЃРєСЂРёРїС‚РѕРІ...${NC}"
        local TEMP_DIR=$(mktemp -d)
        
        git clone --depth 1 --single-branch --branch spiderman https://github.com/RamaPulya/bot_auto_install.git "$TEMP_DIR" 2>/dev/null
        
        if [ -d "$TEMP_DIR/scripts" ]; then
            # Р‘СЌРєР°Рї СЃС‚Р°СЂРѕР№ РІРµСЂСЃРёРё
            if [ -d "$INSTALLER_DIR" ]; then
                mv "$INSTALLER_DIR" "${INSTALLER_DIR}.backup_$(date +%Y%m%d_%H%M%S)"
            fi
            
            # РљРѕРїРёСЂСѓРµРј РЅРѕРІСѓСЋ РІРµСЂСЃРёСЋ
            cp -r "$TEMP_DIR/scripts" "$INSTALLER_DIR"
            chmod +x "$INSTALLER_DIR"/*.sh 2>/dev/null
            chmod +x "$INSTALLER_DIR"/lib/*.sh 2>/dev/null
            
            echo -e "${GREEN}вњ… РЈСЃС‚Р°РЅРѕРІС‰РёРє РѕР±РЅРѕРІР»С‘РЅ РґРѕ РІРµСЂСЃРёРё $REMOTE_VERSION${NC}"
            
            # РЈРґР°Р»СЏРµРј СЃС‚Р°СЂС‹Рµ Р±СЌРєР°РїС‹ (РѕСЃС‚Р°РІР»СЏРµРј РїРѕСЃР»РµРґРЅРёРµ 3)
            ls -dt "${INSTALLER_DIR}.backup_"* 2>/dev/null | tail -n +4 | xargs -r rm -rf
        else
            echo -e "${RED}вќЊ РћС€РёР±РєР° РѕР±РЅРѕРІР»РµРЅРёСЏ${NC}"
        fi
        
        rm -rf "$TEMP_DIR"
    else
        echo -e "${YELLOW}РћР±РЅРѕРІР»РµРЅРёРµ РѕС‚РјРµРЅРµРЅРѕ${NC}"
    fi
}

do_install() {
    echo -e "${PURPLE}в•”в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•—${NC}"
    echo -e "${PURPLE}в•‘           рџ”§ РЈРЎРўРђРќРћР’Р©РРљ Р‘РћРўРђ рџ”§                              в•‘${NC}"
    echo -e "${PURPLE}в•љв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ќ${NC}"
    echo
    
    # РџСЂРѕРІРµСЂСЏРµРј РЅР°Р»РёС‡РёРµ Р»РѕРєР°Р»СЊРЅС‹С… СЃРєСЂРёРїС‚РѕРІ СѓСЃС‚Р°РЅРѕРІС‰РёРєР°
    if [ -d "$INSTALLER_DIR" ] && [ -f "$INSTALLER_DIR/install.sh" ]; then
        # РџРѕР»СѓС‡Р°РµРј Р»РѕРєР°Р»СЊРЅСѓСЋ РІРµСЂСЃРёСЋ
        local LOCAL_VERSION="0.0.0"
        if [ -f "$INSTALLER_DIR/VERSION" ]; then
            LOCAL_VERSION=$(cat "$INSTALLER_DIR/VERSION")
        fi
        
        echo -e "${GREEN}вњ… РќР°Р№РґРµРЅС‹ Р»РѕРєР°Р»СЊРЅС‹Рµ СЃРєСЂРёРїС‚С‹ СѓСЃС‚Р°РЅРѕРІС‰РёРєР°${NC}"
        echo -e "${WHITE}Р’РµСЂСЃРёСЏ: ${CYAN}$LOCAL_VERSION${NC}"
        echo
        
        # РџСЂРѕРІРµСЂСЏРµРј РѕР±РЅРѕРІР»РµРЅРёСЏ
        echo -e "${CYAN}рџ”Ќ РџСЂРѕРІРµСЂРєР° РѕР±РЅРѕРІР»РµРЅРёР№...${NC}"
        local REMOTE_VERSION=$(curl -fsSL --connect-timeout 5 https://raw.githubusercontent.com/RamaPulya/bot_auto_install/spiderman/scripts/VERSION 2>/dev/null)
        
        if [ -n "$REMOTE_VERSION" ] && [ "$LOCAL_VERSION" != "$REMOTE_VERSION" ]; then
            echo -e "${YELLOW}рџ“¦ Р”РѕСЃС‚СѓРїРЅР° РЅРѕРІР°СЏ РІРµСЂСЃРёСЏ: ${WHITE}$REMOTE_VERSION${NC}"
            echo
            echo -e "${WHITE}Р’Р°СЂРёР°РЅС‚С‹:${NC}"
            echo -e "  ${CYAN}1)${NC} РћР±РЅРѕРІРёС‚СЊ Рё Р·Р°РїСѓСЃС‚РёС‚СЊ (СЂРµРєРѕРјРµРЅРґСѓРµС‚СЃСЏ)"
            echo -e "  ${CYAN}2)${NC} Р—Р°РїСѓСЃС‚РёС‚СЊ С‚РµРєСѓС‰СѓСЋ РІРµСЂСЃРёСЋ ($LOCAL_VERSION)"
            echo -e "  ${CYAN}3)${NC} РџРѕСЃРјРѕС‚СЂРµС‚СЊ РёР·РјРµРЅРµРЅРёСЏ"
            echo -e "  ${CYAN}0)${NC} РћС‚РјРµРЅР°"
            echo
            read -p "Р’Р°С€ РІС‹Р±РѕСЂ [1]: " choice
            choice=${choice:-1}
            
            case $choice in
                1)
                    update_installer_scripts
                    echo -e "${CYAN}рџљЂ Р—Р°РїСѓСЃРє СѓСЃС‚Р°РЅРѕРІС‰РёРєР°...${NC}"
                    sudo bash "$INSTALLER_DIR/install.sh"
                    ;;
                2)
                    echo -e "${CYAN}рџљЂ Р—Р°РїСѓСЃРє СѓСЃС‚Р°РЅРѕРІС‰РёРєР° v$LOCAL_VERSION...${NC}"
                    sudo bash "$INSTALLER_DIR/install.sh"
                    ;;
                3)
                    show_changelog
                    read -p "РќР°Р¶РјРёС‚Рµ Enter..."
                    do_install  # Р’РµСЂРЅСѓС‚СЊСЃСЏ РІ РјРµРЅСЋ
                    ;;
                0)
                    return
                    ;;
            esac
        else
            echo -e "${GREEN}вњ… РЈ РІР°СЃ Р°РєС‚СѓР°Р»СЊРЅР°СЏ РІРµСЂСЃРёСЏ${NC}"
            echo
            echo -e "${WHITE}Р’Р°СЂРёР°РЅС‚С‹:${NC}"
            echo -e "  ${CYAN}1)${NC} Р—Р°РїСѓСЃС‚РёС‚СЊ СѓСЃС‚Р°РЅРѕРІС‰РёРє"
            echo -e "  ${CYAN}2)${NC} РџСЂРёРЅСѓРґРёС‚РµР»СЊРЅРѕ СЃРєР°С‡Р°С‚СЊ СЃ GitHub"
            echo -e "  ${CYAN}0)${NC} РћС‚РјРµРЅР°"
            echo
            read -p "Р’Р°С€ РІС‹Р±РѕСЂ [1]: " choice
            choice=${choice:-1}
            
            case $choice in
                1)
                    echo -e "${CYAN}рџљЂ Р—Р°РїСѓСЃРє СѓСЃС‚Р°РЅРѕРІС‰РёРєР°...${NC}"
                    sudo bash "$INSTALLER_DIR/install.sh"
                    ;;
                2)
                    echo -e "${CYAN}рџ“Ґ РЎРєР°С‡РёРІР°РЅРёРµ СЃ GitHub...${NC}"
                    curl -fsSL https://raw.githubusercontent.com/RamaPulya/bot_auto_install/spiderman/scripts/quick-install.sh | sudo bash
                    ;;
                0)
                    return
                    ;;
            esac
        fi
    else
        echo -e "${YELLOW}вљ пёЏ  Р›РѕРєР°Р»СЊРЅС‹Рµ СЃРєСЂРёРїС‚С‹ СѓСЃС‚Р°РЅРѕРІС‰РёРєР° РЅРµ РЅР°Р№РґРµРЅС‹${NC}"
        echo
        echo -e "${WHITE}Р’Р°СЂРёР°РЅС‚С‹:${NC}"
        echo -e "  ${CYAN}1)${NC} РЎРєР°С‡Р°С‚СЊ Рё Р·Р°РїСѓСЃС‚РёС‚СЊ СѓСЃС‚Р°РЅРѕРІС‰РёРє СЃ GitHub"
        echo -e "  ${CYAN}2)${NC} РЎРєР°С‡Р°С‚СЊ СЃРєСЂРёРїС‚С‹ Р»РѕРєР°Р»СЊРЅРѕ (Р±РµР· Р·Р°РїСѓСЃРєР°)"
        echo -e "  ${CYAN}0)${NC} РћС‚РјРµРЅР°"
        echo
        read -p "Р’Р°С€ РІС‹Р±РѕСЂ [1]: " choice
        choice=${choice:-1}
        
        case $choice in
            1)
                echo -e "${CYAN}рџ“Ґ РЎРєР°С‡РёРІР°РЅРёРµ СЃ GitHub...${NC}"
                curl -fsSL https://raw.githubusercontent.com/RamaPulya/bot_auto_install/spiderman/scripts/quick-install.sh | sudo bash
                ;;
            2)
                echo -e "${CYAN}рџ“Ґ РЎРєР°С‡РёРІР°РЅРёРµ СЃРєСЂРёРїС‚РѕРІ...${NC}"
                mkdir -p "$INSTALLER_DIR"
                local TEMP_DIR=$(mktemp -d)
                git clone --depth 1 --single-branch --branch spiderman https://github.com/RamaPulya/bot_auto_install.git "$TEMP_DIR" 2>/dev/null
                if [ -d "$TEMP_DIR/scripts" ]; then
                    cp -r "$TEMP_DIR/scripts"/* "$INSTALLER_DIR/"
                    chmod +x "$INSTALLER_DIR"/*.sh 2>/dev/null
                    chmod +x "$INSTALLER_DIR"/lib/*.sh 2>/dev/null
                    echo -e "${GREEN}вњ… РЎРєСЂРёРїС‚С‹ СЃРѕС…СЂР°РЅРµРЅС‹ РІ $INSTALLER_DIR${NC}"
                else
                    echo -e "${RED}вќЊ РћС€РёР±РєР° Р·Р°РіСЂСѓР·РєРё${NC}"
                fi
                rm -rf "$TEMP_DIR"
                ;;
            0)
                return
                ;;
            *)
                echo -e "${RED}РќРµРІРµСЂРЅС‹Р№ РІС‹Р±РѕСЂ${NC}"
                ;;
        esac
    fi
}

do_uninstall() {
    check_install_dir
    
    echo -e "${RED}в•”в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•—${NC}"
    echo -e "${RED}в•‘           рџ—‘пёЏ  РЈР”РђР›Р•РќРР• Р‘РћРўРђ рџ—‘пёЏ                                в•‘${NC}"
    echo -e "${RED}в•љв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ќ${NC}"
    echo
    echo -e "${YELLOW}вљ пёЏ  Р’РќРРњРђРќРР•! Р­С‚Рѕ РґРµР№СЃС‚РІРёРµ СѓРґР°Р»РёС‚:${NC}"
    echo -e "   - Docker РєРѕРЅС‚РµР№РЅРµСЂС‹ Р±РѕС‚Р°"
    echo -e "   - Р”Р°РЅРЅС‹Рµ PostgreSQL Рё Redis (РѕРїС†РёРѕРЅР°Р»СЊРЅРѕ)"
    echo
    
    read -p "Р’РІРµРґРёС‚Рµ 'yes' РґР»СЏ РїРѕРґС‚РІРµСЂР¶РґРµРЅРёСЏ: " CONFIRM
    if [ "$CONFIRM" != "yes" ]; then
        echo -e "${GREEN}РЈРґР°Р»РµРЅРёРµ РѕС‚РјРµРЅРµРЅРѕ${NC}"
        return
    fi
    
    echo -e "${CYAN}рџ›‘ РћСЃС‚Р°РЅРѕРІРєР° РєРѕРЅС‚РµР№РЅРµСЂРѕРІ...${NC}"
    docker compose -f "$COMPOSE_FILE" down
    
    read -p "РЈРґР°Р»РёС‚СЊ РґР°РЅРЅС‹Рµ (volumes)? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${CYAN}рџ’ѕ РЈРґР°Р»РµРЅРёРµ volumes...${NC}"
        docker compose -f "$COMPOSE_FILE" down -v
        docker volume ls -q | grep -E "bedolaga|remnawave.*bot" | xargs -r docker volume rm 2>/dev/null
        echo -e "${GREEN}вњ… Volumes СѓРґР°Р»РµРЅС‹${NC}"
    fi
    
    # РЈРґР°Р»РµРЅРёРµ РіР»РѕР±Р°Р»СЊРЅРѕР№ РєРѕРјР°РЅРґС‹
    if [ -f "/usr/local/bin/bot" ]; then
        rm -f /usr/local/bin/bot
        echo -e "${GREEN}вњ… РљРѕРјР°РЅРґР° 'bot' СѓРґР°Р»РµРЅР°${NC}"
    fi
    
    echo
    echo -e "${GREEN}вњ… РЈРґР°Р»РµРЅРёРµ Р·Р°РІРµСЂС€РµРЅРѕ${NC}"
    echo -e "${YELLOW}Р”РёСЂРµРєС‚РѕСЂРёСЏ $INSTALL_DIR РѕСЃС‚Р°РІР»РµРЅР°. РЈРґР°Р»РёС‚Рµ РІСЂСѓС‡РЅСѓСЋ:${NC}"
    echo -e "${CYAN}rm -rf $INSTALL_DIR${NC}"
}

# в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђ
# РРќРўР•Р РђРљРўРР’РќРћР• РњР•РќР®
# в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђ

show_menu() {
    clear
    echo -e "${PURPLE}в•”в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•—${NC}"
    echo -e "${PURPLE}в•‘        рџ¤– REMNAWAVE BEDOLAGA BOT вЂ” РЈРџР РђР’Р›Р•РќРР• рџ¤–             в•‘${NC}"
    echo -e "${PURPLE}в•љв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ќ${NC}"
    echo
    echo -e "${WHITE}Р”РёСЂРµРєС‚РѕСЂРёСЏ:${NC} ${CYAN}$INSTALL_DIR${NC}"
    echo
    
    # Р‘С‹СЃС‚СЂС‹Р№ СЃС‚Р°С‚СѓСЃ
    if docker ps --format '{{.Names}}' | grep -q "remnawave_bot"; then
        echo -e "${WHITE}РЎС‚Р°С‚СѓСЃ:${NC} ${GREEN}в—Џ Р‘РѕС‚ СЂР°Р±РѕС‚Р°РµС‚${NC}"
    else
        echo -e "${WHITE}РЎС‚Р°С‚СѓСЃ:${NC} ${RED}в—‹ Р‘РѕС‚ РѕСЃС‚Р°РЅРѕРІР»РµРЅ${NC}"
    fi
    echo
    
    echo -e "${WHITE}в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђ${NC}"
    echo -e "${WHITE}Р’С‹Р±РµСЂРёС‚Рµ РґРµР№СЃС‚РІРёРµ:${NC}"
    echo
    echo -e "  ${CYAN}1)${NC} рџ“‹ Р›РѕРіРё              ${CYAN}6)${NC} рџ’ѕ РЎРѕР·РґР°С‚СЊ Р±СЌРєР°Рї"
    echo -e "  ${CYAN}2)${NC} рџ“Љ РЎС‚Р°С‚СѓСЃ            ${CYAN}7)${NC} рџЏҐ Р”РёР°РіРЅРѕСЃС‚РёРєР°"
    echo -e "  ${CYAN}3)${NC} рџ”„ РџРµСЂРµР·Р°РїСѓСЃРє        ${CYAN}8)${NC} вљ™пёЏ  РќР°СЃС‚СЂРѕР№РєРё"
    echo -e "  ${CYAN}4)${NC} в–¶пёЏ  Р—Р°РїСѓСЃРє            ${CYAN}9)${NC} рџ“¦ РћР±РЅРѕРІРёС‚СЊ Р±РѕС‚Р°"
    echo -e "  ${CYAN}5)${NC} вЏ№пёЏ  РћСЃС‚Р°РЅРѕРІРєР°         ${CYAN}10)${NC} рџ› пёЏ РћР±РЅРѕРІРёС‚СЊ СЃРєСЂРёРїС‚"
    echo
    echo -e "  ${CYAN}i)${NC} рџ”§ РЈСЃС‚Р°РЅРѕРІС‰РёРє        ${CYAN}L)${NC} рџ—‘пёЏ  РЈРґР°Р»РµРЅРёРµ"
    echo -e "  ${CYAN}q)${NC} Р’С‹С…РѕРґ"
    echo
}

interactive_menu() {
    while true; do
        show_menu
        read -p "Р’Р°С€ РІС‹Р±РѕСЂ: " choice
        
        case $choice in
            1) do_logs ;;
            2) do_status; read -p "РќР°Р¶РјРёС‚Рµ Enter..." ;;
            3) do_restart; read -p "РќР°Р¶РјРёС‚Рµ Enter..." ;;
            4) do_start; read -p "РќР°Р¶РјРёС‚Рµ Enter..." ;;
            5) do_stop; read -p "РќР°Р¶РјРёС‚Рµ Enter..." ;;
            6) do_backup; read -p "РќР°Р¶РјРёС‚Рµ Enter..." ;;
            7) do_health; read -p "РќР°Р¶РјРёС‚Рµ Enter..." ;;
            8) do_config ;;
            9) update_menu ;;
            10) update_installer_scripts; read -p "РќР°Р¶РјРёС‚Рµ Enter..." ;;
            i|I|install) do_install; read -p "РќР°Р¶РјРёС‚Рµ Enter..." ;;
            l|L) do_uninstall; break ;;
            q|Q|exit) echo -e "${GREEN}Р”Рѕ СЃРІРёРґР°РЅРёСЏ!${NC}"; exit 0 ;;
            *) echo -e "${RED}РќРµРІРµСЂРЅС‹Р№ РІС‹Р±РѕСЂ${NC}"; sleep 1 ;;
        esac
    done
}

show_help() {
    echo -e "${PURPLE}в•”в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•—${NC}"
    echo -e "${PURPLE}в•‘        рџ¤– REMNAWAVE BEDOLAGA BOT вЂ” РЎРџР РђР’РљРђ рџ¤–                в•‘${NC}"
    echo -e "${PURPLE}в•љв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ќ${NC}"
    echo
    echo -e "${WHITE}РСЃРїРѕР»СЊР·РѕРІР°РЅРёРµ:${NC}"
    echo -e "  ${CYAN}bot${NC}              вЂ” РРЅС‚РµСЂР°РєС‚РёРІРЅРѕРµ РјРµРЅСЋ"
    echo -e "  ${CYAN}bot <РєРѕРјР°РЅРґР°>${NC}   вЂ” Р’С‹РїРѕР»РЅРёС‚СЊ РєРѕРјР°РЅРґСѓ РЅР°РїСЂСЏРјСѓСЋ"
    echo
    echo -e "${WHITE}РљРѕРјР°РЅРґС‹:${NC}"
    echo -e "  ${GREEN}logs${NC}       вЂ” РџСЂРѕСЃРјРѕС‚СЂ Р»РѕРіРѕРІ Р±РѕС‚Р°"
    echo -e "  ${GREEN}status${NC}     вЂ” РЎС‚Р°С‚СѓСЃ РєРѕРЅС‚РµР№РЅРµСЂРѕРІ"
    echo -e "  ${GREEN}restart${NC}    вЂ” РџРµСЂРµР·Р°РїСѓСЃРє Р±РѕС‚Р°"
    echo -e "  ${GREEN}start${NC}      вЂ” Р—Р°РїСѓСЃРє Р±РѕС‚Р°"
    echo -e "  ${GREEN}stop${NC}       вЂ” РћСЃС‚Р°РЅРѕРІРєР° Р±РѕС‚Р°"
    echo -e "  ${GREEN}update${NC}     вЂ” РћР±РЅРѕРІР»РµРЅРёРµ Р±РѕС‚Р° (git pull + rebuild)"
    echo -e "  ${GREEN}backup${NC}     вЂ” РЎРѕР·РґР°РЅРёРµ СЂРµР·РµСЂРІРЅРѕР№ РєРѕРїРёРё"
    echo -e "  ${GREEN}health${NC}     вЂ” Р”РёР°РіРЅРѕСЃС‚РёРєР° СЃРёСЃС‚РµРјС‹"
    echo -e "  ${GREEN}config${NC}     вЂ” РР·РјРµРЅРµРЅРёРµ РЅР°СЃС‚СЂРѕРµРє"
    echo -e "  ${GREEN}install${NC}    вЂ” Р—Р°РїСѓСЃС‚РёС‚СЊ СѓСЃС‚Р°РЅРѕРІС‰РёРє (РїРµСЂРµСѓСЃС‚Р°РЅРѕРІРєР°)"
    echo -e "  ${GREEN}uninstall${NC}  вЂ” РЈРґР°Р»РµРЅРёРµ Р±РѕС‚Р°"
    echo
    echo -e "${WHITE}Р”РёСЂРµРєС‚РѕСЂРёСЏ Р±РѕС‚Р°:${NC} $INSTALL_DIR"
    echo -e "${WHITE}РЎРєСЂРёРїС‚С‹ СѓСЃС‚Р°РЅРѕРІС‰РёРєР°:${NC} $INSTALLER_DIR"
}

# в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђ
# РўРћР§РљРђ Р’РҐРћР”Рђ
# в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђ

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
        echo -e "${RED}вќЊ РќРµРёР·РІРµСЃС‚РЅР°СЏ РєРѕРјР°РЅРґР°: $1${NC}"
        echo -e "РСЃРїРѕР»СЊР·СѓР№С‚Рµ ${CYAN}bot help${NC} РґР»СЏ СЃРїСЂР°РІРєРё"
        exit 1
        ;;
esac
BOTSCRIPT
    
    # Р—Р°РјРµРЅСЏРµРј РїР»РµР№СЃС…РѕР»РґРµСЂС‹ РЅР° СЂРµР°Р»СЊРЅС‹Рµ Р·РЅР°С‡РµРЅРёСЏ
    sed -i "s|__INSTALL_DIR__|$INSTALL_DIR|g" /usr/local/bin/bot
    sed -i "s|__COMPOSE_FILE__|$compose_file|g" /usr/local/bin/bot
    
    chmod +x /usr/local/bin/bot
    
    print_success "РљРѕРјР°РЅРґР° СѓРїСЂР°РІР»РµРЅРёСЏ 'bot' СЃРѕР·РґР°РЅР°"
    echo
    echo -e "${GREEN}рџЋ‰ РўРµРїРµСЂСЊ РІС‹ РјРѕР¶РµС‚Рµ СѓРїСЂР°РІР»СЏС‚СЊ Р±РѕС‚РѕРј РєРѕРјР°РЅРґРѕР№:${NC}"
    echo -e "   ${WHITE}bot${NC}        вЂ” РёРЅС‚РµСЂР°РєС‚РёРІРЅРѕРµ РјРµРЅСЋ"
    echo -e "   ${WHITE}bot help${NC}   вЂ” СЃРїСЂР°РІРєР° РїРѕ РєРѕРјР°РЅРґР°Рј"
}

# Р’С‹РІРѕРґ С„РёРЅР°Р»СЊРЅРѕР№ РёРЅС„РѕСЂРјР°С†РёРё
print_final_info() {
    print_step "РЈСЃС‚Р°РЅРѕРІРєР° Р·Р°РІРµСЂС€РµРЅР°!"
    
    echo -e "${GREEN}"
    echo "в•”в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•—"
    echo "в•‘           рџЋ‰ РЈРЎРўРђРќРћР’РљРђ РЈРЎРџР•РЁРќРћ Р—РђР’Р•Р РЁР•РќРђ! рџЋ‰                 в•‘"
    echo "в•љв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ќ"
    echo -e "${NC}"
    
    echo -e "${WHITE}рџ“Ѓ Р”РёСЂРµРєС‚РѕСЂРёСЏ СѓСЃС‚Р°РЅРѕРІРєРё:${NC} ${CYAN}$INSTALL_DIR${NC}"
    echo ""
    
    echo -e "${WHITE}рџЋ® РЈРїСЂР°РІР»РµРЅРёРµ Р±РѕС‚РѕРј:${NC}"
    echo -e "   ${CYAN}bot${NC}          вЂ” РёРЅС‚РµСЂР°РєС‚РёРІРЅРѕРµ РјРµРЅСЋ СѓРїСЂР°РІР»РµРЅРёСЏ"
    echo -e "   ${CYAN}bot help${NC}     вЂ” СЃРїСЂР°РІРєР° РїРѕ РІСЃРµРј РєРѕРјР°РЅРґР°Рј"
    echo -e "   ${CYAN}bot logs${NC}     вЂ” РїСЂРѕСЃРјРѕС‚СЂ Р»РѕРіРѕРІ"
    echo -e "   ${CYAN}bot status${NC}   вЂ” СЃС‚Р°С‚СѓСЃ РєРѕРЅС‚РµР№РЅРµСЂРѕРІ"
    echo -e "   ${CYAN}bot install${NC}  вЂ” Р·Р°РїСѓСЃС‚РёС‚СЊ СѓСЃС‚Р°РЅРѕРІС‰РёРє"
    echo ""
    
    if [ -n "$WEBHOOK_DOMAIN" ]; then
        echo -e "${WHITE}рџЊђ Webhook:${NC} https://$WEBHOOK_DOMAIN"
    fi
    
    if [ -n "$MINIAPP_DOMAIN" ]; then
        echo -e "${WHITE}рџ“± Mini App:${NC} https://$MINIAPP_DOMAIN"
    fi
    
    echo ""
    echo -e "${WHITE}рџ“ќ РљРѕРЅС„РёРіСѓСЂР°С†РёСЏ:${NC} $INSTALL_DIR/.env"
    echo ""
    
    echo -e "${YELLOW}вљ пёЏ  Р’Р°Р¶РЅРѕ:${NC}"
    echo -e "  - РќР°СЃС‚СЂРѕР№С‚Рµ Р±РѕС‚Р° РІ Telegram С‡РµСЂРµР· @BotFather"
    if [ "$PANEL_INSTALLED_LOCALLY" != "true" ] && [ -n "$REMNAWAVE_SECRET_KEY" ]; then
        echo -e "  - РЈР±РµРґРёС‚РµСЃСЊ С‡С‚Рѕ REMNAWAVE_SECRET_KEY СЃРѕРІРїР°РґР°РµС‚ СЃ РїР°РЅРµР»СЊСЋ eGames"
    fi
    if [ "$KEEP_EXISTING_VOLUMES" = "true" ] && [ -n "$OLD_POSTGRES_PASSWORD" ]; then
        echo -e "  - ${GREEN}Р”Р°РЅРЅС‹Рµ PostgreSQL СЃРѕС…СЂР°РЅРµРЅС‹, РїР°СЂРѕР»СЊ РІРѕСЃСЃС‚Р°РЅРѕРІР»РµРЅ РёР· СЃС‚Р°СЂРѕРіРѕ .env${NC}"
    else
        echo -e "  - РЎРѕС…СЂР°РЅРёС‚Рµ РїР°СЂРѕР»СЊ PostgreSQL РёР· С„Р°Р№Р»Р° .env"
    fi
    echo ""
}

# РџРѕРєР°Р· Р»РѕРіРѕРІ
ask_show_logs() {
    echo
    if confirm "РџРѕРєР°Р·Р°С‚СЊ Р»РѕРіРё Р±РѕС‚Р°?"; then
        print_info "РџРѕРєР°Р·С‹РІР°РµРј РїРѕСЃР»РµРґРЅРёРµ 150 СЃС‚СЂРѕРє Р»РѕРіРѕРІ (Ctrl+C РґР»СЏ РІС‹С…РѕРґР°)..."
        sleep 2
        cd "$INSTALL_DIR"
        if [ -f "docker-compose.local.yml" ]; then
            docker compose -f docker-compose.local.yml logs --tail=150 -f bot
        else
            docker compose logs --tail=150 -f bot
        fi
    fi
}




