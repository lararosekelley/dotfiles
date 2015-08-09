# osx

*Turn your Mac into a great development machine*

by Ty-Lucas Kelley

---

This repository should serve as a good way to set up a Mac for development.

### Prerequisites

* Computer running Mac OS X 10.10 (Yosemite)
  * Most things will probably work fine on earlier versions,
    but I'm not making any promises
* NOTE: Be sure to read any file before you download or run it! Safety first :)

### Table of Contents

1. [Xcode Command Line Tools](#1-xcode-command-line-tools)
2. [Zsh](#2-zsh)
3. [Homebrew](#3-homebrew)
4. [Atom](#4-atom)
5. [Vim](#5-vim)
6. [Node](#6-node)
7. [Ruby](#7-ruby)
8. [Python](#8-python)
9. [Dotfiles](#9-dotfiles)
10. [Misc.](#10-misc)

### 1. Xcode Command Line Tools

The first thing you should do is install the Xcode command line tools; without
them, not much else is possible. Open up the Terminal application and type this:

    $ xcode-select --install

Follow the instructions in the prompt to continue the installation.

Then, tell Git who you are:

    $ git config --global user.email "you@example.com"
    $ git config --global user.name "Your Name"
    $ git config --global push.default simple

### 2. Zsh

There's nothing wrong with Bash, but Zsh adds a lot of nice features, such as:

* Plugins
* Themes
* Smarter tab-based autocompletion
* Lots of helpful convenience functions

You can install it like this:

    $ curl -L http://install.ohmyz.sh | sh

The next time you open your shell, you'll be greeted with the Zsh prompt.
We'll customize it later!

### 3. Homebrew

Homebrew bills itself as the "missing" package manager for OS X, but it should
really be called the "necessary" package manager. Install it:

    $ ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

Then run the `brew doctor` command and address any issues that it brings up.

Once that's all set, read the contents of my
[brew.sh](https://github.com/tylucaskelley/osx/blob/master/scripts/brew.sh)
installation script; if you like what you see, run it:

    $ curl -L https://raw.githubusercontent.com/tylucaskelley/osx/master/scripts/brew.sh | sh

Otherwise, install what you want from it!

After installation, do the following to make sure packages like `go` and `mongodb` work right:

    $ sudo mkdir -p /data/db && sudo chmod 777 /data/db # mongodb
    $ mkdir -p ~/.go

Do the same for my
[brew-cask](https://github.com/tylucaskelley/osx/blob/master/scripts/brew.sh) script;
brew cask is like brew but for Mac programs. Here's the install script:

    $ curl -L https://raw.githubusercontent.com/tylucaskelley/osx/master/scripts/brew-cask.sh | sh

### 4. Atom

Atom is a great text editor; it's very similar to Sublime, and seems to have more
momentum going forward. If you installed it via brew cask, copy
[this file](https://github.com/tylucaskelley/osx/blob/master/config.cson) to
your `.atom` folder:

    $ curl -o ~/.atom/config.cson https://raw.githubusercontent.com/tylucaskelley/osx/master/config.cson

And install packages for it with my
[atom.sh](https://github.com/tylucaskelley/osx/blob/master/scripts/atom.sh) script
(after you read it):

    $ curl -L https://raw.githubusercontent.com/tylucaskelley/osx/master/scripts/atom.sh | sh

### 5. Vim

Vim is a nice, extensible command line text editor. I like the Pathogen package
manager for managing extensions, so I'm going to show you how to set that up:

    $ mkdir -p ~/.vim/autoload ~/.vim/bundle
    $ curl -LSso ~/.vim/autoload/pathogen.vim https://tpo.pe/pathogen.vim

Install some stuff to make Vim more awesome after that; check out my
[vim.sh](https://github.com/tylucaskelley/osx/blob/master/scripts/vim.sh)
script and run it if you like what you see:

    $ curl -L https://raw.githubusercontent.com/tylucaskelley/osx/master/scripts/vim.sh | sh

We'll configure vim with a `.vimrc` file later!

### 6. Node

If you installed node.js via Homebrew, use my
[shell script](https://github.com/tylucaskelley/osx/blob/master/scripts/node.sh)
to install some nice packages:

    $ curl -L https://raw.githubusercontent.com/tylucaskelley/osx/master/scripts/node.sh | sh

### 7. Python

If you installed Python via Homebrew, use my
[shell script](https://github.com/tylucaskelley/osx/blob/master/scripts/python.sh)
to install some nice packages:

    $ curl -L https://raw.githubusercontent.com/tylucaskelley/osx/master/scripts/python.sh | sh

### 8. Ruby

If you installed rbenv via Homebrew, install the version you want to use and
replace the system Ruby with it:

    $ rbenv install <version>
    $ rbenv global <version>

Once you do that, use my
[shell script](https://github.com/tylucaskelley/osx/blob/master/scripts/ruby.sh)
to install some nice packages:

    $ curl -L https://raw.githubusercontent.com/tylucaskelley/osx/master/scripts/ruby.sh | sh

### 9. Dotfiles

To make things like Zsh and Vim work nicely, install my dotfiles one at a time:

```bash
$ curl -o ~/.aliases https://raw.githubusercontent.com/tylucaskelley/osx/master/dotfiles/.aliases
$ curl -o ~/.env https://raw.githubusercontent.com/tylucaskelley/osx/master/dotfiles/.env
$ curl -o ~/.functions https://raw.githubusercontent.com/tylucaskelley/osx/master/dotfiles/.functions
$ curl -o ~/.tmux.conf https://raw.githubusercontent.com/tylucaskelley/osx/master/dotfiles/.tmux.conf
$ curl -o ~/.vimrc https://raw.githubusercontent.com/tylucaskelley/osx/master/dotfiles/.vimrc
$ curl -o ~/.zshrc https://raw.githubusercontent.com/tylucaskelley/osx/master/dotfiles/.zshrc
```

### 10. Misc

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
