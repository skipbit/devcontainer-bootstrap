#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# apt で基本パッケージをインストール
sudo apt-get update
sudo apt-get install -y \
    build-essential \
    clangd \
    cmake \
    curl \
    git \
    less \
    locales \
    unzip \
    vim \
    zsh

# ロケールとタイムゾーンの設定
sudo sed -i 's/# ja_JP.UTF-8 UTF-8/ja_JP.UTF-8 UTF-8/' /etc/locale.gen
sudo locale-gen ja_JP.UTF-8
sudo update-locale LANG=ja_JP.UTF-8
sudo ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime
echo 'Asia/Tokyo' | sudo tee /etc/timezone

# Homebrew のインストール（最新バージョンが必要なパッケージ用）
if [ ! -d ~/.homebrew ]; then
    echo "Installing Homebrew..."
    git clone --depth 1 https://github.com/homebrew/brew ~/.homebrew
fi
eval "$(~/.homebrew/bin/brew shellenv)"

# Brewfile から最新バージョンが必要なパッケージをインストール
brew bundle --file="${SCRIPT_DIR}/Brewfile" || true

# fzf のインストール（git clone）
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install --all --no-bash --no-fish --key-bindings --completion --no-update-rc

# Neovim のインストール（GitHub Releases から取得）
NVIM_VERSION="0.11.6"
curl -Lo /tmp/nvim.tar.gz "https://github.com/neovim/neovim/releases/download/v${NVIM_VERSION}/nvim-linux-x86_64.tar.gz"
sudo mkdir -p "/usr/local/bin/nvim-${NVIM_VERSION}"
sudo tar xzf /tmp/nvim.tar.gz -C "/usr/local/bin/nvim-${NVIM_VERSION}" --strip-components=1
sudo ln -sf "/usr/local/bin/nvim-${NVIM_VERSION}/bin/nvim" /usr/local/bin/nvim
rm /tmp/nvim.tar.gz

# Node.js LTS のインストール
export N_PREFIX="$HOME/.n"
export PATH="$N_PREFIX/bin:$PATH"
n lts

# dotfiles のセットアップ
git clone --depth 1 https://github.com/skipbit/dots.git ~/.dots
make -C ~/.dots install

# Neovim headless セットアップ（Lazy, TreeSitter）
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

# ローカル拡張スクリプト（fork 先での個人設定用）
if [ -f "${SCRIPT_DIR}/install.local.sh" ]; then
    # shellcheck source=/dev/null
    source "${SCRIPT_DIR}/install.local.sh"
fi
