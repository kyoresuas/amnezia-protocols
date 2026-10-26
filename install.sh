#!/usr/bin/env bash

set -euo pipefail

REPO_SLUG="kyoresuas/amnezia-protocols"
REPO_REF="${AMNEZIA_PROTOCOLS_REF:-main}"

# При запуске через curl | bash файла на диске нет, и каталога protocols рядом тоже
SCRIPT_DIR=""
if [ -n "${BASH_SOURCE[0]:-}" ]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi
PROTOCOLS_DIR="$SCRIPT_DIR/protocols"
BOOTSTRAP_DIR=""

supports_color() { [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; }
if supports_color; then
  R=$'\033[0m' BOLD=$'\033[1m' DIM=$'\033[2m'
  CYAN=$'\033[36m' RED=$'\033[31m'
else
  R="" BOLD="" DIM="" CYAN="" RED=""
fi

step() { printf "\n%b\n" "${BOLD}${CYAN}▶ $*${R}"; }
die()  { printf "%b\n" "${RED}✗ ОШИБКА:${R} $*" >&2; exit 1; }

# Скачивает архив репозитория и запускает установщик из него, нужно для curl | bash
bootstrap() {
  command -v curl &>/dev/null || die "Для запуска через curl нужен curl."
  command -v tar &>/dev/null  || die "Для запуска через curl нужен tar."

  local stdin_source=/dev/null
  BOOTSTRAP_DIR="$(mktemp -d)"
  trap 'rm -rf "$BOOTSTRAP_DIR"' EXIT

  step "Загрузка $REPO_SLUG ($REPO_REF)"
  curl -fsSL "https://github.com/$REPO_SLUG/archive/$REPO_REF.tar.gz" \
    | tar -xz -C "$BOOTSTRAP_DIR" --strip-components=1 \
    || die "Не удалось скачать архив. Проверьте доступ к github.com и значение AMNEZIA_PROTOCOLS_REF."

  # Скрипт читается из stdin, поэтому дочернему установщику отдаём терминал или пустой ввод,
  # иначе docker exec -i съест остаток скрипта
  if (: </dev/tty) 2>/dev/null; then
    stdin_source=/dev/tty
  fi

  bash "$BOOTSTRAP_DIR/install.sh" "$@" <"$stdin_source"
}

if [ -z "$SCRIPT_DIR" ] || [ ! -d "$PROTOCOLS_DIR" ]; then
  bootstrap "$@"
  exit 0
fi

# Описания протоколов для меню и справки
protocol_title() {
  case "$1" in
    awg)        echo "AmneziaWG 3.1 (контейнер amnezia-awg2)" ;;
    awg-legacy) echo "AmneziaWG 1.5 (контейнер amnezia-awg)" ;;
    xray)       echo "Xray VLESS + REALITY (контейнер amnezia-xray)" ;;
    *)          echo "$1" ;;
  esac
}

# Список доступных протоколов
list_protocols() {
  find "$PROTOCOLS_DIR" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort
}

usage() {
  printf "%b\n" "${BOLD}Установка протоколов Amnezia${R}"
  printf "\n%b\n" "Использование: ./install.sh <протокол> [аргументы]"
  printf "\n%b\n" "${DIM}Протоколы:${R}"

  while read -r name; do
    printf "  %b\n" "${BOLD}${name}${R} — $(protocol_title "$name")"
  done < <(list_protocols)

  printf "\n%b\n" "${DIM}Примеры:${R}"
  printf "%b\n" "  ./install.sh awg --port 55424 --subnet 10.8.1.0"
  printf "%b\n" "  ./install.sh xray --port 443 --site www.googletagmanager.com"
  printf "%b\n" "  ./install.sh awg --force"
  printf "\n%b\n" "${DIM}Аргументы после имени протокола передаются его установщику.${R}"
}

# Интерактивный выбор, если протокол не указан
select_protocol() {
  local names=() name index

  while read -r name; do
    names+=("$name")
  done < <(list_protocols)

  printf "%b\n" "${BOLD}Выберите протокол:${R}" >&2

  for index in "${!names[@]}"; do
    printf "  %b\n" "${BOLD}$((index + 1)))${R} $(protocol_title "${names[index]}")" >&2
  done

  printf "\n%b" "Номер [1-${#names[@]}]: " >&2
  read -r index

  [[ "$index" =~ ^[0-9]+$ ]] || die "Ожидается номер протокола."

  if [ "$index" -lt 1 ] || [ "$index" -gt "${#names[@]}" ]; then
    die "Нет протокола с номером $index."
  fi

  echo "${names[$((index - 1))]}"
}

PROTOCOL="${1:-}"

if [ -n "$PROTOCOL" ]; then
  shift
else
  if [ ! -t 0 ]; then
    usage
    exit 1
  fi

  PROTOCOL="$(select_protocol)"
fi

case "$PROTOCOL" in
  -h|--help|help) usage; exit 0 ;;
esac

INSTALLER="$PROTOCOLS_DIR/$PROTOCOL/install.sh"
[ -f "$INSTALLER" ] || die "Неизвестный протокол '$PROTOCOL'. Доступные: $(list_protocols | tr '\n' ' ')"

step "$(protocol_title "$PROTOCOL")"
bash "$INSTALLER" "$@"
