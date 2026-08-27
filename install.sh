#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROTOCOLS_DIR="$SCRIPT_DIR/protocols"

supports_color() { [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; }
if supports_color; then
  R=$'\033[0m' BOLD=$'\033[1m' DIM=$'\033[2m'
  CYAN=$'\033[36m' RED=$'\033[31m'
else
  R="" BOLD="" DIM="" CYAN="" RED=""
fi

step() { printf "\n%b\n" "${BOLD}${CYAN}▶ $*${R}"; }
die()  { printf "%b\n" "${RED}✗ ОШИБКА:${R} $*" >&2; exit 1; }

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
