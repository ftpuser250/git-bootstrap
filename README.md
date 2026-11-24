# Linux Git & GitHub Bootstrap

A modular Bash bootstrap utility for Git, GitHub CLI (`gh`), SSH, `tldr`, `nano`, SSH-agent setup, and SSH-based commit/tag signing.

Oh, btw, you might need this link : `https://killercoda.com/playgrounds/scenario/ubuntu`
it's recommended to switch to a normal user if root. create user if needed. 
you can do that with `su - ubuntu`

## Supported package managers

- Arch Linux / pacman
- Debian and Ubuntu / apt
- Fedora / dnf
- openSUSE / zypper
- Alpine / apk

Package availability can vary by release and repository configuration.

## Run

```bash
chmod +x bootstrap.sh
./bootstrap.sh
```

Options:

```text
--dry-run          Show planned actions without applying them
--skip-auth        Skip GitHub CLI authentication
--skip-signing     Skip commit/tag signing setup
--non-interactive  Avoid prompts and use defaults
--help             Show help
```

## What it does

1. Detects distro, package manager, desktop/session and systemd-user availability.
2. Installs Git, GitHub CLI, OpenSSH, tldr and nano if needed.
3. Prompts for Git name/email/default branch.
4. Checks for existing SSH keys and offers to reuse or create a key.
5. Adds a managed SSH configuration block for GitHub.
6. Attempts to configure a systemd user SSH-agent service where available, with a fallback warning.
7. Authenticates `gh` and sets SSH as its Git protocol.
8. Configures SSH commit and tag signing, uploads a signing key, and creates/updates local allowed signers.
9. Performs validation checks.

## Backups and safety

- Existing SSH keys are never automatically overwritten.
- Existing files modified by the script are copied to `.bak`; if a `.bak` already exists, a timestamped backup is used.
- Managed SSH configuration is placed between markers. The original file is backed up before changes.
- The script avoids intentionally deleting user configuration.
- Some operations (package installation, Git global settings, GitHub key uploads and agent loading) are external actions and cannot be rolled back by restoring file backups.
- Review the script before running it, especially when using `--non-interactive`.

## Notes / limitations

- A GitHub commit's **Verified** badge depends on GitHub-side key registration and the commit's identity, not only local signing.
- A key used for both authentication and signing has a wider compromise impact. Separate keys are an option for stronger separation.
- systemd environment files affect the user manager and may not automatically propagate to every already-running compositor, shell or application. Log out and back in if needed.
- This is a starter utility, not a universal installer. Unsupported distro/package combinations or session configurations may require manual adjustments.

## License

MIT. See `LICENSE`.
