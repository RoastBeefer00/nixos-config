{ config, pkgs, ... }:

{
  # This module is automatically imported when using niri-flake
  # Make sure your flake.nix passes niri input to home-manager
  programs.niri.package = pkgs.niri;
  
  programs.niri = {
    settings = {
      # Monitor configuration
      outputs."DP-1" = {
        mode = {
          width = 3440;
          height = 1440;
          refresh = 144.0;
        };
        position = {
          x = 0;
          y = 0;
        };
        scale = 1.0;
      };

      # Startup applications
      spawn-at-startup = [
        { command = [ "waybar" ]; }
        { command = [ "mako" ]; }
        { command = [ "swaybg" "-i" "${config.home.homeDirectory}/Pictures/waves.jpg" ]; }
        { command = [ "/usr/lib/polkit-kde-authentication-agent-1" ]; }
        { command = [ "redshift" "-l" "32.3:-106.8" ]; }
      ];

      # Input configuration
      input = {
        mod-key = "Alt";
        keyboard.xkb = {
          layout = "us";
        };
        
        touchpad = {
          natural-scroll = false;
        };
      };

      # Layout configuration
      layout = {
        gaps = 10;
        center-focused-column = "never";
        
        preset-column-widths = [
          { proportion = 0.33333; }
          { proportion = 0.5; }
          { proportion = 0.66667; }
        ];
        
        default-column-width = { proportion = 0.5; };
        
        focus-ring = {
          enable = true;
          width = 2;
          active.color = "#9ccfd8";
          inactive.color = "#595959aa";
        };
        
        border = {
          enable = true;
          width = 2;
          active.color = "#9ccfd8";
          inactive.color = "#595959aa";
        };
      };

      # Prefer server-side decorations
      prefer-no-csd = true;

      # Window rules
      window-rules = [
        {
          matches = [{ app-id = "^onboard$"; }];
          open-floating = true;
        }
        {
          matches = [{ app-id = ".*\\.exe$"; }];
          open-floating = true;
        }
        {
          matches = [{ app-id = "^steam_app_.*$"; }];
          open-floating = true;
        }
        {
          matches = [{ app-id = "^steam_proton$"; }];
          open-floating = true;
        }
        # {
        #   # Apply rounded corners to all windows
        #   geometry-corner-radius = {
        #     top-left = 8.0;
        #     top-right = 8.0;
        #     bottom-left = 8.0;
        #     bottom-right = 8.0;
        #   };
        # }
      ];

      # Environment variables (useful for electron apps)
      environment = {
        NIXOS_OZONE_WL = "1";
        DISPLAY = ":0";
      };

      # Keybindings
      binds = with config.lib.niri.actions; {
        # Window management
        "Mod+Q".action = close-window;
        "Mod+F".action = maximize-column;
        "Mod+Shift+F".action = fullscreen-window;
        "Mod+Shift+Q".action = quit;
        "Mod+V".action = toggle-window-floating;
        "Mod+Ctrl+H".action = consume-or-expel-window-left;
        "Mod+Ctrl+L".action = consume-or-expel-window-right;
        
        # Application launchers
        "Mod+T".action.spawn = [ "thunar" ];
        "Mod+W".action.spawn = [ "google-chrome-stable" ];
        "Mod+Space".action.spawn = [ "rofi" "-show" "drun" ];
        "Mod+Return".action.spawn = [ "ghostty" ];
        "Mod+S".action.spawn = [ "rofi" "-show" "power-menu" "-modi" "power-menu:rofi-power-menu" ];
        "Mod+P".action.spawn = [ "hyprshot" "-m" "region" "--clipboard-only" ];
        
        # Audio controls
        "XF86AudioRaiseVolume".action.spawn = [ "pactl" "--" "set-sink-volume" "0" "+5%" ];
        "XF86AudioLowerVolume".action.spawn = [ "pactl" "--" "set-sink-volume" "0" "-5%" ];
        "XF86AudioMute".action.spawn = [ "pactl" "--" "set-sink-mute" "0" "toggle" ];
        
        # Brightness controls
        "XF86MonBrightnessUp".action.spawn = [ "light" "-A" "10" ];
        "XF86MonBrightnessDown".action.spawn = [ "light" "-U" "10" ];
        
        # Focus movement with arrow keys
        "Mod+Left".action = focus-column-left;
        "Mod+Right".action = focus-column-right;
        "Mod+Up".action = focus-window-up;
        "Mod+Down".action = focus-window-down;
        
        # Focus movement with vim keys
        "Mod+H".action = focus-column-left;
        "Mod+L".action = focus-column-right;
        "Mod+K".action = focus-window-up;
        "Mod+J".action = focus-window-down;
        
        # Move window with vim keys
        "Mod+Shift+H".action = move-column-left;
        "Mod+Shift+L".action = move-column-right;
        "Mod+Shift+K".action = move-window-up;
        "Mod+Shift+J".action = move-window-down;

        # Workspace switching
        "Mod+1".action.focus-workspace = 1;
        "Mod+2".action.focus-workspace = 2;
        "Mod+3".action.focus-workspace = 3;
        "Mod+4".action.focus-workspace = 4;
        "Mod+5".action.focus-workspace = 5;
        "Mod+6".action.focus-workspace = 6;
        "Mod+7".action.focus-workspace = 7;
        "Mod+8".action.focus-workspace = 8;
        "Mod+9".action.focus-workspace = 9;
        "Mod+0".action.focus-workspace = 10;
        
        # Move window to workspace
        "Mod+Shift+1".action.move-column-to-workspace = 1;
        "Mod+Shift+2".action.move-column-to-workspace = 2;
        "Mod+Shift+3".action.move-column-to-workspace = 3;
        "Mod+Shift+4".action.move-column-to-workspace = 4;
        "Mod+Shift+5".action.move-column-to-workspace = 5;
        "Mod+Shift+6".action.move-column-to-workspace = 6;
        "Mod+Shift+7".action.move-column-to-workspace = 7;
        "Mod+Shift+8".action.move-column-to-workspace = 8;
        "Mod+Shift+9".action.move-column-to-workspace = 9;
        "Mod+Shift+0".action.move-column-to-workspace = 10;
        
        # Workspace scrolling
        "Mod+WheelScrollDown".action = focus-workspace-down;
        "Mod+WheelScrollUp".action = focus-workspace-up;
        
        # Window resizing
        "Mod+Shift+Right".action.set-column-width = "+5%";
        "Mod+Shift+Left".action.set-column-width = "-5%";
      };

      # Cursor configuration
      cursor = {
        theme = "default";
        size = 24;
      };

      # Screenshot path
      screenshot-path = "~/Pictures/Screenshots/screenshot-%Y-%m-%d-%H-%M-%S.png";
    };
  };
}
