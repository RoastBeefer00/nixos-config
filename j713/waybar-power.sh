# Waybar's power readout: watts in or out of the battery, with time left in the tooltip.
B=/sys/class/power_supply/macsmc-battery
uw=$(cat $B/power_now); wh=$(cat $B/energy_now); full=$(cat $B/energy_full); status=$(cat $B/status)
uw=${uw#-}
awk -v uw="$uw" -v wh="$wh" -v full="$full" -v status="$status" 'BEGIN {
  w = uw / 1e6
  if (status == "Charging" && uw > 0) { h = (full - wh) / uw; what = "until full" }
  else if (uw > 0) { h = wh / uw; what = "left" }
  else { h = -1 }
  tip = (h < 0) ? status : sprintf("%s: %dh %02dm %s at this draw", status, int(h), int((h - int(h)) * 60), what)
  printf "{\"text\": \"%.1fW\", \"tooltip\": \"%s\", \"class\": \"%s\"}\n", w, tip, tolower(status)
}'
