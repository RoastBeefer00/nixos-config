{ config, pkgs, ... }:

{
  # Enable Fish shell
  programs.fish = {
    enable = true;
    
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
    
    # Shell initialization
    shellInit = ''
      # Environment variables
      set -x EDITOR nvim
      set -x BUN_INSTALL "$HOME/.bun"
      set -x WASMER_DIR "$HOME/.wasmer"
      
      # Key bindings
      bind ctrl-f "$HOME/.local/scripts/tmux-sessionizer"
      
      # Path additions
      set -x PATH "$HOME/.local/scripts:$PATH"
      set -x PATH "$HOME/.cargo/bin:$PATH"
      set -x PATH "$BUN_INSTALL/bin:$PATH"
      set -x PATH "/opt/flutter/bin:$PATH"
      
      # Source external configurations if they exist
      if test -e "$WASMER_DIR/wasmer.sh"
          source "$WASMER_DIR/wasmer.sh"
      end
      
      if test -e "$HOME/tmp/google-cloud-sdk/path.fish.inc"
          source "$HOME/tmp/google-cloud-sdk/path.fish.inc"
      end
      
      if test -e "$HOME/tmp/google-cloud-sdk/completion.fish.inc"
          source "$HOME/tmp/google-cloud-sdk/completion.fish.inc"
      end
      
      # Initialize external tools
      atuin init fish --disable-up-arrow | source
      starship init fish | source
      # mise activate fish | source
    '';
  };
  
  # Install required packages
  home.packages = with pkgs; [
    eza          # Modern replacement for ls
    # neovim       # Editor
    git          # Version control
    starship     # Shell prompt
    atuin        # Shell history
    # mise         # Runtime version manager
    # Add other packages as needed
  ];
  
  # Configure Starship prompt
  programs.starship = {
    enable = true;
    # Add custom starship configuration here if needed
    enableFishIntegration = true;
  };
  
  # Configure Atuin
  programs.atuin = {
    enable = true;
    enableFishIntegration = true;
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
  
  # Environment variables that should be set globally
  home.sessionVariables = {
    EDITOR = "nvim";
    BUN_INSTALL = "$HOME/.bun";
    WASMER_DIR = "$HOME/.wasmer";
  };
  
  # Add paths to session path
  home.sessionPath = [
    "$HOME/.local/scripts"
    "$HOME/.cargo/bin"
    "$HOME/.bun/bin"
    "/opt/flutter/bin"
  ];
}
