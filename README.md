# Amnezia Protocols

[![Bash](https://img.shields.io/badge/Bash-5.x-4EAA25?logo=gnubash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Docker](https://img.shields.io/badge/Docker-required-2496ED?logo=docker&logoColor=white)](https://docs.docker.com/engine/install/)
[![CI](https://github.com/kyoresuas/amnezia-protocols/actions/workflows/ci.yml/badge.svg)](https://github.com/kyoresuas/amnezia-protocols/actions/workflows/ci.yml)
[![License](https://img.shields.io/badge/License-MIT-2ea44f.svg)](LICENSE)

**English** · [Русский](README_RU.md)

**Install AmneziaWG 3.1 or Xray REALITY on your own server with one command.** The installers run in Docker, need no desktop client, and create the same containers the Amnezia app does, so the server keeps working with the app and with [Amnezia API](https://github.com/kyoresuas/amnezia-api).

```bash
curl -fsSL https://raw.githubusercontent.com/kyoresuas/amnezia-protocols/main/install.sh | sudo bash -s -- awg
```

Swap `awg` for `awg-legacy` (AmneziaWG 1.5) or `xray` (VLESS + REALITY), or leave it out to pick from a menu. Logged in as root? Drop `sudo`.

[Quick start](#quick-start) · [Protocols](#supported-protocols) · [Options](#options) · [Security](#security)

## Why Amnezia Protocols?

The Amnezia client installs protocols over SSH from a desktop GUI. That does not fit server-side work: provisioning scripts, CI pipelines, golden images, or a fleet of servers you only reach over SSH.

| Capability | What it gives you |
| --- | --- |
| No desktop client | One command on the server instead of a GUI wizard driving SSH |
| Client-compatible layout | Same container names, interfaces, and file paths, so the Amnezia app and Amnezia API keep working |
| Current protocol versions | AmneziaWG 3.1 with header protection, timing randomization, and random trailers |
| Unique obfuscation per server | Junk sizes and keys are generated on every install instead of being hardcoded |
| Scriptable | Every parameter is available as a flag or environment variable |
| Repeatable | `--force` recreates a container from scratch, `--name` installs a second instance side by side |

## How it fits

```text
   SSH · provisioning · CI
             │
    ./install.sh <protocol>
             │
   Docker containers on the server
 amnezia-awg2 · amnezia-awg · amnezia-xray
             │
   Amnezia app · Amnezia API · your automation
```

Already have containers installed by the Amnezia client? You do **not** need these scripts—they create exactly the same layout. Use them when the client is not an option or when installs must be automated.

## The full stack

Three small projects cover the path from an empty server to users whose Russian traffic goes direct:

| Step | Project | What it does |
| --- | --- | --- |
| 1. Server | **amnezia-protocols** (this repo) | Installs AmneziaWG 3.1, AmneziaWG 1.5, or Xray REALITY in Docker |
| 2. Clients | [amnezia-api](https://github.com/kyoresuas/amnezia-api) | Issues, disables, and deletes clients over HTTP and returns ready-to-import `vpn://` configs |
| 3. Routing | [ru-direct](https://github.com/kyoresuas/ru-direct) | Daily-updated lists of Russian subnets and domains: banks, Gosuslugi, and marketplaces go direct, everything else goes through your server |

## Supported protocols

| Protocol | Command | Container | Server config |
| --- | --- | --- | --- |
| AmneziaWG 3.1 | `./install.sh awg` | `amnezia-awg2` | `/opt/amnezia/awg/awg0.conf` |
| AmneziaWG 1.5 | `./install.sh awg-legacy` | `amnezia-awg` | `/opt/amnezia/awg/wg0.conf` |
| Xray (VLESS + REALITY) | `./install.sh xray` | `amnezia-xray` | `/opt/amnezia/xray/server.json` |

AmneziaWG 3.1 lives in the `amnezia-awg2` container—the same one the Amnezia client uses for 2.0. The protocol version is defined by the parameter set in `awg0.conf`, not by the container name.

## Requirements

- A Linux server with Docker and outbound access to Docker Hub.
- `curl` and `tar` for the one-command install; `git` if you prefer to clone.
- Root or `sudo` access.
- A free UDP port for AmneziaWG or a free TCP port for Xray.
- Debian or Ubuntu is tested; any Docker-capable distribution should work.

## Quick start

### One command

Run it on the server. Anything after `--` goes to the installer, so every flag from [Options](#options) works:

```bash
curl -fsSL https://raw.githubusercontent.com/kyoresuas/amnezia-protocols/main/install.sh | sudo bash -s -- awg --port 55424 --subnet 10.8.1.0
```

The script downloads this repository as an archive into a temporary directory, runs the installer for the chosen protocol, and deletes the archive afterwards.

Piping a script into a root shell means trusting whatever sits at that URL. To pin a version, use a tag or commit in both places:

```bash
curl -fsSL https://raw.githubusercontent.com/kyoresuas/amnezia-protocols/<ref>/install.sh | sudo AMNEZIA_PROTOCOLS_REF=<ref> bash -s -- awg
```

### From a clone

Prefer to read the code first? Clone the repository on the server and run the installer:

```bash
git clone https://github.com/kyoresuas/amnezia-protocols.git
cd amnezia-protocols
./install.sh
```

Without arguments the installer asks which protocol to deploy. Pass the protocol directly to skip the prompt:

```bash
./install.sh awg --port 55424 --subnet 10.8.1.0
```

The installer:

1. Checks that Docker is installed and running.
2. Creates the `amnezia-dns-net` Docker network when it is missing.
3. Builds the protocol image from the bundled `Dockerfile`.
4. Starts the container with the required capabilities and published port.
5. Generates server keys and the server config inside the container.
6. Installs `start.sh`, restarts the container, and prints the public key.

A finished AmneziaWG 3.1 install ends with this summary (the installer prints its messages in Russian, and the public key differs on every server):

```text
Готово!
────────────────────────────────────
  Контейнер: amnezia-awg2
  Протокол: AmneziaWG 3.1
  Порт: 55424/udp
  Подсеть: 10.8.0.0/24
  Public key: <server public key>
```

> [!WARNING]
> `--force` recreates the container and generates **new server keys**. Every previously issued client config stops working. Never run it against a server with live users unless that is what you want.

## Options

Shared by every protocol:

| Flag | Environment variable | Description |
| --- | --- | --- |
| `--name` | `CONTAINER_NAME` | Container name; defaults to the Amnezia name for that protocol |
| `--force` | — | Recreate an existing container and regenerate keys |
| — | `AMNEZIA_PROTOCOLS_REF` | Branch, tag, or commit the one-command install downloads; defaults to `main` |

### AmneziaWG 3.1 and 1.5

| Flag | Environment variable | Default | Description |
| --- | --- | --- | --- |
| `--port` | `AWG_SERVER_PORT` | `55424` | UDP port published on the host |
| `--subnet` | `AWG_SUBNET_IP` | `10.8.0.0` | VPN subnet address assigned to the interface |
| `--cidr` | `WIREGUARD_SUBNET_CIDR` | `24` | VPN subnet prefix length |

### Xray

| Flag | Environment variable | Default | Description |
| --- | --- | --- | --- |
| `--port` | `XRAY_SERVER_PORT` | `443` | TCP port published on the host |
| `--site` | `XRAY_SITE_NAME` | `www.googletagmanager.com` | REALITY SNI and destination site |

## Obfuscation parameters

Every AmneziaWG parameter is generated per install and can be overridden with an environment variable. Values follow the Amnezia client installer.

| Parameter | Variable | Default | Version |
| --- | --- | --- | --- |
| `Jc` | `JUNK_PACKET_COUNT` | random `4..6` | all |
| `Jmin` / `Jmax` | `JUNK_PACKET_MIN_SIZE` / `JUNK_PACKET_MAX_SIZE` | `10` / `50` | all |
| `S1` / `S2` | `INIT_PACKET_JUNK_SIZE` / `RESPONSE_PACKET_JUNK_SIZE` | random `12..149` | all |
| `S3` / `S4` | `COOKIE_REPLY_PACKET_JUNK_SIZE` / `TRANSPORT_PACKET_JUNK_SIZE` | random `12..63` / `12` | 2.0+ |
| `H1`–`H4` | `INIT_PACKET_MAGIC_HEADER` … `TRANSPORT_PACKET_MAGIC_HEADER` | `1`–`4` | all |
| `I1`–`I5` | `SPECIAL_JUNK_1` … `SPECIAL_JUNK_5` | empty | 1.5+ |
| `HeaderProtectionKey` | `HEADER_PROTECTION_KEY` | generated key | 3.1 |
| `ContentPaddingAddition` | `CONTENT_PADDING_ADDITION` | `10-100` | 3.1 |
| `RekeyAfterTime` | `REKEY_AFTER_TIME` | `100-120` | 3.1 |
| `RekeyTimeout` | `REKEY_TIMEOUT` | `3-7` | 3.1 |
| `RejectAfterTime` | `REJECT_AFTER_TIME` | `150-180` | 3.1 |
| `KeepaliveTimeout` | `KEEPALIVE_TIMEOUT` | `5-15` | 3.1 |
| `MaxHandshakeAttempts` | `MAX_HANDSHAKE_ATTEMPTS` | `15-20` | 3.1 |
| `RandomTrailers` | `RANDOM_TRAILERS` | `on` | 3.1 |
| `DisableCookies` | `DISABLE_COOKIES` | `on` | 3.1 |

Junk sizes are generated so that no two obfuscated packets end up with the same length, which is the same constraint the Amnezia client enforces. Magic headers stay sequential because AmneziaWG 3.1 encrypts packet headers with `HeaderProtectionKey`.

Example with pinned values:

```bash
JUNK_PACKET_COUNT=5 CONTENT_PADDING_ADDITION=20-120 ./install.sh awg --port 51820
```

## Generated files

| Path inside the container | Contents |
| --- | --- |
| `/opt/amnezia/awg/awg0.conf` | AmneziaWG 3.1 server config |
| `/opt/amnezia/awg/wg0.conf` | AmneziaWG 1.5 server config |
| `/opt/amnezia/awg/wireguard_server_private_key.key` | Server private key |
| `/opt/amnezia/awg/wireguard_server_public_key.key` | Server public key |
| `/opt/amnezia/awg/wireguard_psk.key` | Preshared key issued to clients |
| `/opt/amnezia/xray/server.json` | Xray server config |
| `/opt/amnezia/xray/xray_private.key`, `xray_public.key` | REALITY key pair |
| `/opt/amnezia/xray/xray_short_id.key`, `xray_uuid.key` | REALITY short ID and first client UUID |

Back these files up before recreating a container—they are the only copy of the server identity.

## Verifying the result

```bash
docker exec amnezia-awg2 awg show awg0
docker exec amnezia-awg2 cat /opt/amnezia/awg/awg0.conf
docker exec amnezia-xray cat /opt/amnezia/xray/server.json
```

A healthy AmneziaWG 3.1 interface reports `header protection key`, `content padding addition`, `random trailers: on`, and `disable cookies: on`.

## Managing clients

These scripts install and configure the server side. To issue, list, disable, and delete clients over HTTP, install [Amnezia API](https://github.com/kyoresuas/amnezia-api) next to the containers:

```bash
git clone https://github.com/kyoresuas/amnezia-api.git
cd amnezia-api
bash ./scripts/setup.sh
```

The API detects the running containers, serves `amnezia-awg2` as the `amneziawg3` protocol, and returns ready-to-import `vpn://` configs. Alternatively, add peers to the server config by hand and reload the interface:

```bash
docker exec amnezia-awg2 sh -lc 'awg syncconf awg0 <(awg-quick strip /opt/amnezia/awg/awg0.conf)'
```

Once clients connect, give them the [ru-direct](https://github.com/kyoresuas/ru-direct) lists so Russian banks, Gosuslugi, and marketplaces keep working without the VPN.

## Removing a protocol

```bash
docker rm -f amnezia-awg2
docker rmi amnezia-awg2
```

## Security

These scripts create privileged containers that terminate VPN traffic and hold server keys.

- The one-command install pipes a script into a root shell. Pin a tag or commit in the URL and in `AMNEZIA_PROTOCOLS_REF`, or clone the repository and read the code first.
- Containers run with `--privileged`, `NET_ADMIN`, and `SYS_MODULE`; install them only on hosts you control.
- Server keys live inside the container filesystem. Copy them out for backup and store them as secrets.
- Publish only the ports you need and restrict the rest at the host firewall or cloud security group.
- Do not publish private keys, preshared keys, `vpn://` configs, or QR codes in issues and screenshots.
- Rebuild the images periodically: `--pull` fetches the current Amnezia base image with protocol fixes.
- Obfuscation is not authentication. Keep client keys secret and rotate anything that may have leaked.

Report suspected vulnerabilities privately by following [SECURITY.md](SECURITY.md). Do not open a public issue for a security report.

## Development

```bash
shellcheck install.sh protocols/*/*.sh
find . -name '*.sh' -exec bash -n {} \;
```

CI runs the same checks and installs AmneziaWG 3.1 on a clean runner. See [CONTRIBUTING.md](CONTRIBUTING.md) for the full workflow and the compatibility rules that keep these scripts interchangeable with the Amnezia client.

## Ecosystem

- [amnezia-api](https://github.com/kyoresuas/amnezia-api) — REST API for managing clients on the servers these scripts create.
- [amnezia-panel](https://github.com/slowy19/amnezia-panel) — a web administration panel built on top of Amnezia API.
- [ru-direct](https://github.com/kyoresuas/ru-direct) — daily-updated Russian subnet and domain lists for split tunneling in AmneziaVPN, WireGuard, Xray, sing-box, and routers.

## Support the project

If Amnezia Protocols is useful to you, you can support its development:

- **Russian MIR card:** `2200700644781816`
- **TON:** `kyoresuas.ton`
- **TON wallet address:** `UQATzyMcVoZudjaA5Rc9w5TV_lIqxh9DPk0gSnjkLVvwEVqz`
- **USDT on TRON (TRC-20):** `TJSLjDo4yRgHr9JqqEcrkbC51bP9DCiBC7`

Please verify the network before transferring cryptocurrency.

## Project status and support

Bug reports and feature requests are welcome in [GitHub Issues](https://github.com/kyoresuas/amnezia-protocols/issues).

- Telegram: [@stercuss](https://t.me/stercuss)
- Email: [hey@kyoresuas.com](mailto:hey@kyoresuas.com)

## Disclaimer

This is an independent community project. It is not affiliated with, sponsored by, or officially endorsed by the Amnezia project. The Dockerfiles and container layout follow the Amnezia client's server scripts.

## License

[MIT](LICENSE)
