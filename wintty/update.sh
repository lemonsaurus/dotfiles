#!/usr/bin/env bash
# Build the latest deblasis/wintty with our patch and icon, and install it on
# the Windows side. Run from WSL. First time on a machine: run install.sh.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UPSTREAM="https://github.com/deblasis/wintty"
BRANCH="windows"

info()  { printf '\033[1;34m=> %s\033[0m\n' "$*"; }
ok()    { printf '\033[1;32m=> %s\033[0m\n' "$*"; }
warn()  { printf '\033[1;33m=> %s\033[0m\n' "$*"; }
error() { printf '\033[1;31m=> %s\033[0m\n' "$*"; exit 1; }

grep -qi microsoft /proc/version 2>/dev/null || error "Wintty builds on the Windows side. Run this from WSL."

LOCALAPPDATA_W="$(cmd.exe /d /c 'echo %LOCALAPPDATA%' 2>/dev/null | tr -d '\r')"
LOCALAPPDATA_L="$(wslpath "$LOCALAPPDATA_W")"
SRC_W="$LOCALAPPDATA_W\\wintty-src"
SRC="$LOCALAPPDATA_L/wintty-src"
APP_W="$LOCALAPPDATA_W\\Programs\\Wintty"
DEPLOY_W="$SRC_W\\.git\\wintty-deploy.ps1"
LOG="$(mktemp -t wintty-build.XXXXXX)"

zig_exe="$(ls -d "$LOCALAPPDATA_L"/Microsoft/WinGet/Packages/zig.zig_*/zig-*/zig.exe 2>/dev/null | sort -V | tail -1 || true)"
[ -n "$zig_exe" ] || error "zig not found. Run install.sh first."
command -v uv &>/dev/null || error "uv not found. Run install.sh first."
TOOLS_PATH="$(wslpath -w "$(dirname "$zig_exe")");C:\\Program Files\\dotnet;C:\\Program Files\\Git\\cmd"

# Run a Windows command in the source tree with the toolchain first on PATH.
win() {
    local cwd="$SRC"
    [ -d "$SRC/.git" ] || cwd="$LOCALAPPDATA_L"
    (cd "$cwd" && cmd.exe /d /c "set PATH=$TOOLS_PATH;%PATH% && $*")
}

# Run a step quietly into $LOG, with a spinner and timer on a terminal.
step() {
    local label="$1"; shift
    local start=$SECONDS frames='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏' i=0 pid
    printf '\n== %s\n' "$label" >>"$LOG"
    "$@" >>"$LOG" 2>&1 &
    pid=$!
    while [ -t 1 ] && kill -0 "$pid" 2>/dev/null; do
        printf '\r\033[1;34m%s\033[0m %s \033[2m%ds\033[0m' "${frames:i++%10:1}" "$label" $((SECONDS - start))
        sleep 0.1
    done
    if wait "$pid"; then
        printf '\r\033[K\033[1;32m✓\033[0m %s \033[2m%ds\033[0m\n' "$label" $((SECONDS - start))
    else
        printf '\r\033[K\033[1;31m✗\033[0m %s\n' "$label"
        tail -n 25 "$LOG"
        error "Full log: $LOG"
    fi
}

fetch() {
    if [ -d "$SRC/.git" ]; then
        win git fetch --quiet origin "$BRANCH"
    else
        win git clone --quiet --filter=blob:none --branch "$BRANCH" "$UPSTREAM" "$SRC_W"
    fi
    win git checkout --quiet --force -B "$BRANCH" "origin/$BRANCH"
}

patch_source() {
    win git apply --3way --whitespace=nowarn - <"$HERE/undecorated.patch"
}

build_core() { win zig build -Dapp-runtime=none -Doptimize=ReleaseFast; }

build_app() {
    win dotnet build windows/Ghostty.sln -nologo -v:q \
        /p:Platform=x64 /p:Configuration=Release /p:RestoreLockedMode=true
}

# Copies the build into Programs\Wintty and points the Start menu at it.
# -WaitForExit holds the copy until every Wintty window is closed.
write_deploy_script() {
    local out out_w
    out="$(ls -d "$SRC"/windows/Ghostty/bin/x64/Release/net*-windows*/ | sort -V | tail -1)"
    out_w="$(wslpath -w "${out%/}")"
    cat >"$SRC/.git/wintty-deploy.ps1" <<EOF
param([switch]\$WaitForExit)
if (\$WaitForExit) { Wait-Process -Name Wintty -ErrorAction SilentlyContinue }
robocopy '$out_w' '$APP_W' /MIR /NFL /NDL /NJH /NJS /NP | Out-Null
if (\$LASTEXITCODE -ge 8) { exit 1 }
\$lnk = (New-Object -ComObject WScript.Shell).CreateShortcut("\$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Wintty.lnk")
\$lnk.TargetPath = '$APP_W\Wintty.exe'
\$lnk.WorkingDirectory = '$APP_W'
\$lnk.Save()
ie4uinit.exe -show
exit 0
EOF
}

deploy_now() { powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$DEPLOY_W"; }

deploy_on_exit() {
    powershell.exe -NoProfile -Command "Start-Process powershell -WindowStyle Hidden -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File','$DEPLOY_W','-WaitForExit'"
}

step "Fetch deblasis/wintty ($BRANCH)" fetch
step "Apply undecorated.patch" patch_source
step "Render icon" uv run --quiet "$HERE/make_icon.py" "$SRC/images/icons"
step "Build libghostty (zig, ReleaseFast)" build_core
step "Build Wintty (dotnet, Release)" build_app
write_deploy_script

if tasklist.exe /FI "IMAGENAME eq Wintty.exe" 2>/dev/null | grep -qi wintty.exe; then
    step "Stage install for when Wintty closes" deploy_on_exit
    warn "Wintty is running. The new build installs itself once every Wintty window is closed."
else
    step "Install to $APP_W" deploy_now
fi

ok "Wintty at $(win git log -1 --pretty=reference | tr -d '\r')"
