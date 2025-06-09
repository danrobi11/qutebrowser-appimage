# Unofficial Qutebrowser Portable Build

## Overview
This project provides a Bash script to build a portable version of [qutebrowser](https://qutebrowser.org/), a keyboard-oriented web browser based on QtWebEngine. The script creates a self-contained binary for 64-bit Ubuntu-based systems, suitable for use on other Linux distributions with minimal dependencies. It supports software rendering as a fallback for systems with disabled or unsupported GPUs, aiming for compatibility across diverse environments.

## Features
- Builds a portable qutebrowser binary with Qt6, FFmpeg, and Widevine CDM for media playback.
- Supports dynamic GPU detection, enabling hardware acceleration when available or falling back to software rendering (using Mesa's `llvmpipe` or SwiftShader).
- Includes debugging tools like `gdb` backtraces for crash diagnostics.
- Configurable via environment variables (`FORCE_SOFTWARE_RENDERING`, `FORCE_SOFTWARE_RENDERING_BACKEND`, `FORCE_MULTI_PROCESS`).
- No X11 dependency (`libx11.so.6`) by default, relying on Xcb for rendering.

## Requirements
- Ubuntu-based system (tested on Ubuntu 24.04) with `sudo` access.
- Approximately 2.5GB of free disk space in `/home`.
- Internet connection for downloading dependencies and Widevine CDM.
- X11 or Wayland display server on the target system.

## Usage
1. **Clone the Repository**:
   ```bash
   git clone https://github.com/yourusername/qutebrowser-portable.git
   cd qutebrowser-portable
   ```

2. **Run the Build Script**:
   ```bash
   chmod +x build_qutebrowser.sh
   ./build_qutebrowser.sh
   ```
   - The script installs dependencies, builds the binary, and creates `qutebrowser-portable.tar.gz`.

3. **Deploy the Binary**:
   - Transfer `qutebrowser-portable.tar.gz` to the target system.
   - Extract and run:
     ```bash
     tar -xzf qutebrowser-portable.tar.gz
     cd qutebrowser-portable
     ./launch-qutebrowser.sh
     ```

4. **Force Software Rendering** (if needed):
   - For systems with disabled GPUs or graphics issues:
     ```bash
     FORCE_SOFTWARE_RENDERING=1 ./launch-qutebrowser.sh
     ```
   - To use SwiftShader instead of `llvmpipe`:
     ```bash
     FORCE_SOFTWARE_RENDERING=1 FORCE_SOFTWARE_RENDERING_BACKEND=swiftshader ./launch-qutebrowser.sh
     ```
   - To enable multi-process mode:
     ```bash
     FORCE_SOFTWARE_RENDERING=1 FORCE_MULTI_PROCESS=1 ./launch-qutebrowser.sh
     ```

5. **Debugging**:
   - Install `gdb` on the target system for detailed crash diagnostics:
     ```bash
     sudo xbps-install -S gdb  # On Void Linux
     sudo apt install gdb     # On Ubuntu
     ```
   - Check `qutebrowser_stderr.log` for crash details after running the launcher.

## Known Issues
- **Local Video Playback**: Local video files (e.g., MP4) do not play due to limitations in the current QtWebEngine configuration.
- **Twitch.tv Streaming**: Live streaming on Twitch.tv is not functional, likely due to similar rendering or codec issues.
- **Software Rendering Crashes**: On some systems with disabled GPUs (e.g., Void Linux), qutebrowser may crash with a `Trace/breakpoint trap` despite software rendering flags. Debugging with `gdb` is recommended to diagnose these crashes.

## Troubleshooting
- **Crash with `Trace/breakpoint trap`**:
  - Ensure `gdb` is installed and check `qutebrowser_stderr.log` for backtraces.
  - Try switching to SwiftShader or multi-process mode (see Usage).
  - Install minimal X11 libraries on the target system:
    ```bash
    sudo xbps-install -S libX11  # On Void Linux
    ```
- **Graphics Issues**:
  - Verify Mesa libraries are present:
    ```bash
    xbps-query -l | grep -E "mesa-dri|libGL|libEGL"
    ```
  - Check for missing dependencies:
    ```bash
    ldd qutebrowser/qutebrowser | grep "not found"
    ```

## Contributing
Contributions are welcome! Please submit issues or pull requests for bug fixes, feature enhancements, or documentation improvements. Focus areas include:
- Resolving local video and Twitch.tv playback issues.
- Improving software rendering stability on minimal systems.
- Enhancing compatibility with non-Ubuntu Linux distributions.

## License
This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

## Acknowledgments
- Thanks to the qutebrowser community for their excellent browser.
- Inspired by the need for a portable, lightweight browser with minimal dependencies.
