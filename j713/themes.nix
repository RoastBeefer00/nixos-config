# Dark theme presets for the Air, switchable live with `j713-theme` (Super+Shift+T).
#
# Each preset maps its palette onto Catppuccin's colour names, which the bar, notifications, OSD, menus and lock screen
# already use as roles: base/mantle/surface* are backgrounds, text/subtext0/overlay0 are foregrounds, mauve is the
# accent. Switching points ~/.local/state/theme/current at the preset's generated folder and asks each app to reload.
# Neovim (nixvim-config) watches that folder and follows along. GTK and Qt apps stay on Catppuccin Mocha.
{ config, lib, pkgs, ... }:
let
  state = "${config.home.homeDirectory}/.local/state/theme";

  wallpaper = id: url: hash: pkgs.runCommand "wallpaper-${id}.jpg" { nativeBuildInputs = [ pkgs.imagemagick ]; } ''
    magick '${pkgs.fetchurl { inherit url hash; }}[0]' -resize 2560x1664^ -gravity center -extent 2560x1664 -quality 92 $out
  '';

  # Calm the top edge under Waybar (all presets), and dim the whole picture where a preset sets `dim` (percent).
  finish = id: t: let b = rgb t.palette.base; in pkgs.runCommand "wallpaper-${id}-final.jpg" { nativeBuildInputs = [ pkgs.imagemagick ]; } ''
    magick ${t.wallpaper} \
      \( -size 2560x1664 "xc:#${t.palette.base}" -alpha set -channel A -evaluate set ${toString (t.dim or 0)}% +channel \) -composite \
      \( -size 2560x260 "gradient:rgba(${b},0.95)-rgba(${b},0)" \) -gravity north -composite \
      -quality 92 $out
  '';

  tokyoNightAccents = {
    red = "f7768e"; yellow = "e0af68"; pink = "bb9af7"; sapphire = "7dcfff"; teal = "73daca";
    blue = "7aa2f7"; mauve = "7aa2f7"; lavender = "7dcfff";
  };

  # Wallpapers are pinned to a commit and cropped to the panel at build time; none are stored in this repo.
  themes = {
    catppuccin-mocha = {
      name = "Catppuccin Mocha";
      ghostty = "Catppuccin Mocha";
      nvim = "catppuccin-mocha";
      herdr = "catppuccin";
      dim = 35;
      wallpaper = wallpaper "catppuccin-mocha"
        "https://raw.githubusercontent.com/orangci/walls-catppuccin-mocha/7bfdf10d16ad3a689f9f0cf3a0930da3d1a245a8/cloud-coffee.jpg"
        "sha256-iG9Ar1KXiRBuzDWvveBPJx9Iq/HlmyKJ0Rv69rUiiGM=";
      palette = {
        base = "1e1e2e"; mantle = "181825"; surface0 = "313244"; surface1 = "45475a"; surface2 = "585b70";
        overlay0 = "6c7086"; subtext0 = "a6adc8"; text = "cdd6f4";
        red = "f38ba8"; yellow = "f9e2af"; pink = "f5c2e7"; sapphire = "74c7ec"; teal = "94e2d5";
        blue = "89b4fa"; mauve = "cba6f7"; lavender = "b4befe";
      };
    };
    tokyo-night = {
      name = "Tokyo Night";
      ghostty = "TokyoNight Night";
      nvim = "tokyonight-night";
      herdr = "tokyo-night";
      wallpaper = wallpaper "tokyo-night"
        "https://codeberg.org/juna-lab/TokyoNight-Wallpapers/raw/commit/55721989fe73ee22f98f27975eec83f2a1b4bfbd/wallpapers/Characters%20%26%20People/a_city_at_night_with_many_tall_buildings.jpg"
        "sha256-XjNiiwEups4svUuuPaNvGBbvq0hnIstoJ+ZkqkOJzvk=";
      palette = tokyoNightAccents // {
        base = "1a1b26"; mantle = "16161e"; surface0 = "292e42"; surface1 = "3b4261"; surface2 = "545c7e";
        overlay0 = "565f89"; subtext0 = "a9b1d6"; text = "c0caf5";
      };
    };
    rose-pine = {
      name = "Rosé Pine";
      ghostty = "Rose Pine";
      nvim = "rose-pine-main";
      herdr = "rose-pine";
      dim = 10;
      wallpaper = wallpaper "rose-pine"
        "https://raw.githubusercontent.com/archimedes64/rose-pine-wallpapers/e96012944f4fdc0c14800692d63af204d4f9e6b3/flowers.png"
        "sha256-YY1oeA2WdVRAfV5lraaCIpEWIEYVgUElFbgoAVLtNKg=";
      palette = {
        base = "191724"; mantle = "16141f"; surface0 = "26233a"; surface1 = "403d52"; surface2 = "524f67";
        overlay0 = "6e6a86"; subtext0 = "908caa"; text = "e0def4";
        red = "eb6f92"; yellow = "f6c177"; pink = "ebbcba"; sapphire = "9ccfd8"; teal = "9ccfd8";
        blue = "9ccfd8"; mauve = "c4a7e7"; lavender = "ebbcba";
      };
    };
  };
  order = [ "catppuccin-mocha" "tokyo-night" "rose-pine" ];
  default = "catppuccin-mocha";

  rgb = hex: lib.concatMapStringsSep ", " (i: toString (lib.fromHexString (builtins.substring i 2 hex))) [ 0 2 4 ];

  # herdr's shared config (hm_modules/herdr.nix), with this preset's built-in theme and its own accent and surfaces,
  # so the tabs and sidebar change visibly between presets that share a herdr theme.
  herdrConfig = t: let p = t.palette; in builtins.replaceStrings
    [ "[theme]\nname = \"tokyo-night\"\n" ]
    [ ''
      [theme]
      name = "${t.herdr}"

      [theme.custom]
      accent = "#${p.mauve}"
      surface0 = "#${p.surface0}"
      surface1 = "#${p.surface1}"
      overlay0 = "#${p.overlay0}"
      text = "#${p.text}"
      subtext0 = "#${p.subtext0}"
      red = "#${p.red}"
      yellow = "#${p.yellow}"
      blue = "#${p.blue}"
      teal = "#${p.teal}"
    '' ]
    (builtins.readFile ../herdr/config.toml);

  themeDir = id: t: let p = t.palette; in pkgs.linkFarm "theme-${id}" {
    "name" = pkgs.writeText "name" t.name;
    "wallpaper.jpg" = finish id t;
    "nvim" = pkgs.writeText "nvim" t.nvim;
    "ghostty" = pkgs.writeText "ghostty" "theme = ${t.ghostty}\n";
    "herdr.toml" = pkgs.writeText "herdr.toml" (herdrConfig t);
    # Waybar and swayosd (GTK CSS).
    "colors.css" = pkgs.writeText "colors.css" (lib.concatStrings (lib.mapAttrsToList (n: v: "@define-color ${n} #${v};\n") p));
    # swaync (CSS variables on top of its stock style).
    "swaync.css" = pkgs.writeText "swaync.css" ''
      :root {
        --cc-bg: rgba(${rgb p.base}, 0.82);
        --noti-border-color: #${p.surface1};
        --noti-bg: ${rgb p.base};
        --noti-bg-darker: #${p.mantle};
        --noti-bg-hover: #${p.surface0};
        --noti-bg-focus: rgba(${rgb p.surface1}, 0.6);
        --noti-close-bg: #${p.surface1};
        --noti-close-bg-hover: #${p.surface2};
        --text-color: #${p.text};
        --text-color-disabled: #${p.overlay0};
        --bg-selected: #${p.mauve};
        --j713-base: #${p.base};
        --j713-border: #${p.surface1};
        --j713-red: #${p.red};
        --j713-accent: #${p.mauve};
        --j713-accent-hover: #${p.lavender};
      }
    '';
    # rofi: the menus' translucent background.
    "rofi.rasi" = pkgs.writeText "rofi.rasi" ''
      * {
        bg-col: #${p.base}d9;
        bg-col-light: #${p.base};
        border-col: #${p.base};
        selected-col: #${p.base};
        blue: #${p.blue};
        fg-col: #${p.text};
        fg-col2: #${p.red};
        grey: #${p.overlay0};
      }
    '';
    "hyprlock.conf" = pkgs.writeText "hyprlock.conf" ''
      $wallpaper = ${finish id t}
      $text = rgb(${p.text})
      $accent = rgb(${p.mauve})
      $base = rgb(${p.base})
      $check = rgb(${p.yellow})
      $fail = rgb(${p.red})
    '';
    "hypr.lua" = pkgs.writeText "hypr.lua" ''
      return { active = "rgb(${p.mauve})", inactive = "rgba(${p.surface1}aa)" }
    '';
  };

  allThemes = pkgs.linkFarm "j713-themes" (lib.mapAttrs themeDir themes);

  menu = lib.concatMapStringsSep "\n" (id: "${id}\t${themes.${id}.name}") order;

  j713-theme = pkgs.writeShellApplication {
    name = "j713-theme";
    runtimeInputs = with pkgs; [ coreutils gnugrep gnused procps awww rofi libnotify swaynotificationcenter swayosd util-linux ];
    text = ''
      state="${state}"
      themes="${allThemes}"
      mkdir -p "$state"

      link() {  # point current at the preset's folder in this generation
        ln -sfn "$(readlink -f "$themes/$1")" "$state/current.new" && mv -T "$state/current.new" "$state/current"
        echo "$1" > "$state/id"
      }

      apply() {
        id=$1; transition=$2
        [ -e "$themes/$id" ] || { echo "unknown theme: $id" >&2; exit 1; }
        link "$id"
        for _ in $(seq 1 50); do awww query > /dev/null 2>&1 && break; sleep 0.1; done
        awww img "$state/current/wallpaper.jpg" --transition-type "$transition" --transition-duration 1.2 --transition-fps 60 || true
        hyprctl eval "local t = dofile('$state/current/hypr.lua'); hl.config({ general = { col = { active_border = t.active, inactive_border = t.inactive } } })" > /dev/null || true
        pkill -USR2 -x '\.?waybar(-wrapped)?' || true             # reloads its style
        swaync-client --reload-css > /dev/null 2>&1 || true
        pkill -USR2 -x '\.?ghostty(-wrappe|-wrapped)?' || true    # reloads its config
        if command -v herdr > /dev/null; then herdr server reload-config > /dev/null 2>&1 || true; fi
        if pkill -x '\.?swayosd-server' ; then setsid -f swayosd-server > /dev/null 2>&1; fi
      }

      case "''${1:-}" in
        --restore)
          id=$(cat "$state/id" 2>/dev/null || echo ${default})
          [ -e "$themes/$id" ] || id=${default}
          apply "$id" fade ;;
        --relink)  # after a rebuild: follow the new generation's copy, nothing else
          id=$(cat "$state/id" 2>/dev/null || echo ${default})
          [ -e "$themes/$id" ] || id=${default}
          link "$id" ;;
        "")
          current=$(cat "$state/id" 2>/dev/null || true)
          choice=$(printf '%s\n' "${menu}" | sed "s/^$current\t\(.*\)/$current\t\1  (current)/" \
            | rofi -dmenu -i -p Theme -display-columns 2 -display-column-separator '\t') || exit 0
          id=''${choice%%$'\t'*}
          apply "$id" grow
          notify-send -a Theme "$(cat "$state/current/name")" ;;
        *) apply "$1" grow ;;
      esac
    '';
  };
in
{
  home.packages = [ j713-theme pkgs.awww ];

  # Ghostty reads the preset's theme after its own config ("?" = fine if missing).
  programs.ghostty.settings.config-file = "?${state}/current/ghostty";

  # herdr's config is the shared one with the preset's colours; it follows the current preset.
  home.file.".config/herdr/config.toml".source = lib.mkForce (config.lib.file.mkOutOfStoreSymlink "${state}/current/herdr.toml");

  # A rebuild makes new copies of the presets: keep the chosen one, pointed at the new copy.
  home.activation.j713Theme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${j713-theme}/bin/j713-theme --relink
  '';
}
