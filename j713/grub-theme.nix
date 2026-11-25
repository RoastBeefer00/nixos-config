# GRUB theme matching the Plymouth splash: black, with the white NixOS snowflake centred.
# Laid out for the Air's 2560x1664 panel.
{ nixos-icons, dejavu_fonts, grub2, imagemagick, runCommand }:

runCommand "black-nixos-grub" { nativeBuildInputs = [ grub2 imagemagick ]; } ''
  mkdir -p $out
  cd $out
  magick ${nixos-icons}/share/icons/hicolor/256x256/apps/nix-snowflake-white.png PNG32:logo.png
  magick -size 16x16 xc:black PNG32:background.png
  # Selection bar: a dark grey box, as all nine pieces GRUB's styled box expects. 1px pieces, since the edges add to the row's height. Plain RGBA PNGs: GRUB's loader is picky.
  for p in c n ne e se s sw w nw; do magick -size 1x1 xc:'#262626' PNG32:select_$p.png; done
  grub-mkfont -s 32 -n "Mono" -o mono-32.pf2 ${dejavu_fonts}/share/fonts/truetype/DejaVuSansMono.ttf

  cat > theme.txt <<'EOF'
  title-text: ""
  desktop-image: "background.png"
  desktop-image-scale-method: "stretch"
  desktop-color: "#000000"
  terminal-font: "Mono Regular 32"
  terminal-left: "0"
  terminal-top: "0"
  terminal-width: "100%"
  terminal-height: "100%"
  terminal-border: "0"

  + image {
    left = 50%-128
    top = 50%-128
    file = "logo.png"
  }

  + boot_menu {
    left = 50%-560
    top = 62%
    width = 1120
    height = 28%
    item_font = "Mono Regular 32"
    item_color = "#808080"
    selected_item_color = "#FFFFFF"
    item_height = 72
    item_padding = 20
    item_spacing = 10
    selected_item_pixmap_style = "select_*.png"
  }

  + label {
    top = 93%
    left = 25%
    width = 50%
    align = "center"
    id = "__timeout__"
    text = "Booting in %d seconds"
    font = "Mono Regular 32"
    color = "#808080"
  }
  EOF
''
