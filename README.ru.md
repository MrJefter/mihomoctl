# mihomoctl

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)

Консольная утилита для установки и управления [Mihomo](https://wiki.metacubex.one/) (Clash-meta) в Linux. Вставьте ссылку на подписку, выберите маршруты и ноды — и вы в сети.

[English version](README.md)

## Что это?

mihomoctl автоматизирует установку и настройку Mihomo в Linux с systemd. Одной командой ставится всё: бинарный файл, сервисы, автодополнения для терминала и таймер автообновления подписки.

Подходит для любых подписок формата Mihomo / Clash (Remnawave, RoscomVPN или собственные конфигурации).

```bash
curl -fsSL https://cdn.jsdelivr.net/gh/Jefter5549/mihomoctl@master/install.sh | sudo bash
```

## Быстрый старт

**Установка или обновление в одну команду:**

```bash
curl -fsSL https://cdn.jsdelivr.net/gh/Jefter5549/mihomoctl@master/install.sh | sudo bash
```

*(Альтернативная ссылка через raw GitHub)*:
```bash
curl -fsSL "https://raw.githubusercontent.com/Jefter5549/mihomoctl/master/install.sh?v=$(date +%s)" | sudo bash
```

Установщик определяет пакетный менеджер (apt в Debian/Ubuntu, dnf в Fedora, pacman в Arch, zypper, apk), ставит зависимости (`python3`, `python3-yaml`, `curl`, `gzip`), скачивает свежий бинарник mihomo, копирует скрипты, автодополнения и systemd-юниты, а также предлагает скачать готовый шаблон маршрутизации RoscomVPN.

**Настройка подписки и запуск:**

```bash
sudo mihomoctl sub set <ваша-ссылка-на-подписку>
sudo mihomoctl sub update
sudo mihomoctl enable
```

**Полное удаление:**

```bash
curl -fsSL https://cdn.jsdelivr.net/gh/Jefter5549/mihomoctl@master/install.sh | sudo bash -s -- --remove
```

## Содержание

- [Возможности](#возможности)
- [Требования](#требования)
- [Установка](#установка)
- [Шаблон маршрутизации](#шаблон-маршрутизации)
- [Команды](#команды)
- [Конфигурация](#конфигурация)
- [Systemd сервисы](#systemd-сервисы)
- [Файловая структура](#файловая-структура-после-установки)
- [Обновление](#обновление)
- [Удаление](#удаление)
- [Ссылки](#ссылки)
- [Лицензия](#лицензия)

## Возможности

- **Установка в одну команду** — поддержка apt, dnf, pacman, zypper, apk.
- **Управление подпиской** — загрузка, ручное и автоматическое обновление через systemd timer.
- **Интерактивный выбор маршрутов и нод** — удобный выбор через fzf (с текстовым меню, если fzf не установлен).
- **Контроль групп политик (policy groups)** — просмотр, выбор прокси, фиксация (pin) серверов для URLTest/Fallback.
- **Тестирование задержки (ping)** — как для отдельных прокси, так и для всех нод группы.
- **Переключение режима перехвата трафика** — TUN (весь трафик системы), proxy (только mixed-port) или inherit (наследовать из подписки).
- **Динамические правила** — просмотр, быстрое добавление пользовательских правил маршрутизации на лету.
- **Автодополнение в шелле** — готовые автодополнения для bash, zsh и fish.

## Требования

- Linux с systemd (Debian 12/13, Ubuntu, Fedora, Arch Linux и др.)
- Python >= 3.10
- PyYAML (`python3-yaml`)
- fzf (опционально, для интерактивного меню)

## Установка

### Полная установка (рекомендуется)

```bash
git clone https://github.com/Jefter5549/mihomoctl.git
cd mihomoctl
sudo make install
sudo ./install.sh
```

### Ручная установка

```bash
sudo make install    # копирует бинарники, автодополнения и сервисы
sudo mihomoctl sub set
sudo mihomoctl sub update
sudo mihomoctl enable
```

## Шаблон маршрутизации

Во время установки будет предложено:

```
Download RoscomVPN routing template? [Y/n]
```

Скачивается оптимизированный шаблон из [hydraponique/roscomvpn-routing](https://github.com/hydraponique/roscomvpn-routing):

- Готовые группы прокси (VPN, YouTube, Discord, Games и др.)
- 40+ наборов правил для РФ/РБ маршрутизации
- Блокировка рекламы, телеметрии и трекеров
- Прямой доступ к локальным и государственным сервисам

## Команды

### Статус и управление сервисом

```bash
mihomoctl status           # статус демона, подписки, режима и соединений
sudo mihomoctl enable      # включить и запустить службу mihomo
sudo mihomoctl disable     # остановить и отключить службу
sudo mihomoctl restart     # перезапустить службу
mihomoctl logs             # просмотр логов mihomo (journalctl)
```

### Маршруты и группы

```bash
mihomoctl group list [--all]               # список групп политик
mihomoctl group show <group>               # детальная информация о группе
mihomoctl group select <group> <member>    # выбрать сервер в группе Selector
mihomoctl group pin <group> <member>       # зафиксировать сервер для URLTest/Fallback
mihomoctl group unpin <group>              # вернуть автовыбор по задержке
mihomoctl route status [roots...]          # текущий активный маршрут
mihomoctl route pick [root]                # интерактивный выбор вложенного маршрута (fzf)
```

### Тестирование прокси

```bash
mihomoctl proxy test <target>              # тест задержки конкретного прокси/узла
mihomoctl proxy test <group> --all         # тест всех узлов в группе
```

### Режим перехвата трафика

```bash
mihomoctl mode                             # текущий режим
sudo mihomoctl mode tun                    # включить TUN (полный перехват трафика ОС)
sudo mihomoctl mode proxy                  # режим proxy (только mixed-port)
sudo mihomoctl mode inherit                # наследовать настройку TUN из подписки
```

### Управление подпиской

```bash
sudo mihomoctl sub set [url]               # задать ссылку на подписку
sudo mihomoctl sub update                  # скачать подписку, сгенерировать конфиг и применить
sudo mihomoctl sub cycle                   # настроить интервал таймера автообновления
```

### Динамические правила

```bash
mihomoctl rules list                       # список активных правил
sudo mihomoctl rules add <rule...>         # добавить правило (например, 'DOMAIN-SUFFIX,example.com,DIRECT')
sudo mihomoctl rules clear                 # очистить добавленные вручную правила
```

## Systemd сервисы

| Юнит | Назначение |
|---|---|
| `mihomo.service` | Основной демон Mihomo |
| `mihomo-update.service` | Обновление конфигурации подписки |
| `mihomo-update.timer` | Таймер периодического обновления подписки |

## Файловая структура после установки

```
/usr/local/bin/mihomoctl                            # исполняемый файл CLI
/usr/local/bin/mihomo                               # бинарник mihomo core
/usr/local/sbin/mihomo-update-config                # скрипт вызова обновления
/etc/bash_completion.d/mihomoctl                    # автодополнение bash
/usr/share/zsh/site-functions/_mihomoctl            # автодополнение zsh
/usr/share/fish/vendor_completions.d/mihomoctl.fish # автодополнение fish
/etc/mihomo/base.yaml                               # шаблон / подписка
/etc/mihomo/config.yaml                             # сгенерированный рабочий конфиг
/etc/systemd/system/mihomo.service
/etc/systemd/system/mihomo-update.service
/etc/systemd/system/mihomo-update.timer
/var/lib/mihomoctl/state.json                       # сохраненные настройки и оверрайды
```

## Обновление

```bash
curl -fsSL "https://raw.githubusercontent.com/Jefter5549/mihomoctl/master/install.sh?v=$(date +%s)" | sudo bash
```

## Удаление

```bash
curl -fsSL "https://raw.githubusercontent.com/Jefter5549/mihomoctl/master/install.sh?v=$(date +%s)" | sudo bash -s -- --remove
```

## Ссылки

- [MetaCubeX/mihomo](https://github.com/MetaCubeX/mihomo) — ядро Mihomo
- [hydraponique/roscomvpn-routing](https://github.com/hydraponique/roscomvpn-routing) — правила и шаблоны маршрутизации

## Лицензия

GPL-3.0
