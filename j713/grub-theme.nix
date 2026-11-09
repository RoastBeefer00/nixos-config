# Catppuccin Mocha GRUB theme at 2x for the Air's 2560x1664 panel.
# The upstream theme is laid out in fixed pixels for about 1080p, which is tiny here.
{ catppuccin-grub, dejavu_fonts, grub2, imagemagick, runCommand }:

let
  src = catppuccin-grub.override { flavor = "mocha"; };
in
runCommand "catppuccin-mocha-grub-2x" { nativeBuildInputs = [ grub2 imagemagick ]; } ''
  cp -r ${src} $out
  chmod -R u+w $out
  cd $out
  for f in logo.png select_*.png icons/*.png; do
    magick "$f" -filter Lanczos -resize 200% "$f"
  done
  rm -f font.pf2
  grub-mkfont -s 32 -n "Mocha" -o mocha-32.pf2 ${dejavu_fonts}/share/fonts/truetype/DejaVuSansMono.ttf

  cat > theme.txt <<'EOF'
  title-text: ""
  desktop-image: "background.png"
  desktop-image-scale-method: "stretch"
  desktop-color: "#1E1E2E"
  terminal-font: "Mocha Regular 32"
  terminal-left: "0"
  terminal-top: "0"
  terminal-width: "100%"
  terminal-height: "100%"
  terminal-border: "0"

  + image {
    left = 50%-100
    top = 50%-200
    file = "logo.png"
  }

  + boot_menu {
    left = 50%-560
    top = 55%
    width = 1120
    height = 30%
    item_font = "Mocha Regular 32"
    item_color = "#CDD6F4"
    selected_item_color = "#CDD6F4"
    icon_width = 64
    icon_height = 64
    item_icon_space = 40
    item_height = 72
    item_padding = 10
    item_spacing = 20
    selected_item_pixmap_style = "select_*.png"
  }

  + label {
    top = 88%
    left = 25%
    width = 50%
    align = "center"
    id = "__timeout__"
    text = "Booting in %d seconds"
    font = "Mocha Regular 32"
    color = "#A6ADC8"
  }
  EOF
''
