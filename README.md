<p align="center">
  <img src="dotfiles.png" alt="dotfiles" width="100%">
</p>

<p align="center">
  <img src="https://img.shields.io/badge/works_on-my_machine-green?style=flat-square" alt="works on my machine">
  <img src="https://img.shields.io/badge/powered_by-caffeine_and_spite-red?style=flat-square" alt="hopes and dreams">
  <img src="https://img.shields.io/badge/PRs-lol_no-critical?style=flat-square" alt="PRs: lol no">
</p>

Opinionated terminal setup for my personal machines. This is public because there's nothing secret here, but it's built entirely around my own preferences — probably not useful to you unless you're curious or want to steal a color scheme.

## What's in here

- **Starship prompt** config with Catppuccin Mocha theme and powerline-style segments
- **Zsh** config with autosuggestions, syntax highlighting, directory jumping, and aliases for `eza`/`bat`
- **Rio terminal** config and Electron Highlighter color theme (for WSL)

## Quick setup

SSH into any box, run this, and you're home:

```bash
curl -fsSL https://raw.githubusercontent.com/lemonsaurus/dotfiles/main/setup.sh | bash
```

This installs zsh (set as default shell), starship, zsh plugins, eza, and bat, then drops all configs into place. On WSL it also installs the Rio config and theme on the Windows side.

Restart your terminal (or run `zsh`) and you're good to go.

## Font

The starship config expects [MesloLGS Nerd Font](https://github.com/ryanoasis/nerd-fonts/releases/latest). Install it on your host OS — your local terminal handles the font rendering, so remote boxes don't need it.
