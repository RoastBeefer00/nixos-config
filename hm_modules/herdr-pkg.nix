{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
}:
let
  version = "0.9.5";
  sources = {
    aarch64-darwin = {
      url = "https://github.com/herdrdev/herdr/releases/download/v${version}/herdr-macos-aarch64";
      hash = "sha256-+3fCIyoFqANUITgsiUOS9BdOTjihjkivPdApAVfDp+I=";
    };
    x86_64-darwin = {
      url = "https://github.com/herdrdev/herdr/releases/download/v${version}/herdr-macos-x86_64";
      hash = "sha256-X7CpCOx/Z0Xj4kVziwa/rVbEY5HDkas8CVX76tAfE2k=";
    };
    x86_64-linux = {
      url = "https://github.com/herdrdev/herdr/releases/download/v${version}/herdr-linux-x86_64";
      hash = "sha256-FNnovItKngEY13wyJm921GHwm0A0LrI3UpYL2J9Zkp0=";
    };
    aarch64-linux = {
      url = "https://github.com/herdrdev/herdr/releases/download/v${version}/herdr-linux-aarch64";
      hash = "sha256-F9dTby2lCFlSNoDvJ53/ysjkojX05G/o2mwuxEFBiXw=";
    };
  };
  source =
    sources.${stdenv.hostPlatform.system}
      or (throw "herdr: unsupported system ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "herdr";
  inherit version;

  src = fetchurl { inherit (source) url hash; };

  nativeBuildInputs = lib.optionals stdenv.isLinux [ autoPatchelfHook ];
  buildInputs = lib.optionals stdenv.isLinux [ stdenv.cc.cc.lib ];

  dontUnpack = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 $src $out/bin/herdr
    runHook postInstall
  '';

  meta = {
    description = "Agent multiplexer that lives in your terminal";
    homepage = "https://github.com/ogulcancelik/herdr";
    license = lib.licenses.mit;
    mainProgram = "herdr";
    platforms = lib.attrNames sources;
  };
}
