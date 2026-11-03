{
  lib,
  stdenv,
  pkg-config,
  wayland,
  wayland-scanner,
  kdePackages,
}:

stdenv.mkDerivation {
  pname = "kwin-virtual-display";
  version = "0.1.0";

  src = ./.;

  nativeBuildInputs = [
    pkg-config
    wayland-scanner
  ];
  buildInputs = [ wayland ];

  buildPhase = ''
    runHook preBuild
    xml=${kdePackages.plasma-wayland-protocols}/share/plasma-wayland-protocols/zkde-screencast-unstable-v1.xml
    wayland-scanner client-header $xml zkde-screencast-unstable-v1-client-protocol.h
    wayland-scanner private-code $xml zkde-screencast-unstable-v1-protocol.c
    $CC -O2 -Wall -Wextra -o kwin-virtual-display \
      kwin-virtual-display.c zkde-screencast-unstable-v1-protocol.c \
      $(pkg-config --cflags --libs wayland-client)
    runHook postBuild
  '';

  # KWin only grants zkde_screencast_unstable_v1 to executables listed in a
  # .desktop file with this key; NoDisplay keeps it out of app menus.
  installPhase = ''
    runHook preInstall
    install -Dm755 kwin-virtual-display $out/bin/kwin-virtual-display
    install -Dm644 /dev/stdin $out/share/applications/kwin-virtual-display.desktop <<EOF
    [Desktop Entry]
    Type=Application
    Name=KWin Virtual Display
    Exec=$out/bin/kwin-virtual-display
    NoDisplay=true
    X-KDE-Wayland-Interfaces=zkde_screencast_unstable_v1
    EOF
    runHook postInstall
  '';

  meta = {
    description = "Create a headless KWin virtual output for game streaming";
    platforms = lib.platforms.linux;
    mainProgram = "kwin-virtual-display";
  };
}
