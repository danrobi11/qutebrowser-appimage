{
  description = "Build and launch qutebrowser v3.5.0 with video, sound, and ALSA support";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
  };

  outputs = { self, nixpkgs, ... }:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs { inherit system; };
    qutebrowserVersion = "3.5.0";

    # Custom qutebrowser derivation
    qutebrowser = pkgs.stdenv.mkDerivation rec {
      pname = "qutebrowser";
      version = qutebrowserVersion;

      src = pkgs.fetchFromGitHub {
        owner = "qutebrowser";
        repo = "qutebrowser";
        rev = "v${version}";
        sha256 = "qa61GRPlrcICgrpIzCVroe7EeAtDC4mp+NYgnAklOYY=";
      };

      nativeBuildInputs = with pkgs; [
        python3
        python3Packages.pip
        python3Packages.setuptools
        python3Packages.wheel
        qt6.qtbase
        qt6.qtwebengine
        qt6.wrapQtAppsHook
        pkg-config
        asciidoc
        libxml2
        libxslt
        curl
        wget
        unzip
      ];

      buildInputs = with pkgs; [
        qt6.qtwebengine
        qt6.qtdeclarative
        python3Packages.pyqt6
        python3Packages.pyqt6-webengine
        python3Packages.jinja2
        python3Packages.pygments
        python3Packages.pyyaml
        python3Packages.attrs
        python3Packages.packaging
        python3Packages.tomli
        python3Packages.importlib-metadata
        ffmpeg
        pulseaudio
        pipewire
        libvpx
        libvorbis
        opusTools
        gst_all_1.gstreamer
        gst_all_1.gst-plugins-base
        gst_all_1.gst-plugins-good
        alsa-lib
        alsa-plugins
        libGL
        libglvnd
        libglvnd.dev
        vulkan-loader
        vulkan-tools
        mesa
        mesa.drivers
        xorg.libX11
        xorg.libXrandr
        xorg.libXcomposite
        xorg.libXdamage
        xorg.libXext
        xorg.libXi
        libxkbcommon
        libdrm
        wayland
        egl-wayland
      ];

      pythonPath = with pkgs.python3Packages; [
        pyqt6
        pyqt6-webengine
        jinja2
        pygments
        pyyaml
        attrs
        packaging
        tomli
        importlib-metadata
      ];

      buildPhase = ''
        export HOME=$TMPDIR
        python3 setup.py build
      '';

      installPhase = ''
        mkdir -p $out
        export HOME=$TMPDIR
        pip install . --prefix=$out --no-deps --no-build-isolation
        # Create a wrapper to run qutebrowser as a module
        mkdir -p $out/bin
        cat > $out/bin/qutebrowser <<EOF
        #!/bin/sh
        export QT_LOGGING_RULES="qt5ct.debug=false;qt6ct.debug=false"
        export QTWEBENGINE_CHROMIUM_FLAGS="--no-sandbox"
        export PYTHONPATH=$out/lib/python3.11/site-packages:${pkgs.lib.concatStringsSep ":" (map (pkg: "${pkg}/lib/python3.11/site-packages") pythonPath)}:$PYTHONPATH
        export QTWEBENGINE_RESOURCES_PATH=${pkgs.qt6.qtwebengine}/resources
        export QTWEBENGINE_DICTIONARIES_PATH=${pkgs.qt6.qtwebengine}/libexec/qtwebengine_dictionaries
        export LC_ALL=C.UTF-8
        export QT_XCB_FORCE_SOFTWARE_OPENGL=1
        export QT_QUICK_BACKEND=software
        exec ${pkgs.python3}/bin/python3 -m qutebrowser "$@"
        EOF
        chmod +x $out/bin/qutebrowser
      '';

      meta = with pkgs.lib; {
        description = "qutebrowser is a keyboard-oriented browser with minimal GUI";
        homepage = "https://qutebrowser.org/";
        license = licenses.gpl3;
        platforms = platforms.linux;
      };
    };

  in {
    packages.${system}.default = qutebrowser;

    apps.${system}.default = {
      type = "app";
      program = "${qutebrowser}/bin/qutebrowser";
    };

    devShells.${system}.default = pkgs.mkShell {
      name = "qutebrowser-dev";
      buildInputs = qutebrowser.buildInputs ++ qutebrowser.nativeBuildInputs;
      shellHook = ''
        export QT_LOGGING_RULES="qt5ct.debug=false;qt6ct.debug=false"
        export QTWEBENGINE_CHROMIUM_FLAGS="--no-sandbox"
        export PATH=${qutebrowser}/bin:$PATH
        export LD_LIBRARY_PATH=${pkgs.lib.makeLibraryPath qutebrowser.buildInputs}:$LD_LIBRARY_PATH
        export PYTHONPATH=${qutebrowser}/lib/python3.11/site-packages:${pkgs.lib.concatStringsSep ":" (map (pkg: "${pkg}/lib/python3.11/site-packages") qutebrowser.pythonPath)}:$PYTHONPATH
        export QTWEBENGINE_RESOURCES_PATH=${pkgs.qt6.qtwebengine}/resources
        export QTWEBENGINE_DICTIONARIES_PATH=${pkgs.qt6.qtwebengine}/libexec/qtwebengine_dictionaries
        export LC_ALL=C.UTF-8
        export QT_XCB_FORCE_SOFTWARE_OPENGL=1
        export QT_QUICK_BACKEND=software
        echo "qutebrowser development environment ready. Run 'qutebrowser' to launch."
      '';
    };
  };
}
