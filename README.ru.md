# mihomoctl

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)

CLI-утилита для управления подписками Mihomo (Clash.Meta) на Linux. Без Electron, без лишнего — только терминал и ваш безмышечный рабочий процесс.

[English version](README.md)

## Что это?

mihomoctl позволяет управлять демоном Mihomo прокси полностью из командной строки. Переключайте ноды, меняйте профили маршрутизации, переключайтесь между TUN и proxy-режимом, управляйте подписками — всё без GUI.

Создано для Linux-систем с systemd (Ubuntu, Fedora, Arch, Debian и т.д.).

## Быстрый старт

**Установка или обновление:**

```bash
curl -fsSL "https://raw.githubusercontent.com/MrJefter/mihomoctl/master/install.sh?v=$(date +%s)" | sudo bash
```

**Удаление:**

```bash
curl -fsSL "https://raw.githubusercontent.com/MrJefter/mihomoctl/master/install.sh?v=$(date +%s)" | sudo bash -s -- --remove
```

**Ручная установка (из клонирования):**

```bash
git clone https://github.com/MrJefter/mihomoctl.git
cd mihomoctl
sudo make install
sudo ./install.sh
```

## Содержание

- [Возможности](#возможности)
- [Требования](#требования)
- [Установка](#установка)
- [Шаблон маршрутизации](#шаблон-маршрутизации)
- [Команды](#команды)
- [Конфигурация](#конфигурация)
- [Systemd-юниты](#systemd-юниты)
- [Структура файлов](#структура-файлов-после-установки)
- [Обновление](#обновление)
- [Удаление](#удаление)
- [Решение проблем](#решение-проблем)
- [Лицензия](#лицензия)

## Возможности

- **Управление подпиской** — установка URL, автообновление по таймеру
- **Интерактивный выбор** — fzf-пикеры для нод/групп/профилей (нумерованный список без fzf)
- **Профили маршрутизации** — переключение группы для YouTube, Discord, игр и т.д.
- **Смена режима** — переключение между TUN (полный системный прокси) и proxy-режимом
- **Управление сервисом** — включение/выключение mihomo из CLI
- **Универсальность** — работает на любом Linux с systemd (apt/dnf/pacman определяется автоматически)
- **Автоустановка** — скачивает бинарник mihomo, ставит зависимости, без ручных шагов

## Требования

- Linux с systemd
- Python 3
- PyYAML (`python3-yaml`)
- fzf (опционально, для интерактивных пикеров)

## Установка

### Полная установка (рекомендуется)

```bash
git clone https://github.com/MrJefter/mihomoctl.git
cd mihomoctl
sudo make install
sudo ./install.sh
```

Установщик:
1. Определит пакетный менеджер и поставит `python3` + `python3-yaml`
2. Скачает последний бинарник mihomo
3. Скопирует mihomoctl, systemd-юниты и вспомогательные скрипты
4. Спросит, скачать ли шаблон маршрутизации RoscomVPN

### Ручная установка

Если предпочитаете ставить зависимости вручную:

```bash
sudo make install    # только копирует файлы
sudo mihomoctl sub set
sudo mihomoctl sub update
sudo mihomoctl enable
```

## Шаблон маршрутизации

При установке будет вопрос:

```
Download RoscomVPN routing template? [Y/n]
```

Это скачает готовый конфиг из [hydraponique/roscomvpn-routing](https://github.com/hydraponique/roscomvpn-routing) с:

- Преднастроенными группами прокси (VPN, YouTube, Discord, Игры и т.д.)
- 40+ рулсетами для маршрутизации РФ/РБ
- Провайдерами правил для блокировки рекламы, шпионского ПО Windows, торрентов
- Прямым доступом для RU/BY-сервисов

Если откажетесь, нужно будет вставить свою ссылку на подписку:

```bash
sudo mihomoctl sub set <ваша-ссылка>
sudo mihomoctl sub update
```

## Команды

### Выбор группы и ноды

```bash
mihomoctl group pick       # fzf: выбрать основную группу прокси
mihomoctl group profile    # fzf: выбрать профиль маршрутизации (YouTube, Discord, Игры...)
mihomoctl node pick        # fzf: выбрать ноду в текущей группе
```

**Рабочий процесс:** `group pick` задаёт группу → `node pick` выбирает сервер в ней → `group profile` настраивает маршрутизацию для конкретных сервисов.

### Управление сервисом

```bash
mihomoctl enable           # systemctl enable --now mihomo.service
mihomoctl disable          # systemctl disable --now mihomo.service
mihomoctl restart          # systemctl restart mihomo.service
mihomoctl status           # показать режим, группу, ноду, статус API и сервиса
mihomoctl logs             # tail -f journalctl -u mihomo.service
```

### Управление подпиской

```bash
mihomoctl sub set [url]    # установить URL подписки (промпт если без аргумента)
mihomoctl sub update       # скачать конфиг по URL, перегенерировать, перезапустить
```

### Смена режима

```bash
mihomoctl mode             # показать текущий режим
mihomoctl mode tun         # переключить в TUN (полный системный прокси)
mihomoctl mode proxy       # переключить в proxy (только для приложений)
```

## Конфигурация

### Как это работает

mihomoctl использует двухфайловую схему:

```
base.yaml → (generate_config) → config.yaml
```

- **`base.yaml`** — шаблон подписки или конфиг RoscomVPN. Скачивается через `sub update` или при установке. **Не редактировать напрямую.**
- **`config.yaml`** — генерируемый конфиг для запуска. Модифицируется `generate_config()` на основе режима (TUN/proxy). Также **не редактировать напрямую.**

Процесс:
1. `sub update` скачивает подписку в `base.yaml`
2. `generate_config()` читает `base.yaml`, применяет_RUNTIME-настройки (режим, порты, DNS, TUN), пишет `config.yaml`
3. Mihomo читает `config.yaml` при старте

### Своя подписка

Если у вас есть подписка Mihomo/Clash (от любого провайдера):

```bash
sudo mihomoctl sub set https://ваша-ссылка-на-подписку
sudo mihomoctl sub update
sudo mihomoctl enable
```

### Без RoscomVPN

Откажитесь от шаблона RoscomVPN при установке, затем вставьте свою подписку. Инструмент работает с любой Mihomo-совместимой подпиской.

## Systemd-юниты

| Юнит | Назначение |
|---|---|
| `mihomo.service` | Демон Mihomo |
| `mihomo-update.service` | Разовое обновление подписки (по таймеру) |
| `mihomo-update.timer` | Периодическое обновление (каждые 6 часов) |

Включение после установки:

```bash
sudo mihomoctl enable
sudo systemctl enable --now mihomo-update.timer  # опционально, автообновление подписки
```

## Структура файлов после установки

```
/usr/local/bin/mihomoctl              # основной CLI
/usr/local/bin/mihomo                 # бинарник mihomo (скачивается install.sh)
/usr/local/sbin/mihomo-update-config  # обёртка для sub update
/etc/mihomo/base.yaml                 # шаблон подписки (не редактировать)
/etc/mihomo/config.yaml               # генерируемый конфиг (не редактировать)
/etc/systemd/system/mihomo.service
/etc/systemd/system/mihomo-update.service
/etc/systemd/system/mihomo-update.timer
/var/lib/mihomoctl/state.json         # сохранённый выбор группы/ноды/режима
```

## Обновление

```bash
curl -fsSL "https://raw.githubusercontent.com/MrJefter/mihomoctl/master/install.sh?v=$(date +%s)" | sudo bash
```

Или вручную:

```bash
cd ~/.local/share/mihomoctl
git pull
sudo make install
sudo mihomoctl restart
```

Тянет последний код и переустанавливает файлы. Конфиг и состояние сохраняются.

## Удаление

```bash
curl -fsSL https://raw.githubusercontent.com/MrJefter/mihomoctl/master/install.sh | sudo bash -s -- --remove
```

Или вручную:

```bash
sudo make uninstall
sudo rm -rf /etc/mihomo /var/lib/mihomoctl ~/.local/share/mihomoctl
```

## Решение проблем

### Mihomo не запускается

Проверьте бинарник и валидность конфига:

```bash
/usr/local/bin/mihomo -t -d /etc/mihomo    # тест конфига
sudo mihomoctl logs                          # проверить логи
```

### API не отвечает

Для большинства команд Mihomo должен быть запущен. Проверьте:

```bash
sudo mihomoctl status
systemctl status mihomo.service
```

Если API показывает "down", перезапустите mihomo:

```bash
sudo mihomoctl restart
```

### fzf не найден

Установите fzf для интерактивных пикеров:

```bash
# Debian/Ubuntu
sudo apt install fzf

# Fedora
sudo dnf install fzf

# Arch
sudo pacman -S fzf
```

Без fzf команды используют нумерованные списки.

### Permission denied

Большинство команд требуют root. Используйте `sudo`:

```bash
sudo mihomoctl enable
sudo mihomoctl sub update
```

## Лицензия

[GPL-3.0](LICENSE)
