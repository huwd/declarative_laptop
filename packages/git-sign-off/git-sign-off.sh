# git-sign-off: finish a branch for review, adding the maintainer's sign-off
# and signature to the commits an agent made.
#
# Agents commit without a signature or a Signed-off-by line, because both
# certify the change as the maintainer's. This script:
#
# 1. signs off and signs every commit on the branch that lacks a sign-off,
#    by rebasing from the oldest one, so commits already signed off and any
#    merges before it are left as they are
# 2. merges the default branch, signed and signed off, if the branch is
#    behind it, unless --no-update is given
# 3. checks every commit on the branch is signed and signed off
# 4. pushes the branch, and marks its pull request ready for review
#
# Each signature asks the signing agent, such as Bitwarden, for approval.
# Git runs this as `git sign-off`.

if [[ -t 2 && -z "${NO_COLOR:-}" ]]; then
  red=$'\e[1;31m' reset=$'\e[0m'
else
  red='' reset=''
fi
die() {
  printf '%sgit-sign-off: error:%s %s\n' "$red" "$reset" "$*" >&2
  exit 1
}

usage() {
  cat <<'EOF'
Usage: git sign-off [--no-update]

Sign off and sign the current branch's commits that lack a sign-off, push
the branch and mark its pull request ready.

  --no-update  don't merge the default branch when the branch is behind it
EOF
}

update=true
case "${1:-}" in
  "") ;;
  --no-update) update=false ;;
  -h | --help)
    usage
    exit 0
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac

branch=$(git branch --show-current)
[[ -n "$branch" ]] || die "not on a branch"
git fetch --quiet origin
base=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD) ||
  die "origin has no default branch set. Run: git remote set-head origin --auto"
[[ "origin/$branch" != "$base" ]] || die "refusing to change the default branch, $branch"
[[ -z "$(git status --porcelain --untracked-files=no)" ]] || die "commit or stash your changes first"

sign_off="Signed-off-by: $(git config user.name) <$(git config user.email)>"
has_sign_off() {
  git log -1 --format=%B "$1" | grep -qxF "$sign_off"
}

# The oldest commit without a sign-off. Rebasing from its parent rewrites
# only it and the commits after it.
first=""
for commit in $(git rev-list --reverse --no-merges "$base..HEAD"); do
  if ! has_sign_off "$commit"; then
    first=$commit
    break
  fi
done
if [[ -n "$first" ]]; then
  echo "Signing off $(git rev-list --count "$first^..HEAD") commits, from $(git log -1 --format='%h %s' "$first")"
  git rebase --quiet --signoff --force-rebase --rebase-merges "$first^" ||
    die "the rebase stopped. Finish it with git rebase --continue, then run this again"
fi

if [[ "$update" = true ]] && ! git merge-base --is-ancestor "$base" HEAD; then
  echo "Merging $base"
  git merge --signoff --no-edit "$base" ||
    die "the merge has conflicts. Resolve them, run git commit -s, then run this again"
fi

for commit in $(git rev-list "$base..HEAD"); do
  summary=$(git log -1 --format='%h %s' "$commit")
  [[ "$(git log -1 --format=%G? "$commit")" = G ]] || die "$summary has no good signature"
  has_sign_off "$commit" || die "$summary has no sign-off"
done

git push --force-with-lease --set-upstream origin "$branch"
if draft=$(gh pr view "$branch" --json isDraft --jq .isDraft 2>/dev/null); then
  if [[ "$draft" = true ]]; then
    gh pr ready "$branch"
  fi
  gh pr view "$branch" --json url --jq .url
else
  echo "Pushed $branch. It has no pull request yet."
fi
