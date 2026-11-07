# Take the newest commit of Aurora's channel, rebuild, and record the new pin in the repo.
repo=$HOME/projects/nixos-config
cd "$repo" || exit 1

finish() {
  read -r -p "Press Enter to close. "
  exit "$1"
}

if ! git diff --quiet -- flake.lock; then
  echo "flake.lock has uncommitted changes. Commit or discard them first."
  finish 1
fi
git pull --ff-only || finish 1

pin=$(jq -r .nodes.aurora.locked.rev flake.lock)
compare=$(curl -fsS "https://api.github.com/repos/aurora-silicon/nixos-aurora/compare/$pin...channel-testing") || finish 1
if [[ $(jq -r .ahead_by <<<"$compare") == 0 ]]; then
  echo "Already up to date."
  finish 0
fi

jq -r '.commits[] | .sha[0:7] + "  " + (.commit.message | split("\n")[0])' <<<"$compare"
echo
read -r -p "Update to these? [y/N] " answer
if [[ $answer != [yY]* ]]; then
  finish 0
fi

nix flake update aurora --flake . || finish 1
if ! sudo nixos-rebuild switch --flake "$repo#j713"; then
  git checkout -- flake.lock
  echo "The rebuild failed, so the old version is still running and flake.lock is back as it was."
  finish 1
fi

git commit -m "j713: update Aurora" -- flake.lock
git push || echo "Couldn't push, so the new pin is only committed on this machine."

if [[ $(readlink /run/booted-system/kernel) != $(readlink /run/current-system/kernel) ]]; then
  echo "New kernel installed. Reboot to start using it."
fi
finish 0
