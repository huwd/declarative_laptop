# with-secrets: run one command with decrypted secrets in its environment.
#
# Derives the age identity once (one agent signature), decrypts the central
# secrets file and the project's secrets.sops.env, merges them (project wins),
# and execs the command. Plaintext never touches disk, and the values are
# exported with the shell builtin rather than passed through `env`, so they
# never appear in a process's argv.
#
# Never run this under `set -x`: tracing would print the secrets.
set +x
set -euo pipefail

if [[ -t 2 && -z "${NO_COLOR:-}" ]]; then
  yellow=$'\e[1;33m' red=$'\e[1;31m' reset=$'\e[0m'
else
  yellow='' red='' reset=''
fi
warn() { printf '%swith-secrets: warning:%s %s\n' "$yellow" "$reset" "$*" >&2; }
die() {
  printf '%swith-secrets: error:%s %s\n' "$red" "$reset" "$*" >&2
  exit 1
}

usage() {
  cat <<'EOF'
usage: with-secrets [-f FILE]... [--only VAR,VAR] [--] COMMAND [ARG...]

  -f FILE        decrypt this file instead of the defaults (repeatable)
  --only A,B     inject only the named variables
  -h, --help     show this help

By default: $SECRETS_CENTRAL (~/.secrets/dev.sops.env) plus secrets.sops.env at
the git root. Later files override earlier ones.
EOF
}

files=()
only=''
while (($#)); do
  case $1 in
    -f)
      (($# >= 2)) || die '-f needs a file'
      files+=("$2")
      shift 2
      ;;
    --only)
      (($# >= 2)) || die '--only needs a comma-separated list'
      only=$2
      shift 2
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    --)
      shift
      break
      ;;
    -*) die "unknown option: $1" ;;
    *) break ;;
  esac
done
(($#)) || {
  usage >&2
  exit 2
}

if ((${#files[@]} == 0)); then
  central=${SECRETS_CENTRAL:-$HOME/.secrets/dev.sops.env}
  if [[ -f $central ]]; then
    files+=("$central")
  else
    warn "central secrets file not found: $central"
  fi
  if root=$(git rev-parse --show-toplevel 2>/dev/null); then
    if [[ -f $root/secrets.sops.env ]]; then
      files+=("$root/secrets.sops.env")
    else
      warn "no secrets.sops.env at $root; using central secrets only"
    fi
  else
    warn 'not inside a git repository; using central secrets only'
  fi
  ((${#files[@]})) || die 'no secrets files found'
fi

identity=$(sops-age-derive) || die 'could not derive the age identity'

declare -A secrets=()
for file in "${files[@]}"; do
  [[ -f $file ]] || die "no such file: $file"
  decrypted=$(SOPS_AGE_KEY=$identity sops decrypt --output-type dotenv "$file") ||
    die "could not decrypt $file"
  while IFS= read -r line; do
    if [[ -z $line || $line == \#* ]]; then continue; fi
    [[ $line == *=* ]] || die "malformed line in $file (no '=')"
    key=${line%%=*}
    [[ $key =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || die "invalid variable name in $file: $key"
    secrets[$key]=${line#*=}
  done <<<"$decrypted"
done
unset identity decrypted

declare -A keep=()
if [[ -n $only ]]; then
  IFS=, read -ra wanted <<<"$only"
  for key in "${wanted[@]}"; do
    [[ -v secrets[$key] ]] || die "--only: $key is not in the decrypted secrets"
    keep[$key]=1
  done
fi

for key in "${!secrets[@]}"; do
  if [[ -n $only && -z ${keep[$key]:-} ]]; then continue; fi
  export "$key=${secrets[$key]}"
done

unset SOPS_AGE_KEY SOPS_AGE_KEY_CMD
exec "$@"
