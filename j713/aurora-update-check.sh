# Notify once for each new commit on Aurora's update channel, with a button that starts the update.
repo=$HOME/projects/nixos-config
aurora="aurora-silicon/nixos-aurora"
seen=${XDG_STATE_HOME:-$HOME/.local/state}/aurora-update-check

# The timer can fire right after a wake, before Wi-Fi is back.
fetch() { curl -fsS --retry 6 --retry-delay 20 --retry-all-errors "$1"; }
raw() { fetch "https://raw.githubusercontent.com/$aurora/$1/$2"; }

pin=$(jq -r .nodes.aurora.locked.rev "$repo/flake.lock")
head=$(fetch "https://api.github.com/repos/$aurora/git/ref/heads/channel-testing" | jq -r .object.sha)
if [[ $head == "$pin" || $head == "$(cat "$seen" 2>/dev/null)" ]]; then
  exit 0
fi

# The pin can be ahead of the channel, and that isn't an update.
count=$(fetch "https://api.github.com/repos/$aurora/compare/$pin...$head" | jq -r .ahead_by)
if ((count == 0)); then
  exit 0
fi

old_sources=$(raw "$pin" sources.json)
new_sources=$(raw "$head" sources.json)
changed() {
  [[ $(jq -r --arg k "$1" '.[$k].commit' <<<"$old_sources") != $(jq -r --arg k "$1" '.[$k].commit' <<<"$new_sources") ]]
}

# Hyprland comes from Aurora's nixpkgs. Not knowing its version shouldn't stop the notification.
hyprland_version() {
  local nixpkgs package
  nixpkgs=$(raw "$1" flake.lock | jq -r '.nodes[.nodes.root.inputs.nixpkgs].locked.rev') || return 0
  package=$(fetch "https://raw.githubusercontent.com/NixOS/nixpkgs/$nixpkgs/pkgs/by-name/hy/hyprland/package.nix") || return 0
  sed -n '/^ *version = "/{s/.*"\(.*\)".*/\1/p;q}' <<<"$package"
}

body="New commits: $count."
if changed kernel-aurora; then
  body+=$'\nNew kernel, so it needs a reboot.'
fi
if changed speakerguardd; then
  body+=$'\nSpeaker safety daemon changed.'
fi
old_hyprland=$(hyprland_version "$pin")
new_hyprland=$(hyprland_version "$head")
if [[ -n $old_hyprland && -n $new_hyprland && $old_hyprland != "$new_hyprland" ]]; then
  body+=$'\n'"Hyprland $old_hyprland to $new_hyprland."
fi

# Stays open so the button works from the panel. A real failure means no notification server, so try again next time.
status=0
action=$(timeout 6h notify-send --app-name=Aurora --icon=system-software-update --action=update=Update --wait "Aurora update available" "$body") || status=$?
if ((status != 0 && status != 124)); then
  exit "$status"
fi

mkdir -p "$(dirname "$seen")"
echo "$head" >"$seen"

if [[ $action == update ]]; then
  hyprctl dispatch 'hl.dsp.exec_cmd("ghostty --class=com.j713.popup -e j713-update")'
fi
