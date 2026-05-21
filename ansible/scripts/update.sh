#!/bin/zsh

source $HOME/.zshrc

# Update Oh-my-zsh
omz update

# Update brew dependencies
brew update
brew upgrade

# Update code assistants
npm install -g pyright typescript-language-server typescript npm
claude update
