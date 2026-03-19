#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Homebrew のインストール（~/.homebrew に git clone）
if [ ! -d ~/.homebrew ]; then
    echo "Installing Homebrew..."
    git clone --depth 1 https://github.com/homebrew/brew ~/.homebrew
fi
eval "$(~/.homebrew/bin/brew shellenv)"

# Brewfile からパッケージをインストール
brew bundle --file="${SCRIPT_DIR}/Brewfile"

# dotfiles のセットアップ
git clone --depth 1 https://github.com/skipbit/dots.git ~/.dots
make -C ~/.dots install

# Neovim headless セットアップ（Lazy, Mason, TreeSitter）
nvim --headless \
    "+Lazy! sync" \
    "+TSUpdateSync" \
    "+qa"

# デフォルトシェルを zsh に変更
ZSH_PATH="$(which zsh)"
if [ -n "$ZSH_PATH" ] && [ "$SHELL" != "$ZSH_PATH" ]; then
    grep -qxF "$ZSH_PATH" /etc/shells || echo "$ZSH_PATH" | sudo tee -a /etc/shells
    sudo chsh -s "$ZSH_PATH" "$(whoami)"
fi

git config --global user.email "endo@ai-ms.com"
