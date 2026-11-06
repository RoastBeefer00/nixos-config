# Waybar's weather pill. Prints nothing when offline, which hides the pill.
IFS='|' read -r icon temp detail <<WTTR || true
$(curl -fsS --max-time 10 'https://wttr.in/lascruces+nm?format=%c|%t|%C,+%h+humidity,+%w')
WTTR
[ -n "$temp" ] || exit 0
printf '{"text": "%s %s", "tooltip": "%s"}\n' "$(printf %s "$icon" | tr -d ' ')" "${temp#+}" "$detail"
