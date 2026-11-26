# Sway

Sway provides very little for us here. To get a functional desktop going, we need a few components.
`chezmoi apply` installs sway and the tools below from
[`scripts/setup/packages.txt`](../scripts/setup/packages.txt), on every machine.
Where this guide names a package, it gives the Arch name.

## Configuring Sway

The config is tracked here, and chezmoi installs it to `~/.config/sway/config`.
Edit the tracked copy and install it in one step with:

```bash
chezmoi edit --apply ~/.config/sway/config
```

### Per-machine settings

The config reads `~/.config/sway/machine.conf` right after its variables. chezmoi writes that file from
`home/dot_config/sway/machine.conf.tmpl`, using the `machine` answer
from `chezmoi init` (`framework`, `thinkpad`, or `desktop`). Put anything that
differs between machines in that template's matching section, such as outputs or
a different `$mod`. Keyboard settings can stay in the shared config: an `input`
block for a device that isn't connected is ignored.

### Wallpaper

### Look

Windows have 2px borders and 6px gaps, both dropped when a workspace holds a single window. Colors come from the [Callie](https://github.com/greylocklabs/themes) theme: the focused window has a pink border. Titles, seen in tabbed and stacked layouts, use IosevkaTerm Nerd Font, which the status bar also needs for its icons.

Dialogs and pop-ups float rather than tile, and a fullscreen window, such as a video, keeps the screen from locking or blanking.

### Keybindings

`$mod+Tab` returns to the last workspace, and `$mod+]` and `$mod+[` step to the next and previous workspace on the current display.

Two scripts in `~/.bin` back the hardware keys:

- `airplane`, on the airplane-mode key (`XF86RFKill`): blocks every radio if any is on, otherwise unblocks them all.
- `display-menu`, on F9 on the Framework (it sends `$mod+p`): a rofi menu of kanshi layouts, mirroring the focused screen with `wl-mirror`, and a gammastep night-light toggle. Its tools come from [`scripts/setup/packages.txt`](../scripts/setup/packages.txt), with the rest of sway's.

### Auto-start programs

## Status bar

> ⚠️Do not trust the sites `waybar.org` or `waybar.net`, only refer to the GitHub repo ⚠️

Install [waybar](https://github.com/Alexays/Waybar) with `pacman`. Use it as the default over `swaybar` by editing `~/.config/sway/config`:

```sway
bar {
    swaybar_command waybar
}
```

This should replace whatever was originally in the `bar {}` block. Hit `Mod-Shift-C` to reload Sway with Waybar in place of the original!

The repo tracks `~/.config/waybar/config.jsonc` and a Callie `style.css`: workspaces, mode, and scratchpad on the left; the clock in the middle, with a calendar on hover; and on the right an idle toggle (stay awake while the eye is open), volume (click to mute), network, CPU, memory, brightness (scroll to change), battery, and the tray. Brightness and battery hide themselves where there is no backlight or battery, and the battery turns yellow below 30% and red below 15%. Icons need IosevkaTerm Nerd Font.

Waybar reapplies `style.css` as soon as it changes; `Mod-Shift-C` reloads the rest.

## Audio

We'll use [pipewire](https://www.pipewire.org) with [wireplumber](https://pipewire.pages.freedesktop.org/wireplumber/index.html) and [playerctl](https://github.com/altdesktop/playerctl), which ship with CachyOS.

## Screen brightness

[brightnessctl](https://github.com/Hummer12007/brightnessctl) with keys bound via Sway config will do the trick here.

## Lock screen

[swaylock](https://github.com/swaywm/swaylock) locks the screen, styled in Callie by `~/.config/swaylock/config`: a ring that turns pink as you type, teal while checking, and red on a wrong password. The config also sets `daemonize`, so `swaylock` returns once the screen is locked, which swayidle's `before-sleep` relies on.

## Sleep, suspend, and resume

[swayidle](https://github.com/swaywm/swayidle) reads `~/.config/swayidle/config`: lock after 5 minutes idle, turn the screens off 5 minutes later, and lock before sleeping. The sway config only starts it.

## Notifications

[mako](https://mako-project.org) shows notifications, styled in Callie by `~/.config/mako/config`. It starts on the first notification, through D-Bus, so the sway config doesn't launch it. Under KDE, Plasma keeps showing notifications instead. Critical notifications have a red border and stay until dismissed.

`$mod+n` runs `dnd`, which toggles do-not-disturb: everything but critical notifications is hidden until it's toggled off.

## Application launcher

[rofi](https://github.com/davatorium/rofi) is the launcher on `$mod+o`, and draws every menu below. `~/.config/rofi/config.rasi` picks the Callie theme in `~/.config/rofi/themes/callie.rasi`, so the launcher and the `~/.bin` menus share one look.

- `$mod+Escape`: `power-menu`, to lock, log out, suspend, reboot, or shut down. Logging out, rebooting, and shutting down ask again first.
- `$mod+v`: clipboard history. [cliphist](https://github.com/sentriz/cliphist) records everything copied, and picking an entry copies it again.
- `$mod+.`: [rofimoji](https://github.com/fdw/rofimoji), which types the chosen emoji into the focused window with `wtype`.

## Screenshots

A combination of [grim](https://sr.ht/~emersion/grim), [slurp](https://github.com/emersion/slurp), and [satty](https://satty-org.github.io/Satty) will allow for a standard desktop screenshotting
experience, with support for things like:

- Click and drag to select area
- Annotations via a UI
- etc...

## File manager

## Hardware-specific configuration
