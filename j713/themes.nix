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

  # Wallpapers are pinned to a commit and cropped to the panel at build time; none are stored in this repo.
  themes = {
    catppuccin-mocha = {
      name = "Catppuccin Mocha";
      ghostty = "Catppuccin Mocha";
      nvim = "catppuccin-mocha";
      wallpaper = wallpaper "catppuccin-mocha"
        "https://raw.githubusercontent.com/zhichaoh/catppuccin-wallpapers/1023077979591cdeca76aae94e0359da1707a60e/landscapes/Clearnight.jpg"
        "sha256-scfoYBzVdRH4NytizwI938JFbfayeIdsne0FYCdsnfk=";
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
      wallpaper = wallpaper "tokyo-night"
        "https://codeberg.org/juna-lab/TokyoNight-Wallpapers/raw/commit/55721989fe73ee22f98f27975eec83f2a1b4bfbd/wallpapers/Characters%20%26%20People/a_city_at_night_with_many_tall_buildings.jpg"
        "sha256-XjNiiwEups4svUuuPaNvGBbvq0hnIstoJ+ZkqkOJzvk=";
      palette = {
        base = "1a1b26"; mantle = "16161e"; surface0 = "292e42"; surface1 = "3b4261"; surface2 = "545c7e";
        overlay0 = "565f89"; subtext0 = "a9b1d6"; text = "c0caf5";
        red = "f7768e"; yellow = "e0af68"; pink = "bb9af7"; sapphire = "7dcfff"; teal = "73daca";
        blue = "7aa2f7"; mauve = "7aa2f7"; lavender = "7dcfff";
      };
    };
    rose-pine = {
      name = "Rosé Pine";
      ghostty = "Rose Pine";
      nvim = "rose-pine-main";
      wallpaper = wallpaper "rose-pine"
        "https://raw.githubusercontent.com/rose-pine/wallpapers/ee39a37b24ab7700cc4d52f50b01a5d13df6a865/photography/kainoa-kanter/bay.jpg"
        "sha256-YLHsj9SKuJNwiYxCQ5zFDrdEfTSEH89ue95yBvQZ+MI=";
      palette = {
        base = "191724"; mantle = "16141f"; surface0 = "26233a"; surface1 = "403d52"; surface2 = "524f67";
        overlay0 = "6e6a86"; subtext0 = "908caa"; text = "e0def4";
        red = "eb6f92"; yellow = "f6c177"; pink = "ebbcba"; sapphire = "9ccfd8"; teal = "9ccfd8";
        blue = "9ccfd8"; mauve = "c4a7e7"; lavender = "ebbcba";
      };
    };
    gruvbox = {
      name = "Gruvbox Dark";
      ghostty = "Gruvbox Dark";
      nvim = "gruvbox";
      wallpaper = wallpaper "gruvbox"
        "https://raw.githubusercontent.com/AngelJumbo/gruvbox-wallpapers/293774acaa531ce106332f790c80301998066b25/wallpapers/photography/forest-3.jpg"
        "sha256-3y6YzTxrtGO0DDcwEixEDo16Gwu/BKkQu8waFWk1hZI=";
      palette = {
        base = "282828"; mantle = "1d2021"; surface0 = "3c3836"; surface1 = "504945"; surface2 = "665c54";
        overlay0 = "7c6f64"; subtext0 = "bdae93"; text = "ebdbb2";
        red = "fb4934"; yellow = "fabd2f"; pink = "d3869b"; sapphire = "83a598"; teal = "8ec07c";
        blue = "83a598"; mauve = "fe8019"; lavender = "fabd2f";
      };
    };
    kanagawa = {
      name = "Kanagawa Wave";
      ghostty = "Kanagawa Wave";
      nvim = "kanagawa-wave";
      wallpaper = wallpaper "kanagawa"
        "https://raw.githubusercontent.com/philikarus/Kanagawa-wallpapers/a8659f85a2f224619285025f29bc6a35fe21da1a/wallpapers/landscape/3895e.jpg"
        "sha256-OJXjRLhDTExsMsSrbhxBowCyWzOc35MNZBSt3APnXj0=";
      palette = {
        base = "1f1f28"; mantle = "16161d"; surface0 = "2a2a37"; surface1 = "363646"; surface2 = "54546d";
        overlay0 = "727169"; subtext0 = "c8c093"; text = "dcd7ba";
        red = "e46876"; yellow = "e6c384"; pink = "d27e99"; sapphire = "7fb4ca"; teal = "7aa89f";
        blue = "7e9cd8"; mauve = "957fb8"; lavender = "9cabca";
      };
    };
    nord = {
      name = "Nord";
      ghostty = "Nord";
      nvim = "nord";
      wallpaper = wallpaper "nord"
        "https://raw.githubusercontent.com/linuxdotexe/nordic-wallpapers/7a8e3bcabafbefd1c5b19229841b9bf377a4b765/wallpapers/misty_mountains.jpg"
        "sha256-nry0g6kNHRS6PHwbE9YNg7UDmUxqiHTyTffKke/T0ls=";
      palette = {
        base = "2e3440"; mantle = "242933"; surface0 = "3b4252"; surface1 = "434c5e"; surface2 = "4c566a";
        overlay0 = "616e88"; subtext0 = "d8dee9"; text = "eceff4";
        red = "bf616a"; yellow = "ebcb8b"; pink = "b48ead"; sapphire = "81a1c1"; teal = "8fbcbb";
        blue = "81a1c1"; mauve = "88c0d0"; lavender = "8fbcbb";
      };
    };
    everforest = {
      name = "Everforest";
      ghostty = "Everforest Dark Med";
      nvim = "everforest";
      wallpaper = wallpaper "everforest"
        "https://raw.githubusercontent.com/Apeiros-46B/everforest-walls/8f538b4e34a880748a471dc4c7aade6e29982417/nature/fog_forest_alt_1.png"
        "sha256-IeQzvScaS107R+639JzH/Jaxo4Vp0G+wpAm3ufoYHbY=";
      palette = {
        base = "2d353b"; mantle = "232a2e"; surface0 = "343f44"; surface1 = "3d484d"; surface2 = "475258";
        overlay0 = "7a8478"; subtext0 = "9da9a0"; text = "d3c6aa";
        red = "e67e80"; yellow = "dbbc7f"; pink = "d699b6"; sapphire = "7fbbb3"; teal = "83c092";
        blue = "7fbbb3"; mauve = "a7c080"; lavender = "83c092";
      };
    };
  };
  order = [ "catppuccin-mocha" "tokyo-night" "rose-pine" "gruvbox" "kanagawa" "nord" "everforest" ];
  default = "catppuccin-mocha";

  rgb = hex: lib.concatMapStringsSep ", " (i: toString (lib.fromHexString (builtins.substring i 2 hex))) [ 0 2 4 ];

  themeDir = id: t: let p = t.palette; in pkgs.linkFarm "theme-${id}" {
    "name" = pkgs.writeText "name" t.name;
    "wallpaper.jpg" = t.wallpaper;
    "nvim" = pkgs.writeText "nvim" t.nvim;
    "ghostty" = pkgs.writeText "ghostty" "theme = ${t.ghostty}\n";
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
      $wallpaper = ${t.wallpaper}
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

  # A rebuild makes new copies of the presets: keep the chosen one, pointed at the new copy.
  home.activation.j713Theme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${j713-theme}/bin/j713-theme --relink
  '';
}
