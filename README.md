![logo](img/logo.png)

*My automated development setup*

---

### Prerequisites

* Apple computer running macOS Sierra (10.12)

Note that these scripts have previously been tested on OS X 10.10 and 10.11, but
are no longer guaranteed to work on those operating systems.

### Installation

Copy and paste this line into your terminal:

```sh
curl https://raw.githubusercontent.com/tylucaskelley/setup.sh/master/bin/setup.bash -o setup.bash && caffeinate -i bash setup.bash
```

Then, restart `Terminal.app` to see all changes.

Note that you will be prompted for input several times as the script runs.

Also, be sure to read [setup.bash](bin/setup.bash) before running it! It's
broken up into sections and commented, so it's not too tough to scan through
quickly.

### ~/.env

Use the provided `~/.env` file for any sensitive information, such as passwords,
API keys, etc. This file can also be used to override anything I've written.

### Contributing

See [CONTRIBUTING.md](.github/CONTRIBUTING.md) for details.

### Screenshot

![screenshot](https://raw.githubusercontent.com/tylucaskelley/setup.sh/785fc8c360eb7aad0ecc7cb1b1d72032960a2d6d/osx.png)
