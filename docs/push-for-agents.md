# Push for AI agents

This repo includes `scripts/push-with-temp-ssh.sh` for environments where HTTPS push with a GitHub PAT fails, but the PAT can manage account SSH keys.

## What it does

1. Creates a temporary local ed25519 SSH key.
2. Registers the public key on the GitHub account behind the token.
3. Pushes `HEAD` to `git@github.com:<owner>/<repo>.git` over SSH.
4. Deletes the registered key and local key files on exit.

## Requirements

- `git`, `ssh-keygen`, `ssh`, `python3`
- A GitHub token in `GITHUB_TOKEN` or `GH_TOKEN`
- Token must have access to push to the target repo
- Token must be allowed to create/delete user SSH keys

## Usage

From the repository root:

```bash
GIT_AUTHOR_NAME="agent-name" \
GIT_AUTHOR_EMAIL="agent@example.com" \
GIT_COMMITTER_NAME="agent-name" \
GIT_COMMITTER_EMAIL="agent@example.com" \
GITHUB_TOKEN="<token>" \
./scripts/push-with-temp-ssh.sh origin main
```

You can omit args to use `origin` and the current branch:

```bash
GITHUB_TOKEN="<token>" ./scripts/push-with-temp-ssh.sh
```

## Notes

- The script does not store the token in git config or remotes.
- It registers a temporary SSH key titled `temp-opencode-push`; it removes it after push.
- If push fails before cleanup, the trap still attempts key deletion.
- Do not commit tokens or private keys.
