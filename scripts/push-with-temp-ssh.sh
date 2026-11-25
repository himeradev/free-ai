#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage:
  GITHUB_TOKEN=<token> ./scripts/push-with-temp-ssh.sh [remote] [branch]

Pushes the current HEAD to a GitHub remote by creating a temporary SSH key,
registering it on the token owner's account, pushing over SSH, then deleting
the key. Useful when HTTPS push with a PAT is rejected but the PAT has repo
access and can manage SSH keys.

Environment:
  GITHUB_TOKEN / GH_TOKEN   GitHub token with repo access and user SSH key write
  GIT_REMOTE                Remote name or URL (default: origin)
  GIT_BRANCH                Target branch (default: current branch)
EOF
  exit 1
}

TOKEN="${GITHUB_TOKEN:-${GH_TOKEN:-}}"
REMOTE="${GIT_REMOTE:-${1:-origin}}"
BRANCH="${GIT_BRANCH:-${2:-$(git branch --show-current)}}"

[ -n "$TOKEN" ] || usage
[ -n "$BRANCH" ] || { echo "No branch detected" >&2; exit 1; }

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

REMOTE_URL="$(git remote get-url "$REMOTE" 2>/dev/null || printf '%s' "$REMOTE")"

parse_github_repo() {
  local url="$1"
  url="${url%.git}"
  if [[ "$url" =~ ^git@github\.com:(.+/.+)$ ]]; then
    printf '%s\n' "${BASH_REMATCH[1]}"
  elif [[ "$url" =~ ^https://github\.com/(.+/.+)$ ]]; then
    printf '%s\n' "${BASH_REMATCH[1]}"
  elif [[ "$url" =~ ^ssh://git@github\.com/(.+/.+)$ ]]; then
    printf '%s\n' "${BASH_REMATCH[1]}"
  else
    return 1
  fi
}

REPO_SLUG="$(parse_github_repo "$REMOTE_URL")" || {
  echo "Unsupported remote: $REMOTE_URL" >&2
  exit 1
}

KEY_FILE="$(mktemp /tmp/gh-push-key.XXXXXX)"
PUB_FILE="${KEY_FILE}.pub"
KEY_ID=""

cleanup() {
  if [ -n "$KEY_ID" ]; then
    python3 - "$TOKEN" "$KEY_ID" <<'PY' >/dev/null 2>&1 || true
import sys, urllib.request
token, key_id = sys.argv[1], sys.argv[2]
req = urllib.request.Request(
    f'https://api.github.com/user/keys/{key_id}',
    method='DELETE',
    headers={
        'Authorization': f'Bearer {token}',
        'Accept': 'application/vnd.github+json',
        'X-GitHub-Api-Version': '2022-11-28',
    },
)
try:
    urllib.request.urlopen(req)
except Exception:
    pass
PY
  fi
  rm -f "$KEY_FILE" "$PUB_FILE"
}
trap cleanup EXIT

ssh-keygen -t ed25519 -N "" -f "$KEY_FILE" -C "temp-push-$(date +%s)" >/dev/null

KEY_ID="$(python3 - "$TOKEN" "$PUB_FILE" <<'PY'
import json, sys, urllib.request
token, pub_path = sys.argv[1], sys.argv[2]
pub = open(pub_path, encoding='utf-8').read().strip()
data = json.dumps({'title': 'temp-opencode-push', 'key': pub}).encode()
req = urllib.request.Request(
    'https://api.github.com/user/keys',
    data=data,
    headers={
        'Authorization': f'Bearer {token}',
        'Accept': 'application/vnd.github+json',
        'X-GitHub-Api-Version': '2022-11-28',
        'Content-Type': 'application/json',
    },
)
with urllib.request.urlopen(req) as r:
    body = json.loads(r.read().decode())
print(body['id'])
PY
)"

export GIT_SSH_COMMAND="ssh -i $KEY_FILE -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new"
git push "git@github.com:${REPO_SLUG}.git" "HEAD:${BRANCH}"
echo "Pushed HEAD to ${REPO_SLUG}:${BRANCH}"
