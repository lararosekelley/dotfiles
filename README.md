# osx

*Turn your new Mac into a great development machine*

by Ty-Lucas Kelley

---

This is a list of resources for setting up a new Apple computer.

### 0. Getting started

Before we begin, note that this tutorial assumes that you're using a computer with
OS X 10.10 (Yosemite).

The first thing you should do is install the Xcode command line tools; without
them, not much else is possible. Open up the Terminal application and type this:

    $ xcode-select --install

Follow the instructions in the prompt to continue the installation.

### 1. Zsh

There's nothing wrong with Bash, but Zsh adds a lot of nice features, such as:

* Plugins
* Themes
* Smarter tab-based autocompletion
* Lots of helpful functions

You can install it like this:

    $ curl -L http://install.ohmyz.sh | sh

The next time you open your shell, you'll be greeted with the Zsh prompt. Download
my theme for it:

`curl -o ~/.oh-my-zsh/themes/tlk.zsh-theme https://raw.githubusercontent.com/tylucaskelley/osx/master/themes/tlk.zsh-theme`

### 2. Homebrew and Brew Cask

Homebrew bills itself as the "missing" package manager for OS X, but it should
really be called the "necessary" package manager. Install it:

    $ ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

Then run the `brew doctor` command and address any issues that it brings up.

Once that's all set, you can start installing a bunch of packages. Install each
package listed here with the `brew install <pkg>` command:

* ack
* android-platform-tools
* autojump
* caskroom/cask/brew-cask
* curl
* elasticsearch
* emacs
* git
* go (after install: 'mkdir -p ~/.go')
* go-app-engine-64
* gradle
* heroku-toolbelt
* hugo
* jq
* libffi
* libxml2
* lua
* lynx
* mercurial
* mongodb (after install: 'sudo mkdir -p /data/db && sudo chmod 777 /data/db')
* mysql
* n
* ngrok
* node
* openssl
* postgresql
* python
* python3
* rbenv
* ruby-build
* sbt
* scala
* sl
* sqlite
* tmux
* tree
* vim --with-lua --override-system-vi
* wget
* xz

Brew Cask extends Homebrew to allow the installation of large binaries and other Mac applications.
If you ran `caskroom/cask/brew-cask` earlier, you already have it installed. Install
some apps with `brew cask install <pkg>`:

* android-studio
* appcleaner
* arduino
* atom
* firefox
* font-lato
* font-roboto
* font-inconsolata
* gimp
* github
* google-chrome
* google-drive
* intellij-idea-ce
* iterm2
* java
* openemu
* openscad
* sketch
* slack
* steam
* unity
* utorrent
* vagrant
* virtualbox

### 3. Vim

Vim is a nice, extensible command line text editor. I like the Pathogen package
manager for managing extensions, so I'm going to show you how to set that up:

    $ mkdir -p ~/.vim/autoload ~/.vim/bundle
    $ curl -LSso ~/.vim/autoload/pathogen.vim https://tpo.pe/pathogen.vim

Install some stuff to make Vim more awesome after that:

* [Badwolf Theme](https://github.com/sjl/badwolf)
    * `git clone https://github.com/sjl/badwolf ~/.vim/bundle/badwolf`
* [Vim Airline](https://github.com/bling/vim-airline)
    * `git clone https://github.com/bling/vim-airline ~/.vim/bundle/vim-airline`
* [Solarized Theme](http://ethanschoonover.com/solarized/vim-colors-solarized)
    * `git clone git://github.com/altercation/vim-colors-solarized.git ~/.vim/bundle/vim-colors-solarized`
* [Jedi Completion](https://github.com/davidhalter/jedi-vim)
    * `git clone --recursive https://github.com/davidhalter/jedi-vim.git ~/.vim/bundle/jedi-vim`
    * Note that you need to run `pip install jedi` for this plugin to work
* [Neocomplete](https://github.com/Shougo/neocomplete.vim)
    * `git clone https://github.com/Shougo/neocomplete.vim.git ~/.vim/bundle/neocomplete`
* [Supertab](https://github.com/ervandew/supertab)
    * `git clone https://github.com/ervandew/supertab ~/.vim/bundle/supertab`
* [Nerdtree](https://github.com/scrooloose/nerdtree.git)
    * `git clone https://github.com/scrooloose/nerdtree.git ~/.vim/bundle/nerdtree`
* [Syntastic](https://github.com/scrooloose/syntastic)
    * `git clone https://github.com/scrooloose/syntastic.git ~/.vim/bundle/syntastic`
* [Tomorrow Theme](https://github.com/d11wtq/tomorrow-theme-vim)
    * `git clone https://github.com/d11wtq/tomorrow-theme-vim ~/.vim/bundle/tomorrow-theme-vim`

### 4. Node

If you installed node.js via Homebrew, use `npm install -g <pkg>` to install these
cool modules:

* bower
* csslint
* generator-angular
* generator-express
* generator-chrome-extension
* grunt-cli
* htmlhint
* http-server
* jquery-seed
* jshint
* mocha
* nodemon
* npm-check-updates
* yo

### 5. Python

If you installed Python 2 with Homebrew, run `pip install <pkg>` to grab a few
cool tools:

* closure-linter
* ipython
* jedi
* licenser
* pep8
* uncommitted

### 6. Ruby

If you installed rbenv via Homebrew, install the version you want to use and
replace the system Ruby with it:

    $ rbenv install <version>
    $ rbenv global <version>

Then grab some great gems using `gem install <pkg>`:

* jekyll
* rails
* sass
* sinatra

### 7. Dotfiles

Grab the files from [here](https://github.com/tylucaskelley/start/tree/master/dotfiles)
and put them in your home directory (be sure to add a . before the name):

* aliases: some useful commands
* vimrc: My Vim config file
* zshrc: My Zsh config file
* tmux.conf: Tmux config file

Note that the Vim and Zsh config files assume that you have:

* Downloaded Go and set up the `~/.go` directory
* Installed my Zsh theme from the `themes` folder
* Properly set up Vim with the Pathogen package manager
* Installed rbenv and ruby-build

### 8. Misc.

To silence annoying "Last Login" prompts when you open a shell, do this:

```bash
    $ touch ~/.hushlogin
```

Create an SSH key to use with services like GitHub:

```bash
    $ ssh-keygen -t rsa -C "your_email@example.com"
    $ eval "$(ssh-agent -s)"
    $ ssh-add ~/.ssh/id_rsa
    $ pbcopy < ~/.ssh/id_rsa.pub # paste the key when you need to
```

You should also check out the themes for Terminal in the `themes` folder!
