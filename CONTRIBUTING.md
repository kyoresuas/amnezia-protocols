# Contributing to Amnezia Protocols

Thanks for helping improve Amnezia Protocols. Fixes for installer bugs, compatibility with new Amnezia releases, documentation, and support for additional protocols are welcome.

## Before you start

- Search existing issues before opening a new one.
- Use a GitHub issue for new protocols or changed defaults so the approach can be discussed first.
- Do not publish private keys, preshared keys, VPN configs, QR codes, or real server addresses.
- Report security vulnerabilities privately according to [SECURITY.md](SECURITY.md).

## Local development

Requirements:

- A disposable Linux server or virtual machine with Docker
- Root or `sudo` access
- ShellCheck for static analysis

Never develop against a server with live users: `--force` recreates the container and generates new server keys, which invalidates every existing client config.

## Project checks

Run all required checks before opening a pull request:

```bash
shellcheck install.sh protocols/*/*.sh
find . -name '*.sh' -exec bash -n {} \;
```

Then install the protocol you changed on a clean host and confirm the result:

```bash
./install.sh awg --name amnezia-awg-test --port 55424 --subnet 10.9.0.0
docker exec amnezia-awg-test awg show awg0
docker rm -f amnezia-awg-test
```

CI runs the same static checks and installs AmneziaWG 3.1 on a clean runner.

## Compatibility rules

The scripts must stay interchangeable with the Amnezia client and [Amnezia API](https://github.com/kyoresuas/amnezia-api):

1. Keep container names, interface names, and file paths identical to the Amnezia client.
2. Keep parameter names exactly as they appear in the client's server config.
3. Generate obfuscation values per install instead of hardcoding them.
4. When Amnezia changes a protocol, follow the upstream installer rather than inventing new defaults.

## Pull requests

1. Keep each pull request focused on one problem.
2. Explain the user-visible behavior and the reason for the change.
3. Describe the environment where the change was verified.
4. Update both `README.md` and `README_RU.md` when flags, defaults, or setup change.
5. Call out breaking changes to flags, defaults, or container layout explicitly.
6. Never commit generated keys, configs, or real server data.

By contributing, you agree that your contribution is licensed under the repository's [MIT License](LICENSE).
