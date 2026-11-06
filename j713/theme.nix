# Catppuccin Mocha for what the bar and terminal don't already cover: GTK, Qt, icons and the cursor.
{ pkgs, ... }:
let
  kvantumTheme = "catppuccin-mocha-mauve";
  kvantum = pkgs.catppuccin-kvantum.override { variant = "mocha"; accent = "mauve"; };
in
{
  gtk = {
    enable = true;
    theme = {
      name = "catppuccin-mocha-mauve-standard";
      package = pkgs.catppuccin-gtk.override { variant = "mocha"; accents = [ "mauve" ]; };
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.catppuccin-papirus-folders.override { flavor = "mocha"; accent = "mauve"; };
    };
  };

  home.pointerCursor = {
    enable = true;
    name = "catppuccin-mocha-mauve-cursors";
    package = pkgs.catppuccin-cursors.mochaMauve;
    size = 24;
    gtk.enable = true;
  };

  qt = {
    enable = true;
    platformTheme.name = "kvantum";
    style.name = "kvantum";
  };
  xdg.configFile."Kvantum/kvantum.kvconfig".text = "[General]\ntheme=${kvantumTheme}\n";
  xdg.configFile."Kvantum/${kvantumTheme}".source = "${kvantum}/share/Kvantum/${kvantumTheme}";
}
