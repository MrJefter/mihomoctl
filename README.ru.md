# mihomoctl

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)

Однострочный CLI для Mihomo на Linux. Вставьте ссылку на подписку, выберите ноду — и вы онлайн.

[English version](README.md)

## Что это?

mihomoctl устанавливает и управляет [Mihomo](https://wiki.metacubex.one/) (Clash-meta) на любой Linux-системе с systemd. Одна команда ставит всё — бинарник, сервис, таймер обновления. Вставляете ссылку на подписку, fzf выбирает ноду — и вы в сети.

Работает с любой Mihomo-совместимой подпиской (Remnawave, RoscomVPN или ваш провайдер).

```bash
curl -fsSL https://raw.githubusercontent.com/MrJefter/mihomoctl/master/install.sh | sudo bash
```

## Быстрый старт

**Установка или обновление (всё одной командой):**

```bash
curl -fsSL "https://raw.githubusercontent.com/MrJefter/mihomoctl/master/install.sh?v=$(date +%s)" | sudo bash
```

Установщик определяет пакетный менеджер, ставит Python + PyYAML, скачивает последний бинарник mihomo, копирует все файлы и спрашивает, скачать ли шаблон маршрутизации RoscomVPN.

**Установите подписку и запуститесь:**

```bash
sudo mihomoctl sub set <ваша-ссылка-на-подписку>
sudo mihomoctl sub update
sudo mihomoctl enable
```

**Удалить всё:**

```bash
curl -fsSL "https://raw.githubusercontent.com/MrJefter/mihomoctl/master/install.sh?v=$(date +%s)" | sudo bash -s -- --remove
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
- [См. также](#см-также)
- [Лицензия](#лицензия)

## Возможности

- **Однокомандная установка** — определяет apt/dnf/pacman, ставит всё
- **Управление подпиской** — установка URL, автообновление по таймеру, настройка цикла
- **Интерактивный выбор** — fzf-пикеры для нод/групп (нумерованный список без fzf)
- **DNS-редактор** — все поля DNS, переопределение nameservers/fallback, сброс к дефолтам подписки
- **Пинг нод** — проверка отдельных нод или всех нод в группе
- **Смена режима** — переключение между TUN (полный системный прокси) и proxy
- **Управление сервисом** — включение/выключение/перезапуск mihomo из CLI
- **Пersistentность** — DNS-переопределения сохраняются через обновления подписки

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

### Выбор ноды и группы

```bash
mihomoctl node group       # fzf: выбор группы → выбор ноды в ней
mihomoctl node pick        # fzf: быстрый выбор ноды в основной группе
mihomoctl node test        # пинг текущей ноды
mihomoctl node test --all  # пинг всех нод в основной группе
```

### Управление подпиской

```bash
mihomoctl sub set [url]    # установить URL подписки (промпт если без аргумента)
mihomoctl sub update       # скачать конфиг, перегенерировать, перезапустить
mihomoctl sub cycle        # изменить интервал автообновления (1ч–24ч или свой)
```

### DNS-настройки

```bash
mihomoctl dns set          # интерактивный DNS-редактор
```

Показывает все DNS-поля из подписки (enhanced-mode, nameservers, fallback, default-nameserver, proxy-server-nameserver и т.д.). Переопределите любое поле или сбросьте к дефолтам подписки. DNS-переопределения сохраняются через обновления подписки.

### Управление сервисом

```bash
mihomoctl enable           # systemctl enable --now mihomo.service
mihomoctl disable          # systemctl disable --now mihomo.service
mihomoctl restart          # systemctl restart mihomo.service
mihomoctl status           # сервис, подписка, маршрутизация, сеть
mihomoctl logs             # tail -f journalctl -u mihomo.service
```

### Смена режима

```bash
mihomoctl mode             # показать текущий режим
mihomoctl mode tun         # TUN (полный системный прокси)
mihomoctl mode proxy       # proxy (только для приложений)
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
2. `generate_config()` читает `base.yaml`, применяет runtime-настройки (режим, порты, DNS, TUN), пишет `config.yaml`
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

## См. также

[vika2603/mihomoctl](https://github.com/vika2603/mihomoctl) — Go-based CLI для продвинутого управления через API: мониторинг соединений в реальном времени, отладка DNS, проверка здоровья proxy-providers, инспекция правил и JSON-вывод для скриптов. Используйте оба: этот проект для настройки, vika2603 для отладки.

## Лицензия

[GPL-3.0](LICENSE)
