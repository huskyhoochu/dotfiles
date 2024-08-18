#!/bin/bash

# update pacman
sudo pacman -Syu

# flatpak
sudo pacman -S flatpak

# yay
sudo pacman -S --needed git base-devel && git clone https://aur.archlinux.org/yay-bin.git && cd yay-bin && makepkg -si

### locales ###

# noto fonts
yay -S noto-fonts-cjk --noconfirm

# ibus
yay -S ibus ibus-hangul

# nerd fonts
yay -S ttf-ibmplex-mono-nerd --noconfirm

### shell ###

# zsh
yay -S zsh --noconfirm
chsh -s $(which zsh)

# oh-my-posh
yay -S oh-my-posh --noconfirm

# neovim
yay -S neovim --noconfirm

# tmux
yay -S tmux --noconfirm

# bat
yay -S bat --noconfirm

# eza
yay -S eza --noconfirm

# fzf
yay -S fzf --noconfirm

# ripgrep
yay -S ripgrep --noconfirm

# lazygit
yay -S lazygit --noconfirm

# rofi
yay -S rofi --noconfirm

# stow
yay -S stow --noconfirm

### ssh ###
ssh-keygen -t ed25519 -C "dfg1499@gmail.com"
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

### languages ###

# golang
yay -S go --noconfirm

# fnm
curl -fsSL https://fnm.vercel.app/install | bash

# sdkman
curl -s "https://get.sdkman.io" | bash

# pyenv
sudo pacman -S --needed base-devel openssl zlib xz tk
curl https://pyenv.run | bash

### applications ###

# firefox
yay -S firefox-developer-edition --noconfirm

# alacritty
yay -S alacritty --noconfirm

# steam
yay -S steam --noconfirm

# obsidian
yay -S obsidian --noconfirm

# syncthing
yay -S syncthing --noconfirm

# docker desktop
yay -S docker-desktop --noconfirm

# android studio
yay -S android-studio --noconfirm

# vscode
yay -S visual-studio-code-bin --noconfirm

# chrome
yay -S google-chrome --noconfirm
