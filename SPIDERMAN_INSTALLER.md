# Установщик Bedolaga Bot (ветка spiderman)

Этот документ описывает актуальную логику установщика в репозитории `RamaPulya/install-spider-bot` (ветка `spiderman`) и отличия от исходной версии.

Актуальная версия установщика: `1.4.21`.

## Быстрый запуск

```bash
curl -fsSL https://raw.githubusercontent.com/RamaPulya/install-spider-bot/spiderman/scripts/quick-install.sh | sudo bash
```

## Репозитории и ветки

- Инсталлятор: `https://github.com/RamaPulya/install-spider-bot` (ветка `spiderman`)
- Бот: `https://github.com/RamaPulya/spiderbot` (ветка `spiderman`)

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

- Подключение к боту переключено на `RamaPulya/spiderbot` и ветку `spiderman`.
- Все ссылки на установщик переведены на `RamaPulya/install-spider-bot`, ветка `spiderman`.
- Добавлен модуль `scripts/lib/caddy_setup.sh`.
- Обновления бота (`upgrade.sh`, `final.sh`) делают `git pull` нужной ветки.
- `VERSION_CHECK_REPO` указывает на `RamaPulya/spiderbot`.

## Примечания

- Caddy и панель должны быть в одной Docker-сети (обычно `remnawave-network`).
- Бот использует `remnawave_bot` как имя сервиса внутри docker сети.
- Если Caddy не найден или выключен, используется стандартная настройка Nginx.

## Личный кабинет через `bot` (spiderman)

- Добавлены команды:
  - `bot cabinet-install`
  - `bot cabinet-update`
  - `bot cabinet-status`
  - `bot cabinet-logs` (realtime логи `cabinet_frontend`)
  - `bot cabinet-stop`
  - `bot cabinet-start`
  - `bot cabinet-restart` (без `--build`, с `--force-recreate`)
  - `bot cabinet-env` (редактирование `.env` кабинета)
  - `bot cabinet-caddy`
  - `bot cabinet-caddy-edit` (редактирование Caddyfile с подтверждением recreate)
  - `bot cabinet-caddy-recreate`
- Кабинет устанавливается/обновляется в `/opt/bedolaga-cabinet` из `RamaPulya/spidercabinet`, ветка `spiderman`.
- Перед деплоем всегда пересоздаётся `docker-compose.override.yml`, чтобы `cabinet_frontend` подключался к external-сети `remnawave-network`.
- Деплой выполняется через:
  - `docker compose up -d --build --force-recreate cabinet-frontend`
- После деплоя скрипт проверяет фактическое подключение контейнера к `remnawave-network` (без ручного `docker network connect`).

### Меню Cabinet

В интерактивном меню `bot` доступен раздел `12) 🧩 Cabinet`:
- `1) 📥 Установить кабинет`
- `2) 🔄 Обновить кабинет`
- `3) 📊 Статус кабинета`
- `4) 📋 Логи кабинета` (realtime `docker compose logs -f` для `cabinet_frontend`)
- `5) ⏹️ Остановить кабинет`
- `6) ▶️ Запустить кабинет`
- `7) 🔄 Перезапустить кабинет`
- `8) ⚙ Редактировать .env кабинета`
- `9) 🌐 Проверка Caddy (cabinet)`
- `10) 📝 Редактировать Caddyfile`
- `11) 🔁 Пересоздать Caddy`
- `0) ↩ Назад`

Примечание по терминалу:
- Для более стабильного выравнивания в разных SSH/console шрифтах используются terminal-safe символы (без variation selector), чтобы избежать «съезжающих» пробелов рядом с emoji.

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

## Troubleshooting: пункт `10` (Обновить скрипт)

Симптом:
- в меню `bot` пункт `10` показывает `Network check failed: cannot reach GitHub repository`.

Что зафиксировано:
- `v1.4.17`: исправлен корректный выход по `Ctrl+C` (код `130`) без зацикливания на "Неверный выбор".
- `v1.4.18`: исправлена GitHub-аутентификация для `git` через token URL mapping (`x-access-token`).
- `v1.4.19`: добавлен fallback без токена для публичного installer-репозитория.
- `v1.4.20`: в fallback принудительно отключается `credential.helper`, чтобы не ломаться из-за старых/невалидных сохраненных git-учеток.
- `v1.4.21`: для кабинета добавлена авто-настройка `safe.directory`, чтобы `cabinet-update` не падал на `detected dubious ownership`.

Быстрая проверка на сервере:
```bash
/usr/local/bin/bot version
GIT_TERMINAL_PROMPT=0 git -c credential.helper= -c core.askPass=true \
  ls-remote --heads https://github.com/RamaPulya/install-spider-bot.git >/dev/null; echo $?
grep -n "INSTALLER_REPO_URL=" /usr/local/bin/bot | head -n 3
```

Ожидаемо:
- версия установщика: `v1.4.21` или выше;
- `ls-remote` возвращает `0`;
- URL установщика: `https://github.com/RamaPulya/install-spider-bot.git`.

