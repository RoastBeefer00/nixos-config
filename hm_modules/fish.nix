{
  config,
  lib,
  pkgs,
  isNixOS ? false,
  isDarwin ? false,
  ...
}:

{
  # 1. CONSOLIDATED ENVIRONMENT VARIABLES
  # These are now set globally and applied to Fish by Home Manager.
  home.sessionVariables = {
    EDITOR = "nvim";
    BUN_INSTALL = "$HOME/.bun";
    WASMER_DIR = "$HOME/.wasmer";
    SKIM_DEFAULT_OPTIONS = "$SKIM_DEFAULT_OPTIONS --color=fg:#cdd6f4,bg:#1e1e2e,matched:#313244,matched_bg:#f2cdcd,current:#cdd6f4,current_bg:#45475a,current_match:#1e1e2e,current_match_bg:#f5e0dc,spinner:#a6e3a1,info:#cba6f7,prompt:#89b4fa,cursor:#f38ba8,selected:#eba0ac,header:#94e2d5,border:#6c7086";
    HELIX_RUNTIME = "$HOME/projects/helix/runtime";
  };

  # 2. CONSOLIDATED PATH ADDITIONS
  # These are applied correctly as Fish paths by Home Manager.
  home.sessionPath = [
    "$HOME/.local/scripts"
    "$HOME/.cargo/bin"
    # Note: BUN_INSTALL is already available as an environment variable
    "$HOME/.bun/bin"
    "$HOME/develop/flutter/bin"
    # "/opt/flutter/bin"
  ];

  # Install required packages
  home.packages = with pkgs; [
    eza # Modern replacement for ls
    # neovim     # Editor
    git # Version control
    starship # Shell prompt
    atuin # Shell history
    # mise       # Runtime version manager
    # Add other packages as needed
  ];

  # Enable Fish shell
  programs.fish = {
    enable = true;

    # 3. DEDICATED KEY BINDING
    # Use the structured 'bindings' option for non-standard key combos.
    # binds = {
    #   # Binds Ctrl+F to execute the tmux sessionizer script.
    #   # Home Manager automatically translates "\cf" or "ctrl-f" into the correct Fish bind syntax.
    #   "ctrl-f".command = "$HOME/.local/scripts/tmux-sessionizer";
    # };

    # Shell aliases (abbreviations in Fish)
    shellAbbrs = {
      ll = "eza -la";
      ls = "eza -a";
      tree = "eza --tree";
      g = "git";
      gst = "git status";
      gco = "git checkout";
      gb = "git branch";
      gl = "git pull";
    }
    // lib.optionalAttrs isNixOS {
      rebuild = "sudo nixos-rebuild switch --flake ~/projects/nixos-config#nixos";
    }
    // lib.optionalAttrs isDarwin {
      rebuild = "sudo darwin-rebuild switch --flake ~/projects/nixos-config";
    };

    # Custom functions
    functions = {
      vim = ''
        if test -z $argv
          nvim .
        else
          nvim $argv
        end
      '';

      dopush = ''
        git add .
        git commit -m $argv
        git push
      '';

      new_branch = ''
        git checkout -b $argv
        git push --set-upstream origin $argv
      '';

      fish_greeting = '''';
    };

    # 4. CLEANED SHELL INITIALIZATION
    # Removed redundant `set -x` and path additions, keeping only necessary external sources/initializers.
    shellInit = ''
      # Enable vi mode
      fish_vi_key_bindings

      # Set cursor shapes for different vi modes (optional)
      set fish_cursor_default block
      set fish_cursor_insert line
      set fish_cursor_replace_one underscore
      set fish_cursor_visual block

      # Source external configurations if they exist
      if test -e "$WASMER_DIR/wasmer.fish"
          source "$WASMER_DIR/wasmer.fish"
      end

      if test -e "$HOME/tmp/google-cloud-sdk/path.fish.inc"
          source "$HOME/tmp/google-cloud-sdk/path.fish.inc"
      end

      if test -e "$HOME/tmp/google-cloud-sdk/completion.fish.inc"
          source "$HOME/tmp/google-cloud-sdk/completion.fish.inc"
      end
    '';
    interactiveShellInit = ''
      bind \cf "$HOME/.local/scripts/tmux-sessionizer"
      # Initialize external tools
      atuin init fish --disable-up-arrow | source
      starship init fish | source
      # mise activate fish | source
    '';
  };

  # Configure Atuin
  programs.atuin = {
    enable = true;
    enableFishIntegration = false;
    # Atuin settings (left empty as the Starship settings were moved)
    settings = { };
  };

  # 5. CORRECTED STARSHIP CONFIGURATION
  # All prompt module settings were moved from programs.atuin.settings to here.
  programs.starship = {
    enable = true;
    enableFishIntegration = false;
    settings = {
      # Character configuration
      character = {
        success_symbol = "[>](bold green)";
        error_symbol = "[x](bold red)";
        vimcmd_symbol = "[<](bold green)";
      };

      # Git configuration
      git_commit = {
        tag_symbol = " tag ";
      };

      git_status = {
        ahead = ">";
        behind = "<";
        diverged = "<>";
        renamed = "r";
        deleted = "x";
      };

      git_branch = {
        symbol = "git ";
      };

      # Cloud and infrastructure
      aws = {
        symbol = "aws ";
      };

      azure = {
        symbol = "az ";
      };

      gcloud = {
        symbol = "gcp ";
      };

      docker_context = {
        symbol = "docker ";
      };

      # Programming languages and runtimes
      bun = {
        symbol = "bun ";
      };

      c = {
        symbol = "C ";
      };

      cobol = {
        symbol = "cobol ";
      };

      crystal = {
        symbol = "cr ";
      };

      dart = {
        symbol = "dart ";
      };

      deno = {
        symbol = "deno ";
      };

      dotnet = {
        symbol = ".NET ";
      };

      elixir = {
        symbol = "exs ";
      };

      elm = {
        symbol = "elm ";
      };

      fennel = {
        symbol = "fnl ";
      };

      gleam = {
        symbol = "gleam ";
      };

      golang = {
        symbol = "go ";
      };

      java = {
        symbol = "java ";
      };

      julia = {
        symbol = "jl ";
      };

      kotlin = {
        symbol = "kt ";
      };

      lua = {
        symbol = "lua ";
      };

      nodejs = {
        symbol = "nodejs ";
      };

      ocaml = {
        symbol = "ml ";
      };

      opa = {
        symbol = "opa ";
      };

      perl = {
        symbol = "pl ";
      };

      php = {
        symbol = "php ";
      };

      purescript = {
        symbol = "purs ";
      };

      python = {
        symbol = "py ";
      };

      quarto = {
        symbol = "quarto ";
      };

      raku = {
        symbol = "raku ";
      };

      ruby = {
        symbol = "rb ";
      };

      rust = {
        symbol = "rs ";
      };

      scala = {
        symbol = "scala ";
      };

      swift = {
        symbol = "swift ";
      };

      typst = {
        symbol = "typst ";
      };

      zig = {
        symbol = "zig ";
      };

      # Build tools and package managers
      cmake = {
        symbol = "cmake ";
      };

      conda = {
        symbol = "conda ";
      };

      gradle = {
        symbol = "gradle ";
      };

      meson = {
        symbol = "meson ";
      };

      package = {
        symbol = "pkg ";
      };

      # Version control systems
      fossil_branch = {
        symbol = "fossil ";
      };

      hg_branch = {
        symbol = "hg ";
      };

      pijul_channel = {
        symbol = "pijul ";
      };

      # Specialized tools
      daml = {
        symbol = "daml ";
      };

      guix_shell = {
        symbol = "guix ";
      };

      memory_usage = {
        symbol = "memory ";
      };

      nats = {
        symbol = "nats ";
      };

      nim = {
        symbol = "nim ";
      };

      nix_shell = {
        symbol = "nix ";
      };

      pulumi = {
        symbol = "pulumi ";
      };

      solidity = {
        symbol = "solidity ";
      };

      spack = {
        symbol = "spack ";
      };

      sudo = {
        symbol = "sudo ";
      };

      terraform = {
        symbol = "terraform ";
      };

      # System configuration
      directory = {
        read_only = " ro";
      };

      status = {
        symbol = "[x](bold red) ";
      };

      # Operating system symbols
      os.symbols = {
        AIX = "aix ";
        Alpaquita = "alq ";
        AlmaLinux = "alma ";
        Alpine = "alp ";
        Amazon = "amz ";
        Android = "andr ";
        Arch = "rch ";
        Artix = "atx ";
        CentOS = "cent ";
        Debian = "deb ";
        DragonFly = "dfbsd ";
        Emscripten = "emsc ";
        EndeavourOS = "ndev ";
        Fedora = "fed ";
        FreeBSD = "fbsd ";
        Garuda = "garu ";
        Gentoo = "gent ";
        HardenedBSD = "hbsd ";
        Illumos = "lum ";
        Kali = "kali ";
        Linux = "lnx ";
        Mabox = "mbox ";
        Macos = "mac ";
        Manjaro = "mjo ";
        Mariner = "mrn ";
        MidnightBSD = "mid ";
        Mint = "mint ";
        NetBSD = "nbsd ";
        NixOS = "nix ";
        OpenBSD = "obsd ";
        OpenCloudOS = "ocos ";
        openEuler = "oeul ";
        openSUSE = "osuse ";
        OracleLinux = "orac ";
        Pop = "pop ";
        Raspbian = "rasp ";
        Redhat = "rhl ";
        RedHatEnterprise = "rhel ";
        RockyLinux = "rky ";
        Redox = "redox ";
        Solus = "sol ";
        SUSE = "suse ";
        Ubuntu = "ubnt ";
        Ultramarine = "ultm ";
        Unknown = "unk ";
        Void = "void ";
        Windows = "win ";
      };
    };
  };
}
