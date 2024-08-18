#!/bin/bash

# Function to print colored output
print_color() {
  COLOR='\033[0;32m'
  NC='\033[0m'
  echo -e "${COLOR}$1${NC}"
}

# Function to print error messages
print_error() {
  COLOR='\033[0;31m'
  NC='\033[0m'
  echo -e "${COLOR}Error: $1${NC}"
}

# Function to check if a command was successful
check_success() {
  if [ $? -ne 0 ]; then
    print_error "$1 failed. Exiting."
    exit 1
  fi
}

# Check for root privileges
if [ "$EUID" -ne 0 ]; then
  print_error "Please run this script as root or with sudo."
  exit 1
fi

# Welcome message
print_color "Welcome to the Arch Linux setup script!"
print_color "This script will set up your system with various tools and applications."
print_color "Please make sure you have a stable internet connection before proceeding."
read -p "Press Enter to continue or Ctrl+C to cancel..."

# Update pacman
print_color "Updating pacman..."
pacman -Syu --noconfirm
check_success "Pacman update"

# Install flatpak
print_color "Installing flatpak..."
pacman -S --noconfirm flatpak
check_success "Flatpak installation"

# Install yay
print_color "Installing yay..."
pacman -S --needed --noconfirm git base-devel
git clone https://aur.archlinux.org/yay-bin.git
cd yay-bin
makepkg -si --noconfirm
cd ..
rm -rf yay-bin
check_success "Yay installation"

# Install fonts and input methods
print_color "Installing fonts and input methods..."
yay -S --noconfirm noto-fonts-cjk ttf-ibmplex-mono-nerd
yay -S --noconfirm ibus ibus-hangul
check_success "Fonts and input methods installation"

# Install shell tools
print_color "Installing shell tools..."
yay -S --noconfirm zsh oh-my-posh neovim tmux bat eza fzf ripgrep lazygit rofi stow
check_success "Shell tools installation"

# Change default shell to zsh
print_color "Changing default shell to zsh..."
chsh -s $(which zsh)
check_success "Shell change"

# Generate SSH key
print_color "Generating SSH key..."
ssh-keygen -t ed25519 -C "dfg1499@gmail.com" -f ~/.ssh/id_ed25519 -N ""
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
check_success "SSH key generation"

# Install programming languages and tools
print_color "Installing programming languages and tools..."
yay -S --noconfirm go
curl -fsSL https://fnm.vercel.app/install | bash
curl -s "https://get.sdkman.io" | bash
pacman -S --noconfirm --needed base-devel openssl zlib xz tk
curl https://pyenv.run | bash
check_success "Programming languages and tools installation"

# Install applications
print_color "Installing applications..."
yay -S --noconfirm firefox-developer-edition alacritty steam obsidian syncthing docker-desktop android-studio visual-studio-code-bin google-chrome
check_success "Applications installation"

# Final message
print_color "Setup complete! Please log out and log back in for all changes to take effect."
print_color "You may need to manually configure some of the installed applications."
print_color "Enjoy your new Arch Linux setup!"
