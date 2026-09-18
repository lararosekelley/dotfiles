# Sax recording setup

Select the **Sax VHS** scene collection and **Sax 4K 30** profile.

## Scenes

- **Sax - Record widescreen master**: 4K/30 landscape master with light NTSC/VHS treatment. Use this for recordings you want to crop into multiple formats later.
- **Sax - 4x3 VHS tape**: centered 4:3 composition with side bars.
- **Sax - Portrait framing check**: check that your head, hands, and sax bell fit a central phone crop before recording the widescreen master.
- **REFERENCE - 4x3 worn VHS**: softened SD detail, stronger color bleed, bloom, tape wear, CRT curvature, and scanlines.
- **REFERENCE - Phone vertical retro**: softened detail, color bleed, bloom, and tape wear in a portrait composition.

All scenes output to the same 3840x2160 landscape canvas. The phone scenes preview a portrait composition inside that canvas; crop away the side bars in your editor for a vertical export. Filters are baked into recordings.

## Hardware and audio

The camera source expects an MX Brio at `/dev/video0`, using MJPEG at 3840x2160/30 fps. The shared microphone explicitly selects Scarlett 2i2 Input 1 through PulseAudio/PipeWire. Re-select devices in source properties if their names differ on another machine.

The microphone uses the sax-tested filter chain in this order:

1. Compressor: 1.5:1 ratio, 30 ms attack, 250 ms release, +2 dB output gain; other settings use OBS defaults.
2. Limiter: -1 dB threshold; other settings use OBS defaults.

Recording uses H.264/AAC in MKV at 48 kHz. Choose a local recording directory in **Settings → Output** after installing these dotfiles; the machine-specific path is omitted here.

## Plugin dependency

Install [OBS Retro Effects](https://github.com/lararosekelley/obs-retro-effects) separately. The fork's README documents Fedora build and user-local installation. Compiled plugins, credentials, logs, and backups are excluded from this directory's versioned configuration.
