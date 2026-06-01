{ config, pkgs, ... }:
{
  services.mako = {
    enable = true;
    # background-color, text-color, border-color handled by Stylix
    extraConfig = ''
      progress-color=over #${config.lib.stylix.colors.base02}

      [urgency=high]
      border-color=#${config.lib.stylix.colors.base09}
    '';
  };
}
