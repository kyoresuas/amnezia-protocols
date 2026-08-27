## Summary

Describe what changed and why.

## Verification

List the checks you ran, including the server or runner the scripts were installed on.

## Checklist

- [ ] The change is focused and does not include unrelated refactoring.
- [ ] `shellcheck install.sh protocols/*/*.sh` passes.
- [ ] The affected protocol was installed on a clean host and the interface came up.
- [ ] Container names, file paths, and parameter names still match the Amnezia client.
- [ ] Public behavior, flags, and environment variables are documented in both READMEs.
- [ ] Breaking changes to flags, defaults, or container layout are clearly identified.
- [ ] No private keys, VPN configs, QR codes, or real server addresses are included.
