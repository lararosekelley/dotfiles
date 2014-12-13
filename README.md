# osx

*Turn your new Mac into a great development machine*

by Ty-Lucas Kelley

---

This is a list of resources for getting started with a new Apple computer.
I eventually want to automate the whole process, but don't have the time right
now.

### Getting started

Before we begin, note that this tutorial assumes that you're using a computer with
OS X 10.10.

The first thing you should do is install the Xcode command line tools; without
them, not much else is possible. Open up the Terminal application and type this:

    $ xcode-select --install

Follow the instructions in the prompt to continue the installation.

### Zsh

There's nothing wrong with Bash, but Zsh adds a lot of nice features, such as:

* Plugins
* Themes
* Smarter tab-based autocompletion
* Lots of helpful functions

You can install it like this:

    $ curl -L http://install.ohmyz.sh | sh

The next time you open your shell, you'll be greeted with the Zsh prompt. We'll
configure Zsh with nice themes and plugins as well.

### Homebrew

Homebrew bills itself as the "missing package manager" for OS X, but it should
really be called the "necessary" package manager. Were it not for Homebrew, I
would probably leave OS X for Linux. Install it:

    $ ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

Then run the `brew doctor` command and address any issues that it brings up.

Once that's all set, you can start installing a bunch of packages. Install each
package listed here with the `brew install <pkg>` command:

* node
* tmux
* python
* python3
* go
    * After installation: `mkdir -p ~/.go`
* mongodb
    * After installation: `sudo mkdir -p /data/db && sudo chmod 777 /data/db`
* postgresql
* mysql
* rbenv
* ruby-build
* ack
* jq
* wget
* tree
* lynx
* emacs
* heroku-toolbelt
* sl (this one's super important)
* google-app-engine
* app-engine-java-sdk
* caskroom/cask/brew-cask
* vim
    * Install with the `--override-system-vi` flag

### Vim

I like the Pathogen package manager for Vim, so I'm going to show you how to set that up:

    $ mkdir -p ~/.vim/autoload ~/.vim/bundle
    $ curl -LSso ~/.vim/autoload/pathogen.vim https://tpo.pe/pathogen.vim

Install some stuff to make Vim more awesome after that:

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

### Dotfiles

Grab the files from [here](https://github.com/tylucaskelley/start/tree/master/dotfiles)
and put them in your home directory (be sure to add a . before the name):

* aliases: some useful commands
* vimrc: My Vim config file
* zshrc: My Zsh config file
* tmux.conf: Tmux config file

Note that the Vim and Zsh config files assume that you have downloaded Go and properly
set up the Pathogen package manager for Vim (see above)

### Brew Cask

Brew Cask extends Homebrew to allow the installation of large binaries and other Mac applications.
If you ran `caskroom/cask/brew-cask` earlier, you already have it installed. Install
some apps with `brew cask install <pkg>`:

* google-chrome
* atom
* evernote
* appcleaner
* google-drive
* utorrent
* openscad
* openemu
* iterm2
* firefox

Much nicer than dragging icons into your Applications folder, eh?

### Node Modules

If you installed node.js via Homebrew, use `npm install <pkg>` to install these
cool modules:

* yo
* bower
* jshint
* http-server
* csslint
* htmlhint
* grunt-cli
* mocha

### Ruby

If you installed rbenv via Homebrew, install the version you want to use and
replace the system Ruby with it:

    $ rbenv install 2.1.3 # or some other version
    $ rbenv global 2.1.3 # or some other version

Then grab some great gems using `gem install <pkg>`:

* sass
* rails
* sinatra

### Pip Packages

If you installed Python 2 with Homebrew, run `pip install <pkg>` to grab some cool stuff:

* ipython
* licenser
* pep8
* requests
* virtualenv
* jedi
* pillow
* scrapy
* numpy
* closure-linter

### GitHub Atom

While Vim is great, I find that Atom is about as good as a non-command line editor
gets, and I use it often. Copy my `atom/config.cson` file and install these
packages using `apm install <pkg>`:

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

### Misc.

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

You should also grab the Solarizd theme for Mac terminal from the `themes` folder
and use it!
