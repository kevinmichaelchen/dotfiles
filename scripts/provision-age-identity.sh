#!/usr/bin/env bash
# Provision the private age identity that unlocks Chezmoi's encrypted source files.

set -euo pipefail

identity="${CHEZMOI_AGE_IDENTITY:-$HOME/.config/chezmoi/key.txt}"
identity_source="${CHEZMOI_AGE_IDENTITY_FILE:-}"
dotfiles_dir="${DOTFILES_DIR:-$HOME/dotfiles}"

usage() {
  cat <<'EOF'
Usage: provision-age-identity.sh [--generate]

Provision ~/.config/chezmoi/key.txt from CHEZMOI_AGE_IDENTITY_FILE. The source
must be an existing age identity file supplied out-of-band. Use --generate only
when creating the repository's first identity, not when joining another machine.
EOF
}

generate="${CHEZMOI_AGE_GENERATE:-0}"
case "${1:-}" in
  "") ;;
  --generate) generate=1 ;;
  -h|--help)
    usage
    exit 0
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac

if ! command -v rage-keygen >/dev/null 2>&1; then
  echo "rage-keygen is required; run the mise package bootstrap first" >&2
  exit 1
fi

if [[ -e "$identity" ]]; then
  chmod 600 "$identity"
  rage-keygen -y "$identity" >/dev/null
  echo "Using existing age identity at $identity"
  exit 0
fi

mkdir -p "$(dirname "$identity")"

if [[ -n "$identity_source" ]]; then
  if [[ ! -f "$identity_source" ]]; then
    echo "CHEZMOI_AGE_IDENTITY_FILE does not exist: $identity_source" >&2
    exit 1
  fi
  install -m 600 "$identity_source" "$identity"
elif [[ "$generate" == "1" ]]; then
  if find "$dotfiles_dir/chezmoi" -type f -name '*.age' -print -quit | grep -q .; then
    echo "Refusing to generate a new identity: encrypted source files already exist" >&2
    echo "Provision the repository's existing identity with CHEZMOI_AGE_IDENTITY_FILE" >&2
    exit 1
  fi
  umask 077
  rage-keygen -o "$identity"
else
  cat >&2 <<EOF
Missing age identity: $identity

Copy the repository identity to this machine, then rerun with:
  CHEZMOI_AGE_IDENTITY_FILE=/path/to/key.txt mise bootstrap --yes

Use CHEZMOI_AGE_GENERATE=1 only once, when establishing the first identity. A
newly generated key cannot decrypt existing secrets.
EOF
  exit 1
fi

chmod 600 "$identity"
rage-keygen -y "$identity" >/dev/null
echo "Provisioned age identity at $identity"
