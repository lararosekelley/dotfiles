#!/usr/bin/env bash

# php
#
# sets up php environment
# --------

log -v "setting up php..."

brew_install php71 --with-httpd

brew_install composer
