{
  stdenv,
  lib,
  fetchFromGitHub,
  cmake,
  pkg-config,
  dtkwidget,
  qt5integration,
  qt5platform-plugins,
  dde-qt-dbus-factory,
  libchardet,
  libuchardet,
  libiconv,
  libsForQt5,
}:

stdenv.mkDerivation rec {
  pname = "deepin-editor";
  version = "6.5.15";

  src = fetchFromGitHub {
    owner = "linuxdeepin";
    repo = pname;
    rev = version;
    hash = "sha256-aMxEESZ/noGtEDpQZz1asR0M+wnAfQT1FXLaQB6B0Zs=";
  };

  nativeBuildInputs = [
    cmake
    pkg-config
    libsForQt5.qttools
    libsForQt5.wrapQtAppsHook
  ];

  buildInputs = [
    dtkwidget
    qt5integration
    qt5platform-plugins
    libsForQt5.qtbase
    libsForQt5.qtsvg
    dde-qt-dbus-factory
    libsForQt5.kcodecs
    libsForQt5.syntax-highlighting
    libchardet
    libuchardet
    libiconv
  ];

  strictDeps = true;

  cmakeFlags = [ "-DVERSION=${version}" ];

  # Fix build with icu4c: "error: parameter declared 'auto'"
  env.NIX_CFLAGS_COMPILE = toString [ "--std=c++17" ];

  meta = {
    description = "Desktop text editor that supports common text editing features";
    homepage = "https://github.com/linuxdeepin/deepin-editor";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
    teams = [ lib.teams.deepin ];
  };
}
