# Security Policy

Amnezia Protocols generates VPN server keys and runs privileged Docker containers. Please treat suspected vulnerabilities as sensitive.

## Supported versions

Security fixes are applied to the latest code on the `main` branch. Older commits are not maintained separately.

## Reporting a vulnerability

Do not open a public GitHub issue.

Email [hey@kyoresuas.com](mailto:hey@kyoresuas.com) with:

- a clear description of the vulnerability and its impact;
- the affected protocol, script, and commit SHA;
- minimal reproduction steps or a proof of concept;
- any suggested mitigation;
- whether the report may be credited publicly after a fix.

Remove real private keys, preshared keys, VPN configs, QR codes, client identifiers, IP addresses, and other sensitive production data. Use a disposable server whenever possible.

The report will be reviewed before details are made public. Please allow time for investigation and remediation, and coordinate disclosure with the maintainer.

## Deployment responsibility

These scripts install privileged containers that terminate VPN traffic. Operators are responsible for firewall rules, key storage, container updates, and host security. See the security section in [README.md](README.md#security).
