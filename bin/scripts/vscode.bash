#!/usr/bin/env bash

# vscode
# --------

# sets up the visual studio code editor for development work

PACKAGES=(
    EditorConfig.EditorConfig
    HookyQR.beautify
    cssho.vscode-svgviewer
    dbaeumer.vscode-eslint
    donjayamanne.githistory
    donjayamanne.python
    eg2.tslint
    felixrieseberg.vsc-travis-ci-status
    lukehoban.Go
    mkaufman.HTMLHint
    ms-vscode.cpptools
    ms-vscode.csharp
    msjsdiag.debugger-for-chrome
    rebornix.Ruby
    robertohuertasm.vscode-icons
    xabikos.JavaScriptSnippets
)

log -v "installing & configuring visual studio code..."

brew cask install visual-studio-code

if [ -d ~/.vscode ]; then
    rm -rf ~/.vscode
fi

mkdir -p ~/.vscode

cp "$1"/bin/themes/settings.json "~/Library/Application Support/Code/User/settings.json"

for p in "${PACKAGES[@]}"; do
    code --install-extension "$p"
done
