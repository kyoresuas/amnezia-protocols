# Amnezia Protocols

[![Bash](https://img.shields.io/badge/Bash-5.x-4EAA25?logo=gnubash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Docker](https://img.shields.io/badge/Docker-required-2496ED?logo=docker&logoColor=white)](https://docs.docker.com/engine/install/)
[![CI](https://github.com/kyoresuas/amnezia-protocols/actions/workflows/ci.yml/badge.svg)](https://github.com/kyoresuas/amnezia-protocols/actions/workflows/ci.yml)
[![License](https://img.shields.io/badge/License-MIT-2ea44f.svg)](LICENSE)

[English](README.md) · **Русский**

**Установщики протоколов Amnezia из командной строки.** Разверните AmneziaWG 3.1, старый AmneziaWG или Xray с REALITY на любом Linux-сервере с Docker — без десктопного клиента Amnezia, без SSH из графического интерфейса и без ручной генерации ключей.

Контейнеры, пути и названия параметров совпадают с тем, что создаёт клиент Amnezia, поэтому сервер остаётся полностью совместимым с приложением Amnezia и с [Amnezia API](https://github.com/kyoresuas/amnezia-api).

[Быстрый старт](#быстрый-старт) · [Протоколы](#поддерживаемые-протоколы) · [Опции](#опции) · [Безопасность](#безопасность)

## Зачем это нужно

Клиент Amnezia ставит протоколы по SSH из десктопного интерфейса. Для серверной работы это не подходит: скрипты подготовки, CI, golden image или парк серверов, к которым есть только SSH.

| Возможность | Что даёт |
| --- | --- |
| Без десктопного клиента | Одна команда на сервере вместо графического мастера, который ходит по SSH |
| Совместимая раскладка | Те же имена контейнеров, интерфейсов и пути к файлам, поэтому приложение Amnezia и Amnezia API продолжают работать |
| Актуальные версии протоколов | AmneziaWG 3.1 с защитой заголовков, рандомизацией таймингов и случайными трейлерами |
| Уникальная обфускация на каждом сервере | Размеры мусора и ключи генерируются при установке, а не зашиты в скрипт |
| Пригодно для автоматизации | Каждый параметр доступен как аргумент или переменная окружения |
| Повторяемость | `--force` пересоздаёт контейнер с нуля, `--name` ставит второй экземпляр рядом |

## Как это устроено

```text
    SSH · подготовка · CI
             │
    ./install.sh <протокол>
             │
    Docker-контейнеры на сервере
 amnezia-awg2 · amnezia-awg · amnezia-xray
             │
 Приложение Amnezia · Amnezia API · ваша автоматизация
```

Если контейнеры уже поставлены клиентом Amnezia, эти скрипты не нужны — они создают ровно такую же раскладку. Они пригодятся там, где клиент недоступен или установку нужно автоматизировать.

## Поддерживаемые протоколы

| Протокол | Команда | Контейнер | Конфиг сервера |
| --- | --- | --- | --- |
| AmneziaWG 3.1 | `./install.sh awg` | `amnezia-awg2` | `/opt/amnezia/awg/awg0.conf` |
| AmneziaWG 1.5 | `./install.sh awg-legacy` | `amnezia-awg` | `/opt/amnezia/awg/wg0.conf` |
| Xray (VLESS + REALITY) | `./install.sh xray` | `amnezia-xray` | `/opt/amnezia/xray/server.json` |

AmneziaWG 3.1 живёт в контейнере `amnezia-awg2` — том же, что клиент Amnezia использует для 2.0. Версию протокола задаёт набор параметров в `awg0.conf`, а не имя контейнера.

## Требования

- Linux-сервер с Docker и доступом к Docker Hub.
- Права root или `sudo`.
- Свободный UDP-порт для AmneziaWG или свободный TCP-порт для Xray.
- Проверено на Debian и Ubuntu, подойдёт любой дистрибутив с Docker.

## Быстрый старт

Склонируйте репозиторий на сервере и запустите установщик:

```bash
git clone https://github.com/kyoresuas/amnezia-protocols.git
cd amnezia-protocols
./install.sh
```

Без аргументов установщик спросит, какой протокол разворачивать. Передайте протокол сразу, чтобы пропустить вопрос:

```bash
./install.sh awg --port 55424 --subnet 10.8.1.0
```

Установщик:

1. Проверяет, что Docker установлен и запущен.
2. Создаёт Docker-сеть `amnezia-dns-net`, если её нет.
3. Собирает образ протокола из вложенного `Dockerfile`.
4. Запускает контейнер с нужными правами и опубликованным портом.
5. Генерирует ключи сервера и конфиг внутри контейнера.
6. Устанавливает `start.sh`, перезапускает контейнер и печатает публичный ключ.

> [!WARNING]
> `--force` пересоздаёт контейнер и генерирует **новые ключи сервера**. Все ранее выданные клиентские конфиги перестанут работать. Не запускайте его на сервере с живыми пользователями, если это не то, что вам нужно.

## Опции

Общие для всех протоколов:

| Аргумент | Переменная окружения | Описание |
| --- | --- | --- |
| `--name` | `CONTAINER_NAME` | Имя контейнера, по умолчанию — имя Amnezia для этого протокола |
| `--force` | — | Пересоздать существующий контейнер и перегенерировать ключи |

### AmneziaWG 3.1 и 1.5

| Аргумент | Переменная окружения | По умолчанию | Описание |
| --- | --- | --- | --- |
| `--port` | `AWG_SERVER_PORT` | `55424` | UDP-порт, публикуемый на хосте |
| `--subnet` | `AWG_SUBNET_IP` | `10.8.0.0` | Адрес VPN-подсети для интерфейса |
| `--cidr` | `WIREGUARD_SUBNET_CIDR` | `24` | Длина префикса VPN-подсети |

### Xray

| Аргумент | Переменная окружения | По умолчанию | Описание |
| --- | --- | --- | --- |
| `--port` | `XRAY_SERVER_PORT` | `443` | TCP-порт, публикуемый на хосте |
| `--site` | `XRAY_SITE_NAME` | `www.googletagmanager.com` | SNI и сайт назначения для REALITY |

## Параметры обфускации

Все параметры AmneziaWG генерируются при установке, любой можно переопределить переменной окружения. Значения повторяют установщик клиента Amnezia.

| Параметр | Переменная | По умолчанию | Версия |
| --- | --- | --- | --- |
| `Jc` | `JUNK_PACKET_COUNT` | случайно `4..6` | все |
| `Jmin` / `Jmax` | `JUNK_PACKET_MIN_SIZE` / `JUNK_PACKET_MAX_SIZE` | `10` / `50` | все |
| `S1` / `S2` | `INIT_PACKET_JUNK_SIZE` / `RESPONSE_PACKET_JUNK_SIZE` | случайно `12..149` | все |
| `S3` / `S4` | `COOKIE_REPLY_PACKET_JUNK_SIZE` / `TRANSPORT_PACKET_JUNK_SIZE` | случайно `12..63` / `12` | 2.0+ |
| `H1`–`H4` | `INIT_PACKET_MAGIC_HEADER` … `TRANSPORT_PACKET_MAGIC_HEADER` | `1`–`4` | все |
| `I1`–`I5` | `SPECIAL_JUNK_1` … `SPECIAL_JUNK_5` | пусто | 1.5+ |
| `HeaderProtectionKey` | `HEADER_PROTECTION_KEY` | генерируется | 3.1 |
| `ContentPaddingAddition` | `CONTENT_PADDING_ADDITION` | `10-100` | 3.1 |
| `RekeyAfterTime` | `REKEY_AFTER_TIME` | `100-120` | 3.1 |
| `RekeyTimeout` | `REKEY_TIMEOUT` | `3-7` | 3.1 |
| `RejectAfterTime` | `REJECT_AFTER_TIME` | `150-180` | 3.1 |
| `KeepaliveTimeout` | `KEEPALIVE_TIMEOUT` | `5-15` | 3.1 |
| `MaxHandshakeAttempts` | `MAX_HANDSHAKE_ATTEMPTS` | `15-20` | 3.1 |
| `RandomTrailers` | `RANDOM_TRAILERS` | `on` | 3.1 |
| `DisableCookies` | `DISABLE_COOKIES` | `on` | 3.1 |

Размеры мусора подбираются так, чтобы обфусцированные пакеты не совпадали по длине, — то же ограничение проверяет клиент Amnezia. Magic-заголовки остаются последовательными, потому что в AmneziaWG 3.1 заголовки пакетов шифруются ключом `HeaderProtectionKey`.

Пример с фиксированными значениями:

```bash
JUNK_PACKET_COUNT=5 CONTENT_PADDING_ADDITION=20-120 ./install.sh awg --port 51820
```

## Что создаётся

| Путь внутри контейнера | Содержимое |
| --- | --- |
| `/opt/amnezia/awg/awg0.conf` | Конфиг сервера AmneziaWG 3.1 |
| `/opt/amnezia/awg/wg0.conf` | Конфиг сервера AmneziaWG 1.5 |
| `/opt/amnezia/awg/wireguard_server_private_key.key` | Приватный ключ сервера |
| `/opt/amnezia/awg/wireguard_server_public_key.key` | Публичный ключ сервера |
| `/opt/amnezia/awg/wireguard_psk.key` | Preshared-ключ, выдаваемый клиентам |
| `/opt/amnezia/xray/server.json` | Конфиг сервера Xray |
| `/opt/amnezia/xray/xray_private.key`, `xray_public.key` | Пара ключей REALITY |
| `/opt/amnezia/xray/xray_short_id.key`, `xray_uuid.key` | Short ID REALITY и UUID первого клиента |

Сохраните эти файлы перед пересозданием контейнера — другой копии идентичности сервера нет.

## Проверка результата

```bash
docker exec amnezia-awg2 awg show awg0
docker exec amnezia-awg2 cat /opt/amnezia/awg/awg0.conf
docker exec amnezia-xray cat /opt/amnezia/xray/server.json
```

Живой интерфейс AmneziaWG 3.1 показывает `header protection key`, `content padding addition`, `random trailers: on` и `disable cookies: on`.

## Управление клиентами

Эти скрипты ставят и настраивают серверную часть. Чтобы выдавать, смотреть, отключать и удалять клиентов по HTTP, поставьте рядом [Amnezia API](https://github.com/kyoresuas/amnezia-api):

```bash
git clone https://github.com/kyoresuas/amnezia-api.git
cd amnezia-api
bash ./scripts/setup.sh
```

API обнаружит запущенные контейнеры, отдаст `amnezia-awg2` как протокол `amneziawg3` и вернёт готовые к импорту конфиги `vpn://`. Либо добавляйте пиров в конфиг сервера вручную и перечитывайте интерфейс:

```bash
docker exec amnezia-awg2 sh -lc 'awg syncconf awg0 <(awg-quick strip /opt/amnezia/awg/awg0.conf)'
```

## Удаление протокола

```bash
docker rm -f amnezia-awg2
docker rmi amnezia-awg2
```

## Безопасность

Скрипты создают привилегированные контейнеры, через которые идёт VPN-трафик и в которых лежат ключи сервера.

- Контейнеры запускаются с `--privileged`, `NET_ADMIN` и `SYS_MODULE` — ставьте их только на подконтрольных хостах.
- Ключи сервера лежат внутри контейнера. Копируйте их для резервной копии и храните как секреты.
- Публикуйте только нужные порты, остальное закрывайте файрволом хоста или группой безопасности.
- Не публикуйте приватные ключи, preshared-ключи, конфиги `vpn://` и QR-коды в issue и на скриншотах.
- Периодически пересобирайте образы: `--pull` подтягивает актуальный базовый образ Amnezia с исправлениями протокола.
- Обфускация не заменяет аутентификацию. Держите клиентские ключи в секрете и меняйте всё, что могло утечь.

О предполагаемых уязвимостях сообщайте приватно по инструкции из [SECURITY.md](SECURITY.md). Не создавайте публичный issue для отчёта о безопасности.

## Разработка

```bash
shellcheck install.sh protocols/*/*.sh
find . -name '*.sh' -exec bash -n {} \;
```

CI выполняет те же проверки и ставит AmneziaWG 3.1 на чистом раннере. Полный процесс и правила совместимости с клиентом Amnezia — в [CONTRIBUTING.md](CONTRIBUTING.md).

## Экосистема

- [amnezia-api](https://github.com/kyoresuas/amnezia-api) — REST API для управления клиентами на серверах, созданных этими скриптами.
- [amnezia-panel](https://github.com/slowy19/amnezia-panel) — веб-панель администрирования поверх Amnezia API.

## Поддержать проект

Если Amnezia Protocols вам полезен, можно поддержать разработку:

- **Карта МИР:** `2200700644781816`
- **TON:** `kyoresuas.ton`
- **Адрес кошелька TON:** `UQATzyMcVoZudjaA5Rc9w5TV_lIqxh9DPk0gSnjkLVvwEVqz`
- **USDT в сети TRON (TRC-20):** `TJSLjDo4yRgHr9JqqEcrkbC51bP9DCiBC7`

Проверяйте сеть перед переводом криптовалюты.

## Статус проекта и поддержка

Баг-репорты и предложения — в [GitHub Issues](https://github.com/kyoresuas/amnezia-protocols/issues).

- Telegram: [@stercuss](https://t.me/stercuss)
- Почта: [hey@kyoresuas.com](mailto:hey@kyoresuas.com)

## Отказ от ответственности

Это независимый проект сообщества. Он не аффилирован с проектом Amnezia, не спонсируется и не одобрен им официально. Dockerfile и раскладка контейнеров повторяют серверные скрипты клиента Amnezia.

## Лицензия

[MIT](LICENSE)
