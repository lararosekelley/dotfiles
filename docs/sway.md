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

The config ends by reading `~/.config/sway/session.conf`, written from
`session.conf.tmpl`: what sway sets up when it is the whole session. That is the
distro's session setup in `/etc/sway/config.d` (the graphical session target,
and the environment the portals and user services need), a polkit agent to
answer apps that ask for your password (KDE's on Fedora, `polkit-gnome` on
Arch), `dex`, which starts the desktop's autostart apps such as Dropbox and
KDE Connect, since sway doesn't, and recoll's indexer. The repo hides CachyOS
Hello's autostart entry, which CachyOS copies into new homes, so the welcome
screen doesn't open at every login.

### Startup windows

When sway starts as the whole session, `session.conf` runs `sway-startup` in
`~/.bin`, which opens kitty windows in a fixed layout: on workspace 1, the
Callie calendar (`callie tui`) in a full-height column on the left, and on the
right fastfetch above the cliamp music player; on workspace 2, Neovim.
`sway-nested` leaves it out. It opens each window only once the one before it
has appeared, since sway places a new window beside the focused one. A program
that isn't installed gets a plain shell in its place, a window stays open at a
shell when its program exits, and a window that never appears is reported
while the rest still open. Edit the script to change the layout.

### Dark mode and night light

When sway is the whole session, `session.conf` sets GTK's `color-scheme` to
`prefer-dark`, which GTK 4 apps follow and the portal passes on to Flatpaks and
browsers. On machines without KDE, it also sets the GTK 3 theme to Adwaita's
dark variant; on KDE machines Plasma themes GTK apps itself.

The night light, [gammastep](https://gitlab.com/chinstrap/gammastep), starts at
login. `~/.config/gammastep/config.ini` sets it to warm the screen to 3600K
between dusk (19:00 to 20:30) and dawn (06:30 to 07:30), fading in and out,
with fixed times rather than a location. `night-light` in `~/.bin` controls it:
the moon or sun in waybar shows whether it's on, a click toggles it, and a
right-click opens the config and restarts it with any changes. `$mod+Shift+n`
also toggles it, as does the display menu.

### Sway on the desktop

On the desktop, choose Sway instead of Plasma at the login screen for a full
sway session, with the same config as the laptops and the ultrawide set up in
`machine.conf`.

To run sway in a window inside KDE instead, use `sway-nested`. It runs
`~/.config/sway/nested.conf`, which chezmoi makes from the config with `$mod` set
to Alt, since Plasma keeps most Super shortcuts, and without `session.conf`,
since Plasma already set up the session. Plain `sway` there would take the
session over, and quitting it would end the Plasma session too.

Under sway, Chrome may look for saved passwords in the GNOME keyring rather
than KDE Wallet, so they seem missing. Start it with
`--password-store=kwallet6` to keep using the wallet.

### Wallpaper

The wallpaper is `pond`, installed with the dotfiles to `~/.local/share/wallpapers`. The config sets `$wallpaper` to `pond.jpg` (3440x1440), and each laptop's section of `machine.conf.tmpl` switches it to `pond-laptop.jpg` (2560x1600, the laptops' 16:10). Both are JPEGs, to keep the repo small, with a 40% wash of Callie's background color (`#1c1220`) baked in so the painting sits with the rest of the theme. To remake one from its original PNG:

```bash
magick pond.png -alpha off \( +clone -fill '#1c1220' -colorize 100 -alpha set \
  -channel A -evaluate set 40% +channel \) -composite -strip -quality 92 \
  -sampling-factor 4:4:4 pond.jpg
```

### Look

Windows have 2px borders and 8px gaps (4px at the screen edges), both dropped when a workspace holds a single window. Colors come from the [Callie](https://github.com/greylocklabs/themes) theme: the focused window has a pink border. Titles, seen in tabbed and stacked layouts, use IosevkaTerm Nerd Font, which the status bar also needs for its icons.

Dialogs and pop-ups float rather than tile, and a fullscreen window, such as a video, keeps the screen from locking or blanking.

### Keybindings

`$mod+/` lists every key binding, with the comment above it in the config and its command. `sway-keys` in `~/.bin` builds the list from the installed config each time it opens, so it follows `machine.conf` and any binding added later. `sway-keys --print` writes the same list to a terminal. Because the comments double as the list's descriptions, write each binding's comment for someone reading the list.

`$mod+Shift+Space` and `$mod+Alt+Space` float or tile the focused window (`sway-nested` keeps only the first, since its `$mod` is Alt). `$mod+Tab` returns to the last workspace, and `$mod+]` and `$mod+[` step to the next and previous workspace on the current display. On a touchpad, swiping three fingers left or right does the same, through sway's `bindgesture`. Swiping four fingers up shows the next scratchpad window, like `$mod+x`, and four fingers down floats or tiles the focused window, like `$mod+Shift+Space`. The `$mod+/` list includes gestures too.

`$mod+b` opens the default web browser, whichever `xdg-settings get default-web-browser` names. `$mod+e` opens Neovim in a terminal. `$mod+c` opens the Callie calendar's TUI (`callie tui`) and `$mod+m` the cliamp music player, each in a terminal like any other window. Callie is only installed on Fedora for now.

Two scripts in `~/.bin` back the hardware keys:

- `airplane`, on the airplane-mode key (`XF86RFKill`): blocks every radio if any is on, otherwise unblocks them all, then shows a notification. A press can reach it twice, or after the kernel or firmware has already toggled the radios, so it ignores a second run at the same moment and leaves a change that happens on its own in the first half second.
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

The repo tracks `~/.config/waybar/config.jsonc` and a Callie `style.css`: the tray (apps' status icons, such as Dropbox), then workspaces, a red dot while a screen recording runs, mode, and scratchpad on the left; the clock in the middle, with a calendar on hover; and on the right do-not-disturb and the notification bell (see [Notifications](#notifications)), the night light (a moon when on; click to toggle, right-click to configure), an idle toggle (stay awake while the eye is open), volume (click to mute), network, CPU, memory, brightness (scroll to change), and battery. Each module is a rounded, bordered pill on a 34px bar. Brightness and battery hide themselves where there is no backlight or battery, and the battery turns yellow below 30% and red below 15%. The bar uses IosevkaTerm Nerd Font's Propo variant, whose icons are sized to sit beside text.

Waybar reapplies `style.css` as soon as it changes; `Mod-Shift-C` reloads the rest.

## Audio

We'll use [pipewire](https://www.pipewire.org) with [wireplumber](https://pipewire.pages.freedesktop.org/wireplumber/index.html) and [playerctl](https://github.com/altdesktop/playerctl), which ship with CachyOS.

## Screen brightness

[brightnessctl](https://github.com/Hummer12007/brightnessctl) with keys bound via Sway config will do the trick here.

## Lock screen

[swaylock](https://github.com/swaywm/swaylock) locks the screen, styled in Callie by `~/.config/swaylock/config`. It shows the machine's wallpaper with a ring in the middle, visible before you type: pink highlights as you type, teal while checking, and red on a wrong password. chezmoi writes the config from `config.tmpl`, which picks `pond` or `pond-laptop` like the sway config does. On the laptops it leaves out `ignore-empty-password`, so pressing Enter on the empty field starts a fingerprint unlock (see [New machine](./new-machine.md#3-after-the-first-apply)). The config also sets `daemonize`, so `swaylock` returns once the screen is locked, which swayidle's `before-sleep` relies on.

## Sleep, suspend, and resume

[swayidle](https://github.com/swaywm/swayidle) reads `~/.config/swayidle/config`, which chezmoi writes from `config.tmpl`: lock after 5 minutes idle, then 5 minutes later suspend on the laptops or turn the screens off on the desktop, and lock before sleeping. The sway config only starts it. While Agent Awake holds its sleep lock, the laptops' suspend fails and they stay locked instead.

## Notifications

[mako](https://mako-project.org) shows notifications, styled in Callie by `~/.config/mako/config`. It starts on the first notification, through D-Bus, so the sway config doesn't launch it. Critical notifications have a red border and stay until dismissed.

mako only starts in a sway session: a drop-in, `~/.config/systemd/user/mako.service.d/override.conf`, skips it unless `XDG_CURRENT_DESKTOP` is sway. Without it, a notification sent at login before Plasma claims the notification service starts mako in Plasma's place. Plasma, and `sway-nested` inside it, keep Plasma's notifications.

`$mod+n` runs `dnd`, which toggles do-not-disturb: everything but critical notifications is hidden until it's toggled off.

The bell in waybar opens the notification history, as does `$mod+Ctrl+n`: `notifications` in `~/.bin` lists what's showing and then the last 50 dismissed, newest first, in rofi, and Enter copies one's text. Beside it, the do-not-disturb pill shows a hollow circle while notifications show and a filled yellow one during do-not-disturb; a click toggles it, like `$mod+n`.

## Application launcher

[rofi](https://github.com/davatorium/rofi) is the launcher on `$mod+o`, and draws every menu below. `~/.config/rofi/config.rasi` picks the Callie theme in `~/.config/rofi/themes/callie.rasi`, so the launcher and the `~/.bin` menus share one look.

- `$mod+w`: `windows`, an overview of every window on every workspace and in the scratchpad, listed by workspace with app icons. Type to filter by workspace, app, or title; Enter jumps to the window, bringing it out of the scratchpad if it's there.
- `$mod+Escape`: `power-menu`, to lock, log out, suspend, reboot, or shut down. Logging out, rebooting, and shutting down ask again first.
- `$mod+v`: clipboard history. [cliphist](https://github.com/sentriz/cliphist) records everything copied; Enter copies an entry again, and Alt+Enter sends it to another machine (see [Sending the clipboard](#sending-the-clipboard)).
- `$mod+.`: [rofimoji](https://github.com/fdw/rofimoji), which types the chosen emoji into the focused window with `wtype`.

## Sending the clipboard

To send something to another of your machines over the tailnet, copy it, then
press `$mod+Shift+v`. It arrives on that machine's clipboard with a
notification, ready to paste. To send something copied earlier, open the
history with `$mod+v`, choose it, and press Alt+Enter instead of Enter. Text
and images both work.

Both run `clip-send` in `~/.bin`, which sends with
[Taildrop](https://tailscale.com/kb/1106/taildrop). It sends to the only other
machine Taildrop can reach, or asks which in rofi when there are several. From
a terminal: `clip-send` sends the clipboard, `clip-send desktop` picks the
machine, and `... | clip-send --stdin` sends what's piped in.

On the receiving machine, the `clip-receive` user service puts the clip on the
clipboard. Any other file sent with Taildrop (`tailscale file cp <file>
<machine>:`) lands in `~/Downloads`, renamed rather than overwriting a file
already there. Both need `tailscale set --operator=$USER` on each machine (see
[New machine](./new-machine.md#3-after-the-first-apply)), and work only between
machines on the same tailnet, so not while one is switched to another. Under
Plasma, where sway's keys don't apply, send from a terminal with `clip-send`.

## Screenshots

`screenshot` in `~/.bin` takes screenshots with [grim](https://sr.ht/~emersion/grim), selecting with [slurp](https://github.com/emersion/slurp). Each one is saved to `~/Pictures/Screenshots` and copied to the clipboard:

- `Print`: drag to select a region.
- `Shift+Print`: the focused display.
- `$mod+Print`: click a window.
- `$mod+Shift+Print`: drag a region, then annotate it in [swappy](https://github.com/jtheoof/swappy) before it's saved.

## Screen recording

`screenrecord` in `~/.bin` records with
[wf-recorder](https://github.com/ammen99/wf-recorder) to
`~/Videos/Recordings`. While it records, a red dot shows in waybar to the right
of the workspaces:

- `$mod+Shift+r`: drag to select a region.
- `$mod+Shift+a`: a region, with the desktop's sound.
- `$mod+Ctrl+Shift+r`: the focused display.
- `$mod+Ctrl+Shift+a`: the focused display, with the desktop's sound.

Any of those keys, or a click on the red dot, stops the recording and saves it,
with a notification. The sound is what's playing, recorded from the default
output's monitor, not the microphone.

For anything longer or more involved, use OBS with its "Screen Capture
(PipeWire)" source. That, and screen sharing in browsers and apps such as Zoom,
goes through `xdg-desktop-portal-wlr`, which asks which display to share the
first time.

## File manager

## Hardware-specific configuration
