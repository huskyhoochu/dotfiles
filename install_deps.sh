#!/bin/bash

# update pacman
sudo pacman -Syu

# flatpak
sudo pacman -S flatpak

# yay
sudo pacman -S --needed git base-devel && git clone https://aur.archlinux.org/yay-bin.git && cd yay-bin && makepkg -si

# nerd fonts
yay -S ttf-ibmplex-mono-nerd --noconfirm

# zsh
yay -S zsh --noconfirm

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

# golang
yay -S go --noconfirm

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
