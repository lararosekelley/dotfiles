#!/usr/bin/env bash

# ssh
#
# creates an ssh key and adds it to the mac keychain
# --------

log -v "creating the ~/.ssh folder..."

SSH_DIR=~/.ssh

if [ -d "$SSH_DIR" ]; then
    rm -rf "$SSH_DIR"
fi

mkdir -p "$SSH_DIR"
touch "$SSH_DIR"/config

log -v "creating an ssh key in ~/.ssh/id_rsa..."

echo -n "Enter an email address for the key: " && read -r ssh_email

ssh-keygen -t rsa -b 4096 -C "$ssh_email" -f "$SSH_DIR"/id_rsa

eval "$(ssh-agent -s)"
ssh-add "$SSH_DIR"/id_rsa

log -v "adding ssh key to mac keychain..."

cat > "$SSH_DIR"/config << EOL
Host *
    AddKeysToAgent yes
    UseKeychain yes
    IdentityFile ~/.ssh/id_rsa
EOL
