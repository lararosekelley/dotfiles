# osx

*bootstraps an apple computer for development work*

by Ty-Lucas Kelley

---

This repository should serve as a good way to set up a Mac for development.

![osx](https://github.com/tylucaskelley/osx/blob/master/osx.png)

### Prerequisites

* Apple computer running OS X 10.11 (El Capitan)

### Installation

Simply copy and paste this line into your terminal:

```sh
curl https://raw.githubusercontent.com/tylucaskelley/osx/master/osx.sh -o osx.sh && caffeinate -i sh osx.sh
```

Note that you will be prompted for input several times as the script runs. Also,
be sure to read [osx.sh](https://github.com/tylucaskelley/osx/blob/master/osx.sh)
before running it! It's broken up into sections and commented, so it's not too
tough to scan through quickly.

### ~/.env

Use the provided `~/.env` file for any sensitive information, such as passwords,
API keys, etc. This file can also be used to override anything I've written.
