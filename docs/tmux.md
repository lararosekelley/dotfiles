# tmux

sway tiles the terminal windows; tmux is for what sway can't do:

- **Sessions that outlive a window.** Close kitty, log out, or restart sway,
  and a session keeps running until you attach to it again.
- **Work over SSH**, such as a session on the desktop from a laptop over the
  tailnet.
- **Agents**, and **splits inside one terminal** when that suits better than
  separate windows.

kitty doesn't start tmux on its own. Run `tmux new -A -s <name>` (or `mux
<name>`) for a session, and detach with `C-b d`. tmux-resurrect and
tmux-continuum save the sessions every five minutes and bring them back when
tmux starts again.

## Bar and keys

The bar at the top shows the session, the windows as pills, and the status
cells shared with other tools (`~/.local/share/status-cells`): music, weather,
battery, volume, IP address, and the clock. `cached.sh` limits how often the
weather and IP lookups run, since tmux reruns status commands every few
seconds.

The second line shows keys: the prefix keys while `C-b` is pending, the
copy-mode keys in copy mode, and otherwise where to find help:

- `C-Space` or `C-b Space` opens the which-key menu
  (`~/.config/tmux/plugins/tmux-which-key/config.yaml`).
- `C-b ?` lists every key.

`C-h`, `C-j`, `C-k`, and `C-l` move between tmux panes and Neovim splits
alike; sway's own focus keys use `$mod` instead, so the two don't overlap.
`C-c` in copy mode copies to the Wayland clipboard.

## Plugins

Install or update the plugins with `C-b I` and `C-b U`
([TPM](https://github.com/tmux-plugins/tpm)).
