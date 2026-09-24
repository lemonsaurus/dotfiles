#!/usr/bin/env bash
# Install the Windows toolchain Wintty builds with, then build and install it.
# Run from WSL. Afterwards, update.sh pulls and rebuilds.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VS_INSTALLER="/mnt/c/Program Files (x86)/Microsoft Visual Studio/Installer"
VS_COMPONENTS="--add Microsoft.VisualStudio.Workload.VCTools --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Component.Windows11SDK.26100"

info()  { printf '\033[1;34m=> %s\033[0m\n' "$*"; }
ok()    { printf '\033[1;32m=> %s\033[0m\n' "$*"; }
warn()  { printf '\033[1;33m=> %s\033[0m\n' "$*"; }
error() { printf '\033[1;31m=> %s\033[0m\n' "$*"; exit 1; }

grep -qi microsoft /proc/version 2>/dev/null || error "Wintty builds on the Windows side. Run this from WSL."

winget() { powershell.exe -NoProfile -Command "winget $*; exit \$LASTEXITCODE"; }

# winget_install <id> <label> [extra winget args]
winget_install() {
    local id="$1" label="$2"; shift 2
    if winget list --id "$id" --exact --accept-source-agreements >/dev/null 2>&1; then
        ok "$label is installed"
    else
        info "Installing $label (watch for a UAC prompt)..."
        winget install --id "$id" --exact --silent --accept-source-agreements --accept-package-agreements "$@" \
            || error "winget could not install $label"
        ok "$label installed"
    fi
}

winget_install Git.Git "Git for Windows"
winget_install zig.zig "Zig"
winget_install Microsoft.DotNet.SDK.10 ".NET 10 SDK"

# libghostty links against MSVC and compiles its DX12 shaders with the
# Windows SDK's dxc.exe, so any Visual Studio 2022 with both will do.
has_msvc() {
    [ -x "$VS_INSTALLER/vswhere.exe" ] && "$VS_INSTALLER/vswhere.exe" -products '*' \
        -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath \
        2>/dev/null | grep -q .
}
has_dxc() { ls "/mnt/c/Program Files (x86)/Windows Kits/10/bin/"*/x64/dxc.exe &>/dev/null; }

if has_msvc && has_dxc; then
    ok "MSVC and the Windows SDK are installed"
elif winget list --id Microsoft.VisualStudio.2022.BuildTools --exact >/dev/null 2>&1; then
    error "VS 2022 Build Tools is missing C++ tools or the Windows 11 SDK. Add both in Visual Studio Installer, then re-run."
else
    info "Installing VS 2022 Build Tools with C++ and the Windows 11 SDK (several GB, watch for a UAC prompt)..."
    winget install --id Microsoft.VisualStudio.2022.BuildTools --exact --accept-source-agreements \
        --accept-package-agreements --override "'--quiet --wait --norestart $VS_COMPONENTS'" \
        || error "winget could not install VS 2022 Build Tools"
    ok "VS 2022 Build Tools installed"
fi

if ! command -v uv &>/dev/null; then
    info "Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.local/bin:$PATH"
fi
ok "uv is installed"

exec "$HERE/update.sh"
