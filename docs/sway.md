# Sway

Sway provides very little for us here. To get a functional desktop going, we need a few components.
Assume unless stated otherwise, we're installing packages with `sudo pacman -S <pkg>`

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

### Keybindings

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

The repo tracks a minimal `~/.config/waybar/config.jsonc`: workspaces and mode on the left, the focused window in the middle, and audio, network, battery, clock, and tray on the right. There is no `style.css`, so waybar falls back to its default in `/etc/xdg/waybar`. Like with Sway, `Mod-Shift-C` will also reload Waybar for you as config changes are saved.

## Audio

We'll use [pipewire](https://www.pipewire.org) with [wireplumber](https://pipewire.pages.freedesktop.org/wireplumber/index.html) and [playerctl](https://github.com/altdesktop/playerctl), which ship with CachyOS.

## Screen brightness

[brightnessctl](https://github.com/Hummer12007/brightnessctl) with keys bound via Sway config will do the trick here.

## Lock screen

The natural choice here is [swaylock](https://github.com/swaywm/swaylock).

## Sleep, suspend, and resume

Install [swayidle](https://github.com/swaywm/swayidle)

## Notifications

Install [mako](https://mako-project.org).

## Application launcher

Go with [rofi](https://github.com/davatorium/rofi), which supports Wayland as of 2025. After installing, you can set it as the application launcher for Sway:

```sway
set $menu "rofi -show combi -show-icons -combi-modes window,drun,run,ssh,filebrowser,keys"
```

Optionally, bind Rofi to a set of keys:

```sway
bindsym $mod+p exec $menu
```

## Screenshots

A combination of [grim](https://sr.ht/~emersion/grim), [slurp](https://github.com/emersion/slurp), and [satty](https://satty-org.github.io/Satty) will allow for a standard desktop screenshotting
experience, with support for things like:

- Click and drag to select area
- Annotations via a UI
- etc...

## File manager

## Hardware-specific configuration
