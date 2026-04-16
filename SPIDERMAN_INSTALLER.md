# SpiderMan Installer

Актуальная инструкция по запуску автоустановщика `install-spider-bot` с нуля.

Репозиторий:
- `H:\Dev\BedolagaBot\bedolaga_auto_install-main`
- `origin`: `https://github.com/RamaPulya/install-spider-bot`
- рабочая ветка: `spiderman`
- версия установщика: `scripts/VERSION`

## Назначение

Автоустановщик разворачивает и обновляет SpiderMan Bot на сервере, а также предоставляет локальное меню `bot` для управления инсталлом.

На сервере команда `bot`:
- основной путь: `/usr/local/bin/bot`
- симлинк: `/usr/bin/bot -> /usr/local/bin/bot`
- запускает `.installer/upgrade.sh` внутри папки установленного бота

## Важно

- Не запускать установщик через `curl ... | bash` как основной способ.
- Причина: при установке пакетов `apt/dpkg` может открыть интерактивный диалог по `sshd_config`, и при запуске через pipe ввод часто ломается.
- Рекомендуемый путь: сначала скачать `quick-install.sh`, потом запускать отдельной командой.
- Все файлы и команды ниже должны сохраняться и выполняться в UTF-8.
- Не хранить в этой инструкции реальные токены, пароли, SMTP-секреты и другие секреты.

## Установка с нуля

Подключитесь к серверу по SSH и выполните:

```bash
cd /root
curl -fsSL https://raw.githubusercontent.com/RamaPulya/install-spider-bot/spiderman/scripts/quick-install.sh -o quick-install.sh
chmod +x quick-install.sh
./quick-install.sh
```

Что делает `quick-install.sh`:
- ставит базовые пакеты для bootstrap;
- скачивает архив ветки `spiderman` репозитория `install-spider-bot`;
- распаковывает его во временную папку;
- находит актуальный `install.sh` внутри репозитория;
- запускает основной установщик.

## Если apt/dpkg занят

Если во время запуска видите ошибку вида:

```text
Could not get lock /var/lib/dpkg/lock-frontend
```

значит на сервере уже висит другой `apt-get` или остался зависший процесс от прошлого запуска.

Порядок восстановления:

```bash
ps -ef | grep apt
kill <PID>
dpkg --configure -a
apt-get -f install
```

После этого снова запустите:

```bash
cd /root
./quick-install.sh
```

Не удалять lock-файлы вручную через `rm`.

## Если появляется окно про sshd_config

При обновлении `openssh-server` `dpkg` может спросить, что делать с `/etc/ssh/sshd_config`.

Обычно для уже доступного сервера нужно выбирать:

```text
keep the local version currently installed
```

Это сохраняет текущую рабочую SSH-конфигурацию сервера.

## Требование для private repositories

Если бот или кабинет тянутся с приватных репозиториев, на сервере должен быть задан:

```bash
/etc/bedolaga/installer.env
```

В этом файле должен быть `GITHUB_TOKEN` с доступом к приватным репозиториям.

В документации токен не хранить.

## После установки

Проверьте, что команда `bot` доступна:

```bash
which bot
bot
```

Также полезно проверить:

```bash
bot --help
```

Если бот уже установлен, команда `bot` запускает меню управления инсталлом.

## Основные пункты меню

- `9)` редактировать compose бота: `docker-compose.local.yml` или `docker-compose.yml`
- `10)` редактировать `Caddyfile`: `/opt/caddy-remnawave/Caddyfile`
- `12)` обновить скрипт установщика из ветки `spiderman`
- `13)` показать версию установщика и git-состояние
- `14)` открыть подменю управления cabinet

CLI-алиасы:

```bash
bot compose-edit
bot caddy-edit
```

## Типовая диагностика после установки

Проверить состояние Docker:

```bash
docker ps
docker compose version
```

Проверить, что репозиторий бота установлен:

```bash
ls -la /opt
```

Проверить логи бота:

```bash
docker logs -f remnawave_bot
```

Если бот поднят через compose в конкретной папке:

```bash
docker compose logs -f --tail=200 bot
```

## Обновление скриптов установщика

Если сам установщик уже стоит и нужно подтянуть свежие скрипты:

```bash
bot
```

Далее выбрать:

```text
12) Обновить скрипт
```

После обновления скриптов `bot` пересоздается автоматически.

## Замечания по текущему workflow

- Основной рабочий flow для бота и кабинета: `spiderman-merge`.
- Legacy override/rebuild flow сохраняется только как fallback и исторический reference.
- Для обычного обновления инсталлов не использовать legacy-сценарий без явной причины.

## Связанные документы

- `H:\Dev\BedolagaBot\Docs\MERGE_WORKFLOW.md`
- `H:\Dev\BedolagaBot\Docs\WORKFLOW.md`
- `H:\Dev\BedolagaBot\Docs\ЛОКАЛЬНАЯ РАЗРАБОТКА.md`

## Короткая памятка

Установка с нуля:

```bash
cd /root
curl -fsSL https://raw.githubusercontent.com/RamaPulya/install-spider-bot/spiderman/scripts/quick-install.sh -o quick-install.sh
chmod +x quick-install.sh
./quick-install.sh
```

Перезапуск после сбоя `apt`:

```bash
ps -ef | grep apt
kill <PID>
dpkg --configure -a
apt-get -f install
cd /root
./quick-install.sh
```
