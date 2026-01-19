#!/bin/bash
set -e

# Script to build a portable qutebrowser executable
# Run in Google Cloud Shell (Ubuntu 24.04)

echo "Starting build process for portable qutebrowser..."

# Step 1: Install dependencies
echo "Installing system dependencies..."
sudo apt update
sudo apt install -y --reinstall \
    python3 python3-pip python3-setuptools \
    libqt6webenginecore6 libqt6webenginewidgets6 libqt6webenginecore6-bin \
    qt6-base-dev libqt6widgets6t64 libqt6gui6t64 libqt6core6t64 \
    libqt6network6t64 libqt6dbus6t64 libqt6qml6 libqt6qmlmodels6 \
    libqt6quick6 libqt6quickwidgets6 libqt6webchannel6 \
    libgl1 libglvnd0 libxkbcommon0 libfontconfig1 libx11-6 libxcb1 libwayland-server0 \
    libxext6 libxrender1 libfreetype6 libpng16-16t64 libicu74 \
    libnss3 libnspr4 patchelf libvulkan1 libegl1 libffi8 libudev1 libxcb-cursor0 || { echo "Package installation failed"; exit 1; }

# Step 2: Verify QtWebEngine files
echo "Verifying QtWebEngine files..."
QT6_LIB_DIR=/usr/lib/x86_64-linux-gnu
QT6_LIBEXEC_DIR=/usr/lib/qt6/libexec
QT6_RESOURCE_DIR=/usr/share/qt6/resources
[ -f "$QT6_LIB_DIR/libQt6WebEngineCore.so.6" ] || { echo "Error: libQt6WebEngineCore.so.6 not found"; exit 1; }
[ -f "$QT6_LIB_DIR/libQt6WebEngineWidgets.so.6" ] || { echo "Error: libQt6WebEngineWidgets.so.6 not found"; exit 1; }
[ -f "$QT6_LIBEXEC_DIR/QtWebEngineProcess" ] || { echo "Error: QtWebEngineProcess not found"; exit 1; }
[ -d "$QT6_RESOURCE_DIR" ] || { echo "Error: QtWebEngine resources not found"; exit 1; }
[ -f "$QT6_LIB_DIR/libwayland-server.so.0" ] || { echo "Error: libwayland-server.so.0 not found"; exit 1; }
[ -f "$QT6_LIB_DIR/libvulkan.so.1" ] || { echo "Error: libvulkan.so.1 not found"; exit 1; }
[ -f "$QT6_LIB_DIR/libGL.so.1" ] || { echo "Error: libGL.so.1 not found"; exit 1; }
[ -f "$QT6_LIB_DIR/libEGL.so.1" ] || { echo "Error: libEGL.so.1 not found"; exit 1; }
[ -f "$QT6_LIB_DIR/libX11.so.6" ] || { echo "Error: libX11.so.6 not found"; exit 1; }
[ -f "$QT6_LIB_DIR/libXext.so.6" ] || { echo "Error: libXext.so.6 not found"; exit 1; }
[ -f "$QT6_LIB_DIR/libxcb.so.1" ] || { echo "Error: libxcb.so.1 not found"; exit 1; }
[ -f "$QT6_LIB_DIR/libffi.so.8" ] || { echo "Error: libffi.so.8 not found"; exit 1; }
[ -f "$QT6_LIB_DIR/libudev.so.1" ] || { echo "Error: libudev.so.1 not found"; exit 1; }
[ -f "$QT6_LIB_DIR/libxcb-cursor.so.0" ] || { echo "Error: libxcb-cursor.so.0 not found"; exit 1; }

# Step 3: Install Python dependencies and qutebrowser from main branch
echo "Installing core Python dependencies..."
python3 -m pip install --no-cache-dir --user pyinstaller pyqt6 pyqt6-webengine jinja2 markupsafe pyyaml

echo "Cloning qutebrowser from main branch and installing from source..."
git clone https://github.com/qutebrowser/qutebrowser.git ~/qutebrowser-src
cd ~/qutebrowser-src
python3 -m pip install --no-cache-dir --user .
cd ~

# Step 4: Set up build directory
echo "Setting up build directory..."
BUILD_DIR="${BUILD_DIR:-$HOME/qutebrowser-portable-build}"
STAGING_DIR="$BUILD_DIR/staging/PyQt6/Qt6"
DIST_DIR="$BUILD_DIR/dist/qutebrowser/PyQt6/Qt6"
mkdir -p "$STAGING_DIR/lib" "$STAGING_DIR/libexec" "$STAGING_DIR/resources"
cd "$BUILD_DIR"

# Step 5: Create wrapper script
echo "Creating wrapper script..."
cat > qutebrowser_wrapper.py <<'EOF'
#!/usr/bin/env python3
from qutebrowser import qutebrowser
if __name__ == '__main__':
    qutebrowser.main()
EOF

# Step 6: Copy QtWebEngine files to staging directory
echo "Copying QtWebEngine files to staging..."
QT6_WEBENGINE_CORE_SRC="$(readlink -f "$QT6_LIB_DIR/libQt6WebEngineCore.so.6")"
QT6_WEBENGINE_WIDGETS_SRC="$(readlink -f "$QT6_LIB_DIR/libQt6WebEngineWidgets.so.6")"
QT6_WAYLAND_SRC="$(readlink -f "$QT6_LIB_DIR/libwayland-server.so.0")"
QT6_VULKAN_SRC="$(readlink -f "$QT6_LIB_DIR/libvulkan.so.1")"
QT6_GL_SRC="$(readlink -f "$QT6_LIB_DIR/libGL.so.1")"
QT6_EGL_SRC="$(readlink -f "$QT6_LIB_DIR/libEGL.so.1")"
QT6_X11_SRC="$(readlink -f "$QT6_LIB_DIR/libX11.so.6")"
QT6_XEXT_SRC="$(readlink -f "$QT6_LIB_DIR/libXext.so.6")"
QT6_XCB_SRC="$(readlink -f "$QT6_LIB_DIR/libxcb.so.1")"
QT6_FFI_SRC="$(readlink -f "$QT6_LIB_DIR/libffi.so.8")"
QT6_UDEV_SRC="$(readlink -f "$QT6_LIB_DIR/libudev.so.1")"
QT6_XCB_CURSOR_SRC="$(readlink -f "$QT6_LIB_DIR/libxcb-cursor.so.0")"
QT6_ICUDATA_SRC="$(readlink -f "$QT6_LIB_DIR/libicudata.so.74" || echo "")"
QT6_NSS3_SRC="$(readlink -f "$QT6_LIB_DIR/libnss3.so" || echo "")"
QT6_NSPR4_SRC="$(readlink -f "$QT6_LIB_DIR/libnspr4.so" || echo "")"

cp -v "$QT6_WEBENGINE_CORE_SRC" "$STAGING_DIR/lib/libQt6WebEngineCore.so.6.4.2" || { echo "Failed to copy Qt6WebEngineCore"; exit 1; }
cp -v "$QT6_WEBENGINE_WIDGETS_SRC" "$STAGING_DIR/lib/libQt6WebEngineWidgets.so.6.4.2" || { echo "Failed to copy Qt6WebEngineWidgets"; exit 1; }
cp -v "$QT6_LIBEXEC_DIR/QtWebEngineProcess" "$STAGING_DIR/libexec/" || { echo "Failed to copy QtWebEngineProcess"; exit 1; }
cp -rv "$QT6_RESOURCE_DIR"/* "$STAGING_DIR/resources/" || { echo "Failed to copy resources"; exit 1; }
cp -v "$QT6_WAYLAND_SRC" "$STAGING_DIR/lib/libwayland-server.so.0" || { echo "Failed to copy libwayland-server.so.0"; exit 1; }
cp -v "$QT6_VULKAN_SRC" "$STAGING_DIR/lib/libvulkan.so.1" || echo "Skipping libvulkan"
cp -v "$QT6_GL_SRC" "$STAGING_DIR/lib/libGL.so.1" || echo "Skipping libGL"
cp -v "$QT6_EGL_SRC" "$STAGING_DIR/lib/libEGL.so.1" || echo "Skipping libEGL"
cp -v "$QT6_X11_SRC" "$STAGING_DIR/lib/libX11.so.6" || echo "Skipping libX11"
cp -v "$QT6_XEXT_SRC" "$STAGING_DIR/lib/libXext.so.6" || echo "Skipping libXext"
cp -v "$QT6_XCB_SRC" "$STAGING_DIR/lib/libxcb.so.1" || echo "Skipping libxcb"
cp -v "$QT6_FFI_SRC" "$STAGING_DIR/lib/libffi.so.8" || echo "Skipping libffi"
cp -v "$QT6_UDEV_SRC" "$STAGING_DIR/lib/libudev.so.1" || echo "Skipping libudev"
cp -v "$QT6_XCB_CURSOR_SRC" "$STAGING_DIR/lib/libxcb-cursor.so.0" || { echo "Failed to copy libxcb-cursor.so.0"; exit 1; }
[ -n "$QT6_ICUDATA_SRC" ] && cp -v "$QT6_ICUDATA_SRC" "$STAGING_DIR/lib/libicudata.so.74.2" || echo "Skipping libicudata"
[ -n "$QT6_NSS3_SRC" ] && cp -v "$QT6_NSS3_SRC" "$STAGING_DIR/lib/libnss3.so" || echo "Skipping libnss3"
[ -n "$QT6_NSPR4_SRC" ] && cp -v "$QT6_NSPR4_SRC" "$STAGING_DIR/lib/libnspr4.so" || echo "Skipping libnspr4"

# Create symbolic links in staging
ln -sf "$STAGING_DIR/lib/libQt6WebEngineCore.so.6.4.2" "$STAGING_DIR/lib/libQt6WebEngineCore.so.6" || echo "Failed to create symlink for libQt6WebEngineCore.so.6"
ln -sf "$STAGING_DIR/lib/libQt6WebEngineWidgets.so.6.4.2" "$STAGING_DIR/lib/libQt6WebEngineWidgets.so.6" || echo "Failed to create symlink for libQt6WebEngineWidgets.so.6"
ln -sf "$STAGING_DIR/lib/libicudata.so.74.2" "$STAGING_DIR/lib/libicudata.so.74" || echo "Skipping symlink for libicudata.so.74"

echo "Verifying staged files..."
[ -f "$STAGING_DIR/lib/libQt6WebEngineCore.so.6.4.2" ] || { echo "libQt6WebEngineCore.so.6.4.2 not found"; exit 1; }
[ -f "$STAGING_DIR/lib/libQt6WebEngineWidgets.so.6.4.2" ] || { echo "libQt6WebEngineWidgets.so.6.4.2 not found"; exit 1; }
[ -f "$STAGING_DIR/libexec/QtWebEngineProcess" ] || { echo "QtWebEngineProcess not found"; exit 1; }
[ -d "$STAGING_DIR/resources" ] || { echo "Resources not found"; exit 1; }
[ -f "$STAGING_DIR/lib/libwayland-server.so.0" ] || { echo "libwayland-server.so.0 not found"; exit 1; }
[ -f "$STAGING_DIR/lib/libvulkan.so.1" ] && echo "libvulkan.so.1 found" || echo "libvulkan.so.1 not found"
[ -f "$STAGING_DIR/lib/libGL.so.1" ] && echo "libGL.so.1 found" || echo "libGL.so.1 not found"
[ -f "$STAGING_DIR/lib/libEGL.so.1" ] && echo "libEGL.so.1 found" || echo "libEGL.so.1 not found"
[ -f "$STAGING_DIR/lib/libX11.so.6" ] && echo "libX11.so.6 found" || echo "libX11.so.6 not found"
[ -f "$STAGING_DIR/lib/libXext.so.6" ] && echo "libXext.so.6 found" || echo "libXext.so.6 not found"
[ -f "$STAGING_DIR/lib/libxcb.so.1" ] && echo "libxcb.so.1 found" || echo "libxcb.so.1 not found"
[ -f "$STAGING_DIR/lib/libffi.so.8" ] && echo "libffi.so.8 found" || echo "libffi.so.8 not found"
[ -f "$STAGING_DIR/lib/libudev.so.1" ] && echo "libudev.so.1 found" || echo "libudev.so.1 not found"
[ -f "$STAGING_DIR/lib/libxcb-cursor.so.0" ] || { echo "libxcb-cursor.so.0 not found"; exit 1; }

# Step 7: Run PyInstaller
echo "Running PyInstaller..."
QT6_WEBENGINE_CORE="$STAGING_DIR/lib/libQt6WebEngineCore.so.6.4.2"
QT6_WEBENGINE_WIDGETS="$STAGING_DIR/lib/libQt6WebEngineWidgets.so.6.4.2"
QT6_WAYLAND="$STAGING_DIR/lib/libwayland-server.so.0"
QT6_VULKAN="$STAGING_DIR/lib/libvulkan.so.1"
QT6_GL="$STAGING_DIR/lib/libGL.so.1"
QT6_EGL="$STAGING_DIR/lib/libEGL.so.1"
QT6_X11="$STAGING_DIR/lib/libX11.so.6"
QT6_XEXT="$STAGING_DIR/lib/libXext.so.6"
QT6_XCB="$STAGING_DIR/lib/libxcb.so.1"
QT6_FFI="$STAGING_DIR/lib/libffi.so.8"
QT6_UDEV="$STAGING_DIR/lib/libudev.so.1"
QT6_XCB_CURSOR="$STAGING_DIR/lib/libxcb-cursor.so.0"
QT6_ICUDATA="$STAGING_DIR/lib/libicudata.so.74.2"
QT6_NSS3="$STAGING_DIR/lib/libnss3.so"
QT6_NSPR4="$STAGING_DIR/lib/libnspr4.so"

~/.local/bin/pyinstaller \
    --name qutebrowser \
    --onedir \
    -y \
    --add-data "$(python3 -c 'import PyQt6; print(PyQt6.__path__[0])'):PyQt6" \
    --add-data "$(python3 -c 'import qutebrowser; print(qutebrowser.__path__[0])'):qutebrowser" \
    --add-binary "$QT6_WEBENGINE_CORE:PyQt6/Qt6/lib" \
    --add-binary "$QT6_WEBENGINE_WIDGETS:PyQt6/Qt6/lib" \
    --add-binary "$STAGING_DIR/libexec/QtWebEngineProcess:PyQt6/Qt6/libexec" \
    --add-data "$STAGING_DIR/resources:PyQt6/Qt6/resources" \
    --add-binary "$QT6_WAYLAND:PyQt6/Qt6/lib" \
    --add-binary "$QT6_VULKAN:PyQt6/Qt6/lib" \
    --add-binary "$QT6_GL:PyQt6/Qt6/lib" \
    --add-binary "$QT6_EGL:PyQt6/Qt6/lib" \
    --add-binary "$QT6_X11:PyQt6/Qt6/lib" \
    --add-binary "$QT6_XEXT:PyQt6/Qt6/lib" \
    --add-binary "$QT6_XCB:PyQt6/Qt6/lib" \
    --add-binary "$QT6_FFI:PyQt6/Qt6/lib" \
    --add-binary "$QT6_UDEV:PyQt6/Qt6/lib" \
    --add-binary "$QT6_XCB_CURSOR:PyQt6/Qt6/lib" \
    --add-binary "$QT6_ICUDATA:PyQt6/Qt6/lib" \
    --add-binary "$QT6_NSS3:PyQt6/Qt6/lib" \
    --add-binary "$QT6_NSPR4:PyQt6/Qt6/lib" \
    --add-binary "$(which python3):." \
    --hidden-import PyQt6.QtWebEngineCore \
    --hidden-import PyQt6.QtWebEngineWidgets \
    --hidden-import qutebrowser \
    --hidden-import qutebrowser.__main__ \
    --collect-all qutebrowser \
    --collect-all PyQt6 \
    --log-level DEBUG \
    qutebrowser_wrapper.py > pyinstaller.log 2>&1 || { echo "PyInstaller failed"; cat pyinstaller.log; exit 1; }

# Step 8: Copy QtWebEngine files to dist directory post-PyInstaller
echo "Copying QtWebEngine files to dist post-PyInstaller..."
mkdir -p "$DIST_DIR/lib" "$DIST_DIR/libexec" "$DIST_DIR/resources"
cp -v "$STAGING_DIR/lib/libQt6WebEngineCore.so.6.4.2" "$DIST_DIR/lib/" || { echo "Failed to copy Qt6WebEngineCore to dist"; exit 1; }
cp -v "$STAGING_DIR/lib/libQt6WebEngineWidgets.so.6.4.2" "$DIST_DIR/lib/" || { echo "Failed to copy Qt6WebEngineWidgets to dist"; exit 1; }
cp -v "$STAGING_DIR/libexec/QtWebEngineProcess" "$DIST_DIR/libexec/" || { echo "Failed to copy QtWebEngineProcess to dist"; exit 1; }
cp -rv "$STAGING_DIR/resources"/* "$DIST_DIR/resources/" || { echo "Failed to copy resources to dist"; exit 1; }
cp -v "$STAGING_DIR/lib/libwayland-server.so.0" "$DIST_DIR/lib/" || { echo "Failed to copy libwayland-server.so.0 to dist"; exit 1; }
cp -v "$STAGING_DIR/lib/libvulkan.so.1" "$DIST_DIR/lib/" || echo "Skipping libvulkan"
cp -v "$STAGING_DIR/lib/libGL.so.1" "$DIST_DIR/lib/" || echo "Skipping libGL"
cp -v "$STAGING_DIR/lib/libEGL.so.1" "$DIST_DIR/lib/" || echo "Skipping libEGL"
cp -v "$STAGING_DIR/lib/libX11.so.6" "$DIST_DIR/lib/" || echo "Skipping libX11"
cp -v "$STAGING_DIR/lib/libXext.so.6" "$DIST_DIR/lib/" || echo "Skipping libXext"
cp -v "$STAGING_DIR/lib/libxcb.so.1" "$DIST_DIR/lib/" || echo "Skipping libxcb"
cp -v "$STAGING_DIR/lib/libffi.so.8" "$DIST_DIR/lib/" || echo "Skipping libffi"
cp -v "$STAGING_DIR/lib/libudev.so.1" "$DIST_DIR/lib/" || echo "Skipping libudev"
cp -v "$STAGING_DIR/lib/libxcb-cursor.so.0" "$DIST_DIR/lib/" || { echo "Failed to copy libxcb-cursor.so.0 to dist"; exit 1; }
[ -f "$STAGING_DIR/lib/libicudata.so.74.2" ] && cp -v "$STAGING_DIR/lib/libicudata.so.74.2" "$DIST_DIR/lib/" || echo "Skipping libicudata"
[ -f "$STAGING_DIR/lib/libnss3.so" ] && cp -v "$STAGING_DIR/lib/libnss3.so" "$DIST_DIR/lib/" || echo "Skipping libnss3"
[ -f "$STAGING_DIR/lib/libnspr4.so" ] && cp -v "$STAGING_DIR/lib/libnspr4.so" "$DIST_DIR/lib/" || echo "Skipping libnspr4"
cp -v "$(which python3)" "$DIST_DIR/../python3" || { echo "Failed to copy python3"; exit 1; }

echo "Verifying dist files post-PyInstaller..."
[ -f "$DIST_DIR/lib/libQt6WebEngineCore.so.6.4.2" ] || { echo "libQt6WebEngineCore.so.6.4.2 not found in dist"; exit 1; }
[ -f "$DIST_DIR/lib/libQt6WebEngineWidgets.so.6.4.2" ] || { echo "libQt6WebEngineWidgets.so.6.4.2 not found in dist"; exit 1; }
[ -f "$DIST_DIR/libexec/QtWebEngineProcess" ] || { echo "QtWebEngineProcess not found in dist"; exit 1; }
[ -d "$DIST_DIR/resources" ] || { echo "Resources not found in dist"; exit 1; }
[ -f "$DIST_DIR/lib/libwayland-server.so.0" ] || { echo "libwayland-server.so.0 not found in dist"; exit 1; }
[ -f "$DIST_DIR/lib/libvulkan.so.1" ] && echo "libvulkan.so.1 found in dist" || echo "libvulkan.so.1 not found in dist"
[ -f "$DIST_DIR/lib/libGL.so.1" ] && echo "libGL.so.1 found in dist" || echo "libGL.so.1 not found in dist"
[ -f "$DIST_DIR/lib/libEGL.so.1" ] && echo "libEGL.so.1 found in dist" || echo "libEGL.so.1 not found in dist"
[ -f "$DIST_DIR/lib/libX11.so.6" ] && echo "libX11.so.6 found in dist" || echo "libX11.so.6 not found in dist"
[ -f "$DIST_DIR/lib/libXext.so.6" ] && echo "libXext.so.6 found in dist" || echo "libXext.so.6 not found in dist"
[ -f "$DIST_DIR/lib/libxcb.so.1" ] && echo "libxcb.so.1 found in dist" || echo "libxcb.so.1 not found in dist"
[ -f "$DIST_DIR/lib/libffi.so.8" ] && echo "libffi.so.8 found in dist" || echo "libffi.so.8 not found in dist"
[ -f "$DIST_DIR/lib/libudev.so.1" ] && echo "libudev.so.1 found in dist" || echo "libudev.so.1 not found in dist"
[ -f "$DIST_DIR/lib/libxcb-cursor.so.0" ] || { echo "libxcb-cursor.so.0 not found in dist"; exit 1; }
[ -f "$DIST_DIR/../python3" ] || { echo "Python executable not found in dist"; exit 1; }

# Step 9: Fix RPATH
echo "Fixing RPATH..."
for lib in "$DIST_DIR/lib/libQt6WebEngineCore.so.6.4.2" "$DIST_DIR/lib/libQt6WebEngineWidgets.so.6.4.2" "$DIST_DIR/lib/libicudata.so.74.2" "$DIST_DIR/lib/libnss3.so" "$DIST_DIR/lib/libnspr4.so" "$DIST_DIR/lib/libwayland-server.so.0" "$DIST_DIR/lib/libvulkan.so.1" "$DIST_DIR/lib/libGL.so.1" "$DIST_DIR/lib/libEGL.so.1" "$DIST_DIR/lib/libX11.so.6" "$DIST_DIR/lib/libXext.so.6" "$DIST_DIR/lib/libxcb.so.1" "$DIST_DIR/lib/libffi.so.8" "$DIST_DIR/lib/libudev.so.1" "$DIST_DIR/lib/libxcb-cursor.so.0"; do
    if [ -f "$lib" ]; then
        patchelf --set-rpath '$ORIGIN' "$lib" && echo "Set RPATH for $lib" || { echo "Failed to set RPATH for $lib; continuing"; }
    else
        echo "File $lib not found; skipping RPATH"
    fi
done
if [ -f "$DIST_DIR/libexec/QtWebEngineProcess" ]; then
    patchelf --set-rpath '$ORIGIN/../lib' "$DIST_DIR/libexec/QtWebEngineProcess" && echo "Set RPATH for QtWebEngineProcess" || { echo "Failed to set RPATH for QtWebEngineProcess; continuing"; }
else
    echo "QtWebEngineProcess not found; skipping RPATH"
fi

# Step 10: Verify final bundle
echo "Verifying final bundle..."
[ -f "$DIST_DIR/lib/libQt6WebEngineCore.so.6.4.2" ] || { echo "libQt6WebEngineCore.so.6.4.2 not found"; exit 1; }
[ -f "$DIST_DIR/lib/libQt6WebEngineWidgets.so.6.4.2" ] || { echo "libQt6WebEngineWidgets.so.6.4.2 not found"; exit 1; }
[ -f "$DIST_DIR/libexec/QtWebEngineProcess" ] || { echo "QtWebEngineProcess not found"; exit 1; }
[ -d "$DIST_DIR/resources" ] || { echo "Resources not found"; exit 1; }
[ -f "$DIST_DIR/lib/libwayland-server.so.0" ] || { echo "libwayland-server.so.0 not found"; exit 1; }
[ -f "$DIST_DIR/lib/libvulkan.so.1" ] && echo "libvulkan.so.1 found" || echo "libvulkan.so.1 not found"
[ -f "$DIST_DIR/lib/libGL.so.1" ] && echo "libGL.so.1 found" || echo "libGL.so.1 not found"
[ -f "$DIST_DIR/lib/libEGL.so.1" ] && echo "libEGL.so.1 found" || echo "libEGL.so.1 not found"
[ -f "$DIST_DIR/lib/libX11.so.6" ] && echo "libX11.so.6 found" || echo "libX11.so.6 not found"
[ -f "$DIST_DIR/lib/libXext.so.6" ] && echo "libXext.so.6 found" || echo "libXext.so.6 not found"
[ -f "$DIST_DIR/lib/libxcb.so.1" ] && echo "libxcb.so.1 found" || echo "libxcb.so.1 not found"
[ -f "$DIST_DIR/lib/libffi.so.8" ] && echo "libffi.so.8 found" || echo "libffi.so.8 not found"
[ -f "$DIST_DIR/lib/libudev.so.1" ] && echo "libudev.so.1 found" || echo "libudev.so.1 not found"
[ -f "$DIST_DIR/lib/libxcb-cursor.so.0" ] || { echo "libxcb-cursor.so.0 not found"; exit 1; }
[ -f "$DIST_DIR/../python3" ] || { echo "Python executable not found"; exit 1; }

# Step 11: Package the bundle
echo "Packaging the bundle..."
BUNDLE_DIR="${BUILD_DIR:-$HOME/qutebrowser-portable}"
mkdir -p "$BUNDLE_DIR"
rm -rf "$BUNDLE_DIR/qutebrowser"
mv dist/qutebrowser "$BUNDLE_DIR/qutebrowser"
cd "$BUNDLE_DIR"

# Step 12: Create launch script
echo "Creating launch script..."
cat > launch-qutebrowser.sh <<'EOF'
#!/bin/bash
set -e
USERNAME=${USER:-$(whoami)}
echo "Host username: $USERNAME"
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
if ! cd "$SCRIPT_DIR" 2>/dev/null; then
    echo "Failed to change to $SCRIPT_DIR, using current directory"
    SCRIPT_DIR="$(pwd)"
fi
echo "Working directory set to: $SCRIPT_DIR"
RUNTIME_DIR="$HOME/.run"
if [ ! -d "$RUNTIME_DIR" ]; then
    mkdir -p "$RUNTIME_DIR"
    chmod 700 "$RUNTIME_DIR"
    echo "Created runtime dir: $RUNTIME_DIR"
fi
export XDG_RUNTIME_DIR="$RUNTIME_DIR"
echo "XDG_RUNTIME_DIR set to: $XDG_RUNTIME_DIR"
export QT_QPA_PLATFORM=xcb
echo "QT_QPA_PLATFORM set to: $QT_QPA_PLATFORM"
export QT_QUICK_BACKEND=software
echo "QT_QUICK_BACKEND set to: $QT_QUICK_BACKEND"
export LD_LIBRARY_PATH="$SCRIPT_DIR/qutebrowser/_internal/PyQt6/Qt6/lib:$LD_LIBRARY_PATH"
echo "LD_LIBRARY_PATH: $LD_LIBRARY_PATH"
export QT_LOGGING_RULES="qt5ct.debug=true;qt6ct.debug=true;qt.webenginecontext.debug=true;qt.webengine.debug=true"
echo "QT_LOGGING_RULES: $QT_LOGGING_RULES"
echo "DISPLAY: $DISPLAY"
if [ -z "$DISPLAY" ]; then
    echo "DISPLAY unset—trying :0"
    export DISPLAY=:0
fi
if ! xset q >/dev/null 2>&1; then
    echo "Cannot connect to X server $DISPLAY—run from an X session"
    exit 1
fi
echo "Granting local X11 access..."
xhost +SI:localuser:$USER
xhost
echo "Creating qutebrowser config..."
mkdir -p ~/.config/qutebrowser
cat > ~/.config/qutebrowser/config.py <<'CONFIG'
# config.py for qutebrowser
c.qt.args = ['webEngineArgs=--no-sandbox', 'webEngineArgs=--disable-gpu']
CONFIG
echo "Launching qutebrowser..."
./qutebrowser/qutebrowser --set content.local_content_can_access_file_urls true --debug -l debug --backend webengine
EOF
chmod +x launch-qutebrowser.sh

# Step 13: Archive the bundle
echo "Archiving the bundle..."
cd "$HOME"
tar -czf qutebrowser-portable.tar.gz qutebrowser-portable

# Step 14: Generate SHA256 checksum
echo "Generating SHA256 checksum..."
sha256sum qutebrowser-portable.tar.gz > qutebrowser-portable.tar.gz.sha256
cat qutebrowser-portable.tar.gz.sha256

# Step 15: Clean up
echo "Cleaning up temporary files..."
rm -rf "$BUILD_DIR"

# Step 16: List outputs
echo "Build completed. Outputs:"
ls -l qutebrowser-portable.tar.gz qutebrowser-portable.tar.gz.sha256
echo "Portable bundle directory:"
ls -l qutebrowser-portable

echo "Script execution finished. Download qutebrowser-portable.tar.gz and extract."
