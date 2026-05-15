{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
}:

let
  version = "0.40.0";
  sources = {
    aarch64-darwin = {
      url = "https://github.com/rtk-ai/rtk/releases/download/v${version}/rtk-aarch64-apple-darwin.tar.gz";
      sha256 = "0g1fp0d5d9hda40mvx7gcp8br2l85hpaq5lpz9y3dw7dnhjw7hk0";
    };
    x86_64-darwin = {
      url = "https://github.com/rtk-ai/rtk/releases/download/v${version}/rtk-x86_64-apple-darwin.tar.gz";
      sha256 = "12mr1iil1i8ba80lrl8vyyjpnhp10062z31av9rnj18jp0pm1b4f";
    };
    x86_64-linux = {
      url = "https://github.com/rtk-ai/rtk/releases/download/v${version}/rtk-x86_64-unknown-linux-musl.tar.gz";
      sha256 = "1bzm5vsdbwi88w9yqczsg8lnvlq1pbpv98kdq5mi0x2q8h522pd7";
    };
    aarch64-linux = {
      url = "https://github.com/rtk-ai/rtk/releases/download/v${version}/rtk-aarch64-unknown-linux-gnu.tar.gz";
      sha256 = "00mir4ka2ldc0mrsa6nr31j3a1ayidksql927j1w10m1canqf00x";
    };
  };
  source =
    sources.${stdenv.hostPlatform.system}
      or (throw "rtk: unsupported system ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "rtk";
  inherit version;

  src = fetchurl { inherit (source) url sha256; };

  nativeBuildInputs = lib.optionals stdenv.isLinux [ autoPatchelfHook ];

  sourceRoot = ".";
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 rtk $out/bin/rtk
    runHook postInstall
  '';

  meta = {
    description = "Token optimization proxy for AI coding tools";
    homepage = "https://github.com/rtk-ai/rtk";
    license = lib.licenses.mit;
    mainProgram = "rtk";
    platforms = lib.attrNames sources;
  };
}
