# Установщик Bedolaga Bot (ветка spiderman)

Этот документ описывает актуальную логику установщика в репозитории `RamaPulya/bot_auto_install` (ветка `spiderman`) и отличия от исходной версии.

## Быстрый запуск

```bash
curl -fsSL https://raw.githubusercontent.com/RamaPulya/bot_auto_install/spiderman/scripts/quick-install.sh | sudo bash
```

## Репозитории и ветки

- Инсталлятор: `https://github.com/RamaPulya/bot_auto_install` (ветка `spiderman`)
- Бот: `https://github.com/RamaPulya/remnawave-bedolaga-telegram-bot` (ветка `spiderman`)

Скрипт установки всегда тянет именно ветку `spiderman` и при обновлении делает `git pull origin spiderman`.

## Сценарии установки

1) Панель и бот на одном сервере  
   - Бот подключается к сети панели (обычно `remnawave-network`).
   - Используется `docker-compose.local.yml` с `external` сетью.
2) Панель на другом сервере  
   - Бот работает standalone, используется `docker-compose.yml`.
   - Подключение к панели идёт по внешнему URL.

## Caddy (когда панель и бот на одном сервере)

Если найдена папка Caddy с файлами:
- `/opt/caddy-remnawave/Caddyfile`
- `/opt/caddy-remnawave/docker-compose.yml`
(или `/root/caddy-remnawave/...`)

то установщик предложит настроить Caddy для бота.

Что делает скрипт:
- Добавляет блоки для доменов бота/miniapp в `Caddyfile`.
- Логирует в `/var/log/caddy/bedolaga-bot.log` и `/var/log/caddy/bedolaga-miniapp.log`.
- Для miniapp добавляет volume:
  `./miniapp -> /var/www/bedolaga-miniapp`
  в `docker-compose.yml` Caddy.
- Перезапускает Caddy через `docker compose up -d`.

Важно:
- `.env` Caddy не трогается.
- Если Caddy включён, Nginx не настраивается (чтобы не конфликтовать на 80/443).

## Изменения в ветке spiderman (установщик)

- Подключение к боту переключено на `RamaPulya/remnawave-bedolaga-telegram-bot` и ветку `spiderman`.
- Все ссылки на установщик переведены на `RamaPulya/bot_auto_install`, ветка `spiderman`.
- Добавлен модуль `scripts/lib/caddy_setup.sh`.
- Обновления бота (`upgrade.sh`, `final.sh`) делают `git pull` нужной ветки.
- `VERSION_CHECK_REPO` указывает на `RamaPulya/remnawave-bedolaga-telegram-bot`.

## Примечания

- Caddy и панель должны быть в одной Docker-сети (обычно `remnawave-network`).
- Бот использует `remnawave_bot` как имя сервиса внутри docker сети.
- Если Caddy не найден или выключен, используется стандартная настройка Nginx.

## Личный кабинет через `bot` (spiderman)

- Добавлены команды:
  - `bot cabinet-install`
  - `bot cabinet-update`
  - `bot cabinet-status`
  - `bot cabinet-caddy`
- Кабинет устанавливается/обновляется в `/opt/bedolaga-cabinet` из `RamaPulya/bedolaga-cabinet`, ветка `spiderman`.
- Перед деплоем всегда пересоздаётся `docker-compose.override.yml`, чтобы `cabinet_frontend` подключался к external-сети `remnawave-network`.
- Деплой выполняется через:
  - `docker compose up -d --build --force-recreate cabinet-frontend`
- После деплоя скрипт проверяет фактическое подключение контейнера к `remnawave-network` (без ручного `docker network connect`).

## Надежность обновлений (preflight + lock)

- Перед критичными действиями (`update`, `installer-update`, `cabinet-*`, `install`, `uninstall`) выполняется preflight:
  - проверка обязательных команд (`docker`, `git`, `df`);
  - доступ к Docker daemon;
  - для root-операций проверка прав на `/opt` и `/usr/local/bin`;
  - проверка прав на запись только для mutating-операций (для read-only команд запись не требуется);
  - проверка свободного места;
  - проверка сети до GitHub для действий, которым нужен download/fetch.
- Для mutating-операций используется lock-файл `/var/lock/remnawave-bot.lock` (через `flock`, fallback на lockfile).
- Для внутренних пересозданий команды `bot` используется `BOT_SKIP_LOCK=true`, чтобы избежать самоблокировки.
- Базовые коды возврата:
  - `20` — preflight не пройден;
  - `21` — lock занят (уже запущена другая операция).
