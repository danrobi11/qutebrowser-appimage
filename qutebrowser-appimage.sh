#!/bin/bash

# qutebrowser-appimage.sh
# Script to build a qutebrowser AppImage with FUSE 3 support
# Date: March 18, 2025

# Exit on any error
set -e

# Define variables
APP="qutebrowser"
VERSION="3.2.0"
WORKDIR="$HOME/appimage-workdir"
APPDIR="$WORKDIR/$APP.AppDir"
OUTPUT="$HOME/$APP-$VERSION-x86_64.AppImage"
LOGFILE="$HOME/qutebrowser-appimage-run.log"

# Clean up previous workdir
[ -d "$WORKDIR" ] && { echo "Cleaning up previous workdir..."; rm -rf "$WORKDIR"; }

# Create workdir and AppDir
mkdir -p "$WORKDIR" "$APPDIR"

# Install system dependencies (Debian-based, including FUSE 3 and additional libs)
echo "Installing system dependencies..."
sudo apt update
sudo apt install -y \
    build-essential git python3 python3-dev python3-pip python3-venv \
    qt6-base-dev qt6-webengine-dev qt6-tools-dev libqt6webenginecore6 libqt6webenginewidgets6 \
    libx11-dev libxext-dev libxkbcommon-dev libgl1-mesa-dev libegl1-mesa-dev \
    libfontconfig1-dev libfreetype-dev libasound2-dev libnss3-dev libglib2.0-dev \
    libpcre2-dev libjpeg-dev libpng-dev libicu-dev libxslt1-dev \
    python3-pyqt6 python3-pyqt6.qtsvg python3-pyqt6.qtwebengine \
    libfuse3-dev libfuse3-3 wget \
    libmysqlclient-dev libqt63drender6 libqt6webview6 libqt63dquickscene2d6 \
    libgl1 libegl1 libopengl0 libglx0 libx11-xcb1 libxcb-glx0 libgbm1 libdrm2 libxcb-dri3-0 libxshmfence1

# Download and install linuxdeployqt
echo "Downloading linuxdeployqt..."
wget -c "https://github.com/probonopd/linuxdeployqt/releases/download/continuous/linuxdeployqt-continuous-x86_64.AppImage" -O "$WORKDIR/linuxdeployqt"
chmod +x "$WORKDIR/linuxdeployqt"

# Download and install appimagetool (FUSE 3 compatible)
echo "Downloading appimagetool (FUSE 3 support)..."
wget -c "https://github.com/AppImage/AppImageKit/releases/download/13/appimagetool-x86_64.AppImage" -O "$WORKDIR/appimagetool"
chmod +x "$WORKDIR/appimagetool"

# Clone qutebrowser source
echo "Cloning qutebrowser source..."
git clone https://github.com/qutebrowser/qutebrowser.git "$WORKDIR/qutebrowser-source"
cd "$WORKDIR/qutebrowser-source"
git checkout "v$VERSION"

# Create and activate a virtual environment
echo "Creating virtual environment..."
python3 -m venv "$WORKDIR/venv"
source "$WORKDIR/venv/bin/activate"

# Install Python dependencies, including setuptools
echo "Installing Python dependencies..."
pip install setuptools
pip install -r requirements.txt -r misc/requirements/requirements-pyqt.txt

# Install qutebrowser into AppDir using pip
echo "Installing qutebrowser into AppDir..."
pip install . --prefix="$APPDIR/usr" --no-deps

# Deactivate the virtual environment
deactivate

# Bundle Python runtime and venv packages
echo "Bundling Python runtime and dependencies..."
cp "$WORKDIR/venv/bin/python3" "$APPDIR/usr/bin/"
cp -r "$WORKDIR/venv/lib/python3.13" "$APPDIR/usr/lib/"

# Bundle additional non-Qt libraries into AppDir
echo "Bundling additional non-Qt libraries..."
mkdir -p "$APPDIR/usr/lib"
cp /usr/lib/x86_64-linux-gnu/libmysqlclient.so.21 "$APPDIR/usr/lib/"
cp /usr/lib/x86_64-linux-gnu/libssl.so.3 "$APPDIR/usr/lib/" || { echo "Failed to copy libssl.so.3"; exit 1; }
cp /usr/lib/x86_64-linux-gnu/libcrypto.so.3 "$APPDIR/usr/lib/" || { echo "Failed to copy libcrypto.so.3"; exit 1; }
cp /usr/lib/x86_64-linux-gnu/libGL.so.1 "$APPDIR/usr/lib/" || { echo "Failed to copy libGL.so.1"; exit 1; }
cp /usr/lib/x86_64-linux-gnu/libEGL.so.1 "$APPDIR/usr/lib/" || { echo "Failed to copy libEGL.so.1"; exit 1; }
cp /usr/lib/x86_64-linux-gnu/libOpenGL.so.0 "$APPDIR/usr/lib/" || { echo "Failed to copy libOpenGL.so.0"; exit 1; }
cp /usr/lib/x86_64-linux-gnu/libGLX.so.0 "$APPDIR/usr/lib/" || { echo "Failed to copy libGLX.so.0"; exit 1; }
cp /usr/lib/x86_64-linux-gnu/libX11-xcb.so.1 "$APPDIR/usr/lib/" || { echo "Failed to copy libX11-xcb.so.1"; exit 1; }
cp /usr/lib/x86_64-linux-gnu/libxcb-glx.so.0 "$APPDIR/usr/lib/" || { echo "Failed to copy libxcb-glx.so.0"; exit 1; }
cp /usr/lib/x86_64-linux-gnu/libgbm.so.1 "$APPDIR/usr/lib/" || { echo "Failed to copy libgbm.so.1"; exit 1; }
cp /usr/lib/x86_64-linux-gnu/libGLdispatch.so.0 "$APPDIR/usr/lib/" || { echo "Failed to copy libGLdispatch.so.0"; exit 1; }
cp /usr/lib/x86_64-linux-gnu/libdrm.so.2 "$APPDIR/usr/lib/" || { echo "Failed to copy libdrm.so.2"; exit 1; }
cp /usr/lib/x86_64-linux-gnu/libxcb-dri3.so.0 "$APPDIR/usr/lib/" || { echo "Failed to copy libxcb-dri3.so.0"; exit 1; }
cp /usr/lib/x86_64-linux-gnu/libxshmfence.so.1 "$APPDIR/usr/lib/" || { echo "Failed to copy libxshmfence.so.1"; exit 1; }

# Exclude optional plugins, keeping only essentials
echo "Excluding optional plugins..."

# Define plugin directory
PLUGIN_DIR="$APPDIR/usr/lib/python3.13/site-packages/PyQt6/Qt6/plugins"

# Keep required plugins: webenginecore, webenginewidgets, libqxcb.so from platforms, libqsqlite.so from sqldrivers, tls, and xcbglintegrations
echo "Preserving essential plugins and removing others..."
mkdir -p "$WORKDIR/plugin-tmp"
for plugin in webenginecore webenginewidgets tls xcbglintegrations; do
    if [ -d "$PLUGIN_DIR/$plugin" ]; then
        cp -r "$PLUGIN_DIR/$plugin" "$WORKDIR/plugin-tmp/"
    fi
done
# Handle platforms directory to keep only libqxcb.so
if [ -d "$PLUGIN_DIR/platforms" ]; then
    mkdir -p "$WORKDIR/plugin-tmp/platforms"
    cp "$PLUGIN_DIR/platforms/libqxcb.so" "$WORKDIR/plugin-tmp/platforms/"
fi
# Handle sqldrivers directory to keep only libqsqlite.so
if [ -d "$PLUGIN_DIR/sqldrivers" ]; then
    mkdir -p "$WORKDIR/plugin-tmp/sqldrivers"
    cp "$PLUGIN_DIR/sqldrivers/libqsqlite.so" "$WORKDIR/plugin-tmp/sqldrivers/"
fi
rm -rf "$PLUGIN_DIR"/*
mv "$WORKDIR/plugin-tmp"/* "$PLUGIN_DIR/"
rm -rf "$WORKDIR/plugin-tmp"

# Check and remove qml directory
QML_DIR="$APPDIR/usr/lib/python3.13/site-packages/PyQt6/Qt6/qml"
echo "Before exclusion: Checking if qml directory exists..."
if [ -d "$QML_DIR" ]; then
    echo "qml directory exists. Contents:"
    ls -l "$QML_DIR"
    rm -rf "$QML_DIR"
    if [ $? -eq 0 ]; then
        echo "Successfully removed qml directory."
    else
        echo "Failed to remove qml directory."
        exit 1
    fi
else
    echo "qml directory does not exist."
fi
echo "After exclusion: Checking if qml directory still exists..."
if [ -d "$QML_DIR" ]; then
    echo "Warning: qml directory still exists after removal attempt!"
    ls -l "$QML_DIR"
    exit 1
else
    echo "qml directory successfully removed."
fi

# Create AppRun script with debug logging
echo "Creating AppRun with debug logging..."
cat << EOF > "$APPDIR/AppRun"
#!/bin/bash
HERE="\$(dirname "\$(readlink -f "\${0}")")"
export PYTHONPATH="\$HERE/usr/lib/python3.13/site-packages:\$PYTHONPATH"
export LD_LIBRARY_PATH="\$HERE/usr/lib:\$HERE/usr/plugins:\$LD_LIBRARY_PATH"
export QT_PLUGIN_PATH="\$HERE/usr/plugins"
export QT_DEBUG_PLUGINS=1
export QUTE_DEBUG=1
exec "\$HERE/usr/bin/python3" "\$HERE/usr/bin/qutebrowser" --debug > "$LOGFILE" 2>&1
EOF
chmod +x "$APPDIR/AppRun"

# Create desktop file
echo "Creating desktop file..."
cat << EOF > "$APPDIR/qutebrowser.desktop"
[Desktop Entry]
Name=Qutebrowser
Exec=qutebrowser
Type=Application
Icon=qutebrowser
Categories=Network;WebBrowser;
EOF

# Copy icon
echo "Copying icon..."
cp "qutebrowser/icons/qutebrowser-64x64.png" "$APPDIR/qutebrowser.png"

# Bundle Qt dependencies with linuxdeployqt, targeting python3 binary
echo "Bundling Qt dependencies..."
"$WORKDIR/linuxdeployqt" "$APPDIR/usr/bin/python3" \
    -qmake=/usr/lib/qt6/bin/qmake \
    -bundle-non-qt-libs \
    -extra-plugins=webenginecore,webenginewidgets,platforms,sqldrivers,tls,xcbglintegrations \
    -unsupported-allow-new-glibc \
    -verbose=2

# Package into AppImage with FUSE 3
echo "Packaging AppImage with FUSE 3 support..."
"$WORKDIR/appimagetool" "$APPDIR" "$OUTPUT"

# Clean up
echo "Cleaning up..."
rm -rf "$WORKDIR"

echo "Done! Your qutebrowser AppImage (FUSE 3 compatible) is at: $OUTPUT"
echo "Run the AppImage and check the debug log at $LOGFILE for detailed output."
