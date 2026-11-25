# User audio plugins

The dotfiles repository includes the user plugin directories:

| Repository directory | Installed location | Format |
| --- | --- | --- |
| `home/dot_lv2/` | `~/.lv2/` | LV2 bundles |
| `home/dot_vst/` | `~/.vst/` | Linux VST2 plugins |
| `home/dot_vst3/` | `~/.vst3/` | VST3 bundles |
| `home/dot_clap/` | `~/.clap/` | CLAP plugins |

`.vst/` contains the Linux x86-64 binaries for **TAL-Reverb-2** and **TAL-Reverb-4** (about 7 MB total). The other three directories contain repository placeholders, which are not installed by sync. Directories are created when they contain eligible plugin files.

The OBS sax collection uses **TAL-Reverb-2**, between its compressor and limiter. TAL-Reverb-4 is retained as an additional installed plugin. OBS's built-in VST 2.x filter uses VST2; keeping LV2, VST3, or CLAP plugins here does not add support for those formats to OBS.

## Install or update existing files

```bash
chezmoi apply --interactive ~/.lv2 ~/.vst ~/.vst3 ~/.clap
```

Review the prompts. A full `chezmoi apply` includes these files too. Restart audio hosts after installing plugins; avoid replacing a plugin binary while it is loaded.

## Capture newly installed plugins

`chezmoi re-add` only updates files it already tracks. Add newly installed files and whole bundles with `chezmoi add`:

```bash
chezmoi add ~/.lv2 ~/.vst ~/.vst3 ~/.clap
git status --short -- home/dot_lv2 home/dot_vst home/dot_vst3 home/dot_clap
```

This is additive; uninstalling a plugin at home does not delete its repository copy. Remove obsolete copies explicitly so the next `apply` does not reinstall them. Keep complete plugin bundles, including their resources. Review changes before committing and exclude any license keys or account credentials that a future plugin stores alongside its binaries.

Sources: [TAL-Reverb-2/3](https://tal-software.com/products/tal-reverb), [TAL-Reverb-4](https://tal-software.com/products/tal-reverb-4).
