# Small desktop helpers for the Air, started from hyprland.lua or bound to keys there.
{ pkgs }:
let
  battery = "/sys/class/power_supply/macsmc-battery";
in
[
  # Night light. This panel has no gamma table or colour matrix, so hyprsunset, gammastep and redshift do nothing;
  # a Hyprland screen shader warms the picture instead. Like gammastep on the desktop (same location), it follows
  # the sun: off above 3 degrees of elevation, full warmth below -6, a gradual change in between.
  (pkgs.writeShellApplication {
    name = "j713-night-light";
    runtimeInputs = [ pkgs.coreutils pkgs.gnused pkgs.gawk pkgs.heliocron ];
    text = ''
      dir="''${XDG_RUNTIME_DIR:-/tmp}/night-light"
      mkdir -p "$dir"
      while :; do
        e=$(heliocron -l 32.3 -o -106.8 poll --json | sed -n 's/.*"solar_elevation":\([-0-9.]*\).*/\1/p')
        # Warmth 0-100 in steps of 10; if the sun can't be computed, keep the last setting.
        s=$(awk -v e="$e" 'BEGIN { if (e == "") exit 1; w = (3 - e) / 9; if (w < 0) w = 0; if (w > 1) w = 1; print int(w * 10 + 0.5) * 10 }') || { sleep 60; continue; }
        want=""
        if [ "$s" -gt 0 ]; then
          want="$dir/warm-$s.frag"
          if [ ! -e "$want" ]; then
            g=$(( 1000 - 200 * s / 100 )); b=$(( 1000 - 450 * s / 100 ))
            cat > "$want" <<EOF
      #version 300 es
      precision highp float;
      in vec2 v_texcoord;
      uniform sampler2D tex;
      out vec4 fragColor;
      void main() {
        vec4 c = texture(tex, v_texcoord);
        fragColor = vec4(c.r, c.g * 0.$g, c.b * 0.$b, c.a);
      }
      EOF
          fi
        fi
        have=$(hyprctl getoption decoration:screen_shader | sed -n 's/^str: //p')
        [ "$have" = "[[EMPTY]]" ] && have=""
        # Leave any other shader alone; re-apply ours if a config reload cleared it.
        case "$have" in "$dir"/*|"")
          if [ "$have" != "$want" ]; then
            hyprctl eval "hl.config({ decoration = { screen_shader = \"$want\" } })" > /dev/null || true
          fi ;;
        esac
        sleep 60
      done
    '';
  })

  # Notifications at 10% and 5% while on battery. UPower powers off at 3%.
  (pkgs.writeShellApplication {
    name = "j713-battery-warn";
    runtimeInputs = [ pkgs.coreutils pkgs.libnotify ];
    text = ''
      warned=100
      while :; do
        c=$(cat ${battery}/capacity); st=$(cat ${battery}/status)
        if [ "$st" != Discharging ]; then
          warned=100
        elif [ "$c" -le 5 ] && [ "$warned" -gt 5 ]; then
          notify-send -u critical -a Battery "Battery at $c%" "The Air shuts down at 3%. Plug it in now." && warned=5
        elif [ "$c" -le 10 ] && [ "$warned" -gt 10 ]; then
          notify-send -a Battery "Battery at $c%" "Time to find a charger." && warned=10
        fi
        sleep 60
      done
    '';
  })

  # Battery click in the bar: switch between the 80% charge limit (the default at every boot) and a full charge.
  (pkgs.writeShellApplication {
    name = "j713-charge-limit";
    runtimeInputs = [ pkgs.coreutils pkgs.libnotify ];
    text = ''
      f=${battery}/charge_control_end_threshold
      if [ "$(cat "$f")" -lt 100 ]; then
        echo 100 > "$f" && notify-send -a Battery "Charging to 100%" "Until you click again or reboot."
      else
        echo 80 > "$f" && notify-send -a Battery "Charging stops at 80%" "Easier on the battery over the years."
      fi
    '';
  })

  # Super+Shift+C: pick a colour anywhere on screen; its hex code goes to the clipboard.
  (pkgs.writeShellApplication {
    name = "j713-color-pick";
    runtimeInputs = [ pkgs.hyprpicker pkgs.wl-clipboard pkgs.libnotify ];
    text = ''
      c=$(hyprpicker -f hex) || exit 0
      [ -n "$c" ] || exit 0
      wl-copy "$c"
      notify-send -a "Color picker" "$c" "Copied to the clipboard."
    '';
  })

  # Super+Shift+R: select a region and record it to ~/Videos/Recordings; press again to stop. No audio.
  (pkgs.writeShellApplication {
    name = "j713-screen-record";
    runtimeInputs = [ pkgs.coreutils pkgs.procps pkgs.slurp pkgs.wf-recorder pkgs.libnotify ];
    text = ''
      dir="$HOME/Videos/Recordings"
      if pgrep -x wf-recorder > /dev/null; then
        pkill -INT -x wf-recorder
        notify-send -a "Screen recording" "Recording saved" "$dir"
        exit 0
      fi
      geom=$(slurp) || exit 0
      mkdir -p "$dir"
      notify-send -a "Screen recording" "Recording" "Super+Shift+R again to stop."
      exec wf-recorder -g "$geom" -f "$dir/$(date +%Y-%m-%d_%H-%M-%S).mp4"
    '';
  })
]
