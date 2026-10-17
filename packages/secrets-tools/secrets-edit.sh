# secrets-edit: edit an encrypted secrets file with `sops edit`.
#
# The decrypted temporary file goes in $XDG_RUNTIME_DIR (tmpfs) rather than
# /tmp, which is on disk. Vim-family editors are started without swap, viminfo
# or undo files, which would otherwise leave decrypted content on disk.
#
# Never run this under `set -x`.
set +x
set -euo pipefail

die() {
  printf 'secrets-edit: error: %s\n' "$*" >&2
  exit 1
}

(($# == 1)) || die 'usage: secrets-edit FILE'
[[ -n ${XDG_RUNTIME_DIR:-} && -d $XDG_RUNTIME_DIR ]] ||
  die 'XDG_RUNTIME_DIR is not set; refusing to edit secrets on a disk-backed /tmp'

editor=${SOPS_EDITOR:-${EDITOR:-vi}}
case $(basename "${editor%% *}") in
  vi | vim | nvim)
    editor="$editor -n -i NONE -c 'set noundofile nobackup nowritebackup'"
    ;;
  *) ;;
esac

identity=$(sops-age-derive) || die 'could not derive the age identity'

TMPDIR=$XDG_RUNTIME_DIR SOPS_EDITOR=$editor SOPS_AGE_KEY=$identity exec sops edit "$1"
