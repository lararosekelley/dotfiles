# Start

*Turn your new Mac into a great development machine*

by Ty-Lucas Kelley

---

DO NOT USE THIS YET!!! STILL IN EARLY DEVELOPMENT

Start is a collection of scripts that set up your Mac so you can get to work.
Disclaimer: it's based on my development setup, so while I think it's pretty great,
you may not.

Start is *safe*, meaning that if you already have something installed, it won't
overwrite it.

### Dependencies

* OS X Yosemite (10.10)
* [XCode Command Line Tools](http://railsapps.github.io/xcode-command-line-tools.html)

While these scripts will probably work on an older Mac, don't blame me if anything
breaks; I've only tested it on my computer, which runs 10.10. If anyone
does get it working on 10.9 or 10.8, please let me know!

### Installation

**"The works"**

    $ curl -s https://raw.githubusercontent.com/tylucaskelley/start/master/start | sh | tee ~/start-debug.log

**Just the Homebrew stuff (no cask)**

    $ curl -s https://raw.githubusercontent.com/tylucaskelley/start/master/brew | sh | tee ~/start-debug.log

**Just the dotfiles**

    $ curl -s https://raw.githubusercontent.com/tylucaskelley/start/master/dotfiles | sh | tee ~/start-debug.log

All you'll have to do is add in your custom environment variables and
aliases after the install process is complete. The installation process can be
broken down into even smaller bits if you want; take a look at the other scripts
I have and feel free to use those in place of the three I mentioned.

### Just in case...

If an error occurs, it'll show up in `~/start-debug.log`.
Read through that and try to:

* Fix what went wrong
* [Open an issue](https://github.com/tylucaskelley/start/issues/new) so I can look into it

### What happened?

A lot! Start takes your Mac from zero to hero by doing the following:

**Zsh**

Zsh will be set as your default shell! It's nicer than Bash for many reasons that
I won't list here.

**Homebrew**

Homebrew is a great package manager for Mac OS, and I use it here to install:

* git
* Homebrew Cask (see below)
* Programming languages
    * Node.js (and npm)
    * Python 2 and 3 (with pip and pip3)
    * Go
    * Ruby (and rbenv)
* Databases
    * MongoDB
    * PostgreSQL
* Command line tools
    * ack
    * jq
    * wget
    * lynx
    * tree
* Text editors
    * vim (with Pathogen and a few plugins; see "Dotfiles" section)
    * emacs
* Hosting tools
    * Heroku toolbelt
    * Google App Engine (Python SDK)

**Homebrew Cask**

Cask extends Homebrew by allowing the installation of Mac apps and
large binaries like Google Chrome, Evernote, etc. I use it here to install:

* Google Chrome
* Evernote
* Open SCAD
* App Cleaner
* OpenEMU
* Google Drive
* Atom
* uTorrent
* Firefox
* iTerm2

**Dotfiles**

A bunch of dotfiles and folders will get thrown in your `~` directory:

* .zshrc
* .vimrc
* .vim/
    * autoload/
        * pathogen.vim
    * bundle/
        * vim-airline
        * vim-colors-solarized
* .atom/
    * config.cson
* .go/ (this is my $GOPATH)
* .hushlogin
* .aliases (some useful commands)

**GitHub Atom**

Atom is my text editor of choice these days, so I set it up with a bunch of packages:

* autocomplete-paths
* autocomplete-plus
* color-picker
* file-icons
* highlight-line
* language-jade
* linter
* linter-csslint
* linter-htmlhint
* linter-jshint
* linter-pep8
* minimap
* monokai
* seti-syntax
* seti-ui
* travis-ci-status

**Python**

I'll install a bunch of Python 2 packages with pip:

* ipython
* licenser
* pep8
* requests
* virtualenv
* pillow
* scrapy
* numpy

**Node.js**

Lots of npm packages will be installed globally:

* yo
* bower
* jshint
* http-server
* csslint
* htmlhint
* grunt-cli
* mocha

**Ruby**

Here's a list of gems that will be installed:

* sass
* rails
* sinatra

**Misc.**

* Reasonable Mac settings changed
* Solarized theme for Terminal and iTerm2
