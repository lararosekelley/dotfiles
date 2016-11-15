#!/usr/bin/env bash

# bash_profile
#
# sources .bashrc for mac/linux compatibility
# --------

if [ -f ~/.bashrc ]; then
    # shellcheck disable=SC1090
    source ~/.bashrc
fi
