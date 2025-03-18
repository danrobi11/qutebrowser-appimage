# Unofficial Qutebrowser AppImage


[![Build Status](https://img.shields.io/badge/build-passing-brightgreen.svg)](https://github.com/yourusername/qutebrowser-appimage/actions)  
A unofficial portable, self-contained AppImage of [qutebrowser](https://github.com/qutebrowser/qutebrowser), a keyboard-oriented, Vim-like web browser built with QtWebEngine. This project packages qutebrowser v3.2.0 into an AppImage for easy distribution and use on Linux systems, complete with OpenGL rendering and HTTPS support.

## Features
- **Portable**: Run qutebrowser without installation—just download and execute.
- **Vim-like Keybindings**: Navigate the web with keyboard efficiency.
- **Ad-blocking**: Built-in support via the `adblock` library.
- **QtWebEngine**: Powered by Chromium’s engine for modern web compatibility.
- **FUSE 3**: Uses FUSE 3 for AppImage compatibility on newer systems.

## Usage

1. **Download the Unofficial Qutebrowser AppImage**:
   - Grab the latest release from the [Releases page](https://github.com/yourusername/qutebrowser-appimage/releases).
   - Direct link: `qutebrowser-3.2.0-x86_64.AppImage`.

2. **Make it Executable**:
   ```bash
   chmod +x qutebrowser-3.2.0-x86_64.AppImage

## Dependencies for Building Qutebrowser AppImage

To build the `qutebrowser-3.2.0-x86_64.AppImage`, you’ll need the following dependencies installed on a Debian-based system (e.g., Ubuntu). These include system packages for Qt, OpenGL, and other runtime requirements, as well as Python packages for qutebrowser itself.

### System Dependencies (via `apt`)

These are installed using:
```
sudo apt update
sudo apt install -y <packages>

Core Build Tools:
build-essential - Basic compilation tools (gcc, g++, make, etc.)
git - For cloning the qutebrowser repository
python3 - Python 3 runtime
python3-dev - Python 3 development headers
python3-pip - Python package manager
python3-venv - For creating virtual environments

Qt and WebEngine:
qt6-base-dev - Qt 6 base development files
qt6-webengine-dev - Qt 6 WebEngine development files
qt6-tools-dev - Qt 6 tools development files
libqt6webenginecore6 - Qt 6 WebEngine core library
libqt6webenginewidgets6 - Qt 6 WebEngine widgets library
libqt63drender6 - Qt 6 3D rendering library
libqt6webview6 - Qt 6 WebView library
libqt63dquickscene2d6 - Qt 6 3D Quick Scene2D library

OpenGL and Graphics:
libx11-dev - X11 client-side library development files
libxext-dev - X11 extensions library development files
libxkbcommon-dev - XKB common library development files
libgl1-mesa-dev - Mesa OpenGL development files
libegl1-mesa-dev - Mesa EGL development files
libgl1 - Mesa OpenGL runtime library
libegl1 - Mesa EGL runtime library
libopengl0 - OpenGL runtime library
libglx0 - GLX runtime library
libx11-xcb1 - X11-XCB integration library
libxcb-glx0 - XCB GLX extension library
libgbm1 - Generic buffer management library
libdrm2 - Direct Rendering Manager library
libxcb-dri3-0 - XCB DRI3 extension library
libxshmfence1 - X shared memory fence library

Other Libraries:
libfontconfig1-dev - Font configuration library development files
libfreetype-dev - FreeType font library development files
libasound2-dev - ALSA sound library development files
libnss3-dev - Network Security Service library development files
libglib2.0-dev - GLib library development files
libpcre2-dev - PCRE2 regex library development files
libjpeg-dev - JPEG library development files
libpng-dev - PNG library development files
libicu-dev - International Components for Unicode development files
libxslt1-dev - XSLT library development files
libmysqlclient-dev - MySQL client library development files

Python Bindings:
python3-pyqt6 - PyQt6 runtime
python3-pyqt6.qtsvg - PyQt6 SVG module
python3-pyqt6.qtwebengine - PyQt6 WebEngine module
AppImage Tools:
libfuse3-dev - FUSE 3 development files
libfuse3-3 - FUSE 3 runtime library
wget - For downloading tools
Python Dependencies (via pip)
These are installed in a virtual environment using:

python3 -m venv venv
source venv/bin/activate
pip install setuptools
pip install -r requirements.txt -r misc/requirements/requirements-pyqt.txt
From requirements.txt (as of qutebrowser v3.2.0):

jinja2>=3.1 - Templating engine
pyyaml>=6.0 - YAML parser
pygments>=2.18 - Syntax highlighting
colorama>=0.4 - Colored terminal output
adblock>=0.6 - Ad-blocking library
From misc/requirements/requirements-pyqt.txt:

PyQt6>=6.7.0 - Qt 6 bindings for Python
PyQt6-WebEngine>=6.7.0 - WebEngine bindings for PyQt6

Note: Exact versions may vary based on availability in your package index. The script uses >= constraints, so newer compatible versions should work.

Additional Tools
linuxdeployqt: Downloaded from GitHub releases for bundling Qt dependencies.
appimagetool: Downloaded from GitHub releases for packaging the AppImage.

Notes
Ensure your system has Python 3.9 or newer for PyQt6 compatibility.
The build process clones qutebrowser from GitHub and checks out the v3.2.0 tag.
OpenGL support requires all listed graphics libraries to enable GLX/EGL for rendering.
```

Disclaimer

This repository contains a script for building the qutebrowser-3.2.0-x86_64.AppImage.
The script was created with assistance from Grok 3, an AI developed by xAI (https://grok.com).
While efforts have been made to ensure the script functions correctly, it is provided "as is" without any warranties
or guarantees of performance, reliability, or compatibility. Users are responsible for testing and verifying the script's output before use.
Neither the repository owner nor xAI is liable for any issues, damages, or data loss that may arise from using this script or the resulting AppImage.
