#!/usr/bin/env bash

# Set DNS of 8.8.8.8 before proceeding
sudo networksetup -setdnsservers Wi-Fi 8.8.8.8

##################################
# Install command line dev tools #
##################################
xcode-select -p > /dev/null
if [ $? != 0 ]; then
  # install using the non-gui cmd-line alone
  touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
  softwareupdate -ia
  rm /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
  sudo xcodebuild -license accept || true
fi

#####################
# Turn on FileVault #
#####################
FILEVAULT_STATUS=$(fdesetup status)
if [[ ${FILEVAULT_STATUS} != "FileVault is On." ]]; then
  echo "FileVault is not turned on. Please encrypt your hard disk!"
  exit 1
fi

#################################
# Setup ssh scripts/directories #
#################################
mkdir -p "${HOME}/.ssh"
sudo chmod -R 600 "${HOME}"/.ssh/*

# utility functions
green() {
  printf "\033[1;32m$1\033[0m"
}

red() {
  printf "\033[31m$1\033[0m"
}

yellow() {
  printf "\033[33m$1\033[0m"
}

override_prompt() {
  printf "$(green 'Copying') "$2" : "
  if [ ! -f "$2" ]; then
    echo "" # Dummy echo for new line
    cp "$1" "$2"
  else
    read -p "$(red 'already present'). Should I override [yn]? " yn
    case $yn in
      [Yy]*) cp "$1" "$2" ;;
      [Nn]*) echo "$(yellow 'skipping')";;
    esac
  fi
}

command_exists() {
  type $1 &> /dev/null 2>&1
}

#####################
# Install oh-my-zsh #
#####################
export ZSH=
[ ! -d "${HOME}/.oh-my-zsh" ] && curl -L http://install.ohmyz.sh | sh


shopt -s dotglob #show hidden files
for filepath in files/*; do
    filename=$(basename "$filepath")
    override_prompt "files/${filename}" "${HOME}/${filename}"
done
shopt -u dotglob #reset hidden files setting

##################################
# Install custom plugins for zsh #
##################################
ZSH_CUSTOM=${ZSH_CUSTOM:-${HOME}/.oh-my-zsh/custom}
mkdir -p "${ZSH_CUSTOM}/plugins"
clone_if_not_present() {
  [ ! -d "${ZSH_CUSTOM}/plugins/$(basename $1)" ] && git -C "${ZSH_CUSTOM}/plugins" clone --depth=1 $1
}
# Note: Do not move these into '.brewfile' - since that breaks the linking for omz plugins location
clone_if_not_present https://github.com/zsh-users/zsh-syntax-highlighting
clone_if_not_present https://github.com/zsh-users/zsh-autosuggestions


source "${HOME}/.zshenv"
source "${HOME}/.zprofile"
source "${HOME}/.zshrc"

sudo mkdir -p "${HOMEBREW_PREFIX}/tmp" "${HOMEBREW_PREFIX}/repository" "${HOMEBREW_PREFIX}/plugins" "${HOMEBREW_PREFIX}/bin"
sudo chown -fR "${USERNAME}":admin "${HOMEBREW_PREFIX}"

command_exists brew || bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"