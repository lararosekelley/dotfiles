# osx

*bootstraps an apple computer for development work*

---

![osx](https://raw.githubusercontent.com/tylucaskelley/osx/785fc8c360eb7aad0ecc7cb1b1d72032960a2d6d/osx.png)

### Prerequisites

* Apple computer running OS X 10.11 (El Capitan)

### Installation

Copy and paste this line into your terminal:

```sh
curl https://raw.githubusercontent.com/tylucaskelley/osx/master/bin/osx.bash -o osx.bash && caffeinate -i bash osx.bash
```

Then, restart `Terminal.app` to see all changes.

Note that you will be prompted for input several times as the script runs.

Also, be sure to read [osx.bash](https://github.com/tylucaskelley/osx/blob/master/bin/osx.bash)
before running it! It's broken up into sections and commented, so it's not too
tough to scan through quickly.

### ~/.env

Use the provided `~/.env` file for any sensitive information, such as passwords,
API keys, etc. This file can also be used to override anything I've written.

### Contributing

See [CONTRIBUTING.md](https://github.com/tylucaskelley/osx/blob/master/.github/CONTRIBUTING.md) for details.
