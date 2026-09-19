# User audio plugins

The dotfiles repository includes the user plugin directories:

| Repository directory | Installed location | Format |
| --- | --- | --- |
| `content/.lv2/` | `~/.lv2/` | LV2 bundles |
| `content/.vst/` | `~/.vst/` | Linux VST2 plugins |
| `content/.vst3/` | `~/.vst3/` | VST3 bundles |
| `content/.clap/` | `~/.clap/` | CLAP plugins |

Currently `.vst/` contains the Linux x86-64 binaries for **TAL-Reverb-2** and **TAL-Reverb-4** (about 7 MB total). The other three directories have placeholders because no plugins were installed there when this setup was captured. Dragonfly was removed after its editor crashed or rendered black in OBS.

The OBS sax collection uses **TAL-Reverb-2**, between its compressor and limiter. TAL-Reverb-4 is retained as an additional installed plugin. OBS's built-in VST 2.x filter uses VST2; keeping LV2, VST3, or CLAP plugins here does not add support for those formats to OBS.

## Install or update existing files

From the repository root:

```bash
cargo run -- sync to-home --only '.vst/**' --only '.vst3/**' --only '.lv2/**' --only '.clap/**'
```

Review the prompts. The usual full `sync to-home` includes these files too. Restart audio hosts after installing plugins; avoid replacing a plugin binary while it is loaded.

## Capture newly installed plugins

The sync CLI discovers paths from `content/`, even in the `to-repo` direction. To add newly installed files and whole bundles, copy the directories into the repository first:

```bash
for dir in .lv2 .vst .vst3 .clap; do
  if [ -d "$HOME/$dir" ]; then
    mkdir -p "content/$dir"
    cp -a "$HOME/$dir/." "content/$dir/"
  fi
done
git status --short -- content/.lv2 content/.vst content/.vst3 content/.clap
```

This is additive; uninstalling a plugin at home does not delete its repository copy. Remove obsolete copies explicitly so the next sync does not reinstall them. Keep complete plugin bundles, including their resources. Review changes before committing and exclude any license keys or account credentials that a future plugin stores alongside its binaries.

Sources: [TAL-Reverb-2/3](https://tal-software.com/products/tal-reverb), [TAL-Reverb-4](https://tal-software.com/products/tal-reverb-4).
