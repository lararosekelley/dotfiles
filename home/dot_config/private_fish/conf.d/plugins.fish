# Plugins in ~/.config/fish/fish_plugins, managed by fisher
# (https://github.com/jorgebucaran/fisher). The first interactive shell without
# fisher installs it and the listed plugins; after that, a changed fish_plugins,
# from a sync or `fisher install`, is applied by the next shell.

status is-interactive; or return

# fifc opens files from its previews here
set -gx fifc_editor $EDITOR

# fifc's fzf completion on demand with Shift+Tab, in place of fish's completion
# search; Tab stays fish's own completion. fifc reads fifc_keybinding as a
# universal variable when it loads, which can be before this file.
set -U fifc_keybinding shift-tab
for mode in default insert
    bind --erase --mode $mode tab
    bind --mode $mode shift-tab _fifc
end

set -l plugins (string match -rv '^\s*(#.*)?$' <$__fish_config_dir/fish_plugins 2>/dev/null)
or return

if test "$plugins" != "$__fish_plugins_installed"
    if not functions -q fisher
        set -l fisher_tag (string match -rg '^jorgebucaran/fisher@(.+)$' -- $plugins)
        echo "fish: installing fisher $fisher_tag and the plugins in fish_plugins" >&2
        curl -fsSL https://raw.githubusercontent.com/jorgebucaran/fisher/$fisher_tag/functions/fisher.fish | source
    end
    # fisher reads plugins from stdin when it is not a terminal; give it none so
    # it falls back to fish_plugins
    functions -q fisher
    and fisher update </dev/null
    and set -U __fish_plugins_installed $plugins
end
