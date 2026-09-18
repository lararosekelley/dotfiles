# Sax recording setup

Select the **Sax VHS** scene collection and **Sax 4K 30** profile.

## Scenes

- **Sax - Record widescreen master**: 4K/30 landscape master with light NTSC/VHS treatment. Use this for recordings you want to crop into multiple formats later.
- **Sax - 4x3 VHS tape**: centered 4:3 composition with side bars.
- **Sax - Portrait framing check**: check that your head, hands, and sax bell fit a central phone crop before recording the widescreen master.
- **REFERENCE - 4x3 worn VHS**: softened SD detail, stronger color bleed, bloom, tape wear, CRT curvature, and scanlines.
- **REFERENCE - Phone vertical retro**: softened detail, color bleed, bloom, tape wear, and CRT edges in a portrait composition.

All scenes output to the same 3840x2160 landscape canvas. The phone scenes preview a portrait composition inside that canvas; crop away the side bars in your editor for a vertical export. Filters are baked into recordings.

## Hardware and audio

The camera source expects an MX Brio at `/dev/video0`, using MJPEG at 3840x2160/30 fps. The shared microphone explicitly selects Scarlett 2i2 Input 1 through PulseAudio/PipeWire. Re-select devices in source properties if their names differ on another machine.

The microphone uses the sax-tested filter chain in this order:

1. Compressor: 1.5:1 ratio, 30 ms attack, 250 ms release, +2 dB output gain; other settings use OBS defaults.
2. Limiter: -1 dB threshold; other settings use OBS defaults.

Recording uses H.264/AAC in MKV at 48 kHz. Choose a local recording directory in **Settings → Output** after installing these dotfiles; the machine-specific path is omitted here.

## Editing in the OBS UI

The reference scenes contain a nested **Sax - Record widescreen master** scene rather than separate camera and microphone entries. Their extra retro effects are attached to the reference scenes themselves.

### Reference video effects

1. In the **Scenes** panel, right-click **REFERENCE - 4x3 worn VHS** or **REFERENCE - Phone vertical retro** and choose **Filters**.
2. Select a filter on the left to reveal its controls on the right. Use its eye icon to compare with the effect disabled.
3. To adjust noise, select **01 - NTSC dubbed tape color** or **01 - NTSC phone edit color**, then adjust **Luma Noise**.

Use the reference's entry in the **Scenes** panel, not the nested master entry in **Sources**. These scene-level effects tune only that reference look.

For the phone reference's rounded corners, curvature, and vignette, edit **04b - CRT portrait glass and edges**. The adjacent **04a** crop and **04c** padding filters make the effect follow the portrait picture, then restore its position in the landscape preview. Leave those two enabled; toggle **04b** alone to compare the CRT treatment.

### Shared microphone filters

1. Select **Sax - Record widescreen master**.
2. In **Sources**, right-click **Sax Mic - Scarlett Input 1** and choose **Filters**.
3. Select **Compressor** or **Limiter** to edit its controls.

These adjustments apply to all five sax scenes because they share the microphone.

### Shared camera settings and base effects

In **Sax - Record widescreen master**, right-click **Sax Camera - MX Brio 4K**:

- **Properties** opens camera settings such as capture resolution and frame rate.
- **Filters** opens the gentle base NTSC/VHS treatment.

These camera changes carry through to all five sax scenes, including the references.

### Unlocking positioning and cropping

Source padlocks prevent moving or resizing sources; they do not lock filter settings.

- Click the padlock beside a source in the **Sources** panel to unlock its transform.
- If the preview is also locked, right-click the preview and uncheck **Lock Preview**.
- For precise framing, right-click the source and choose **Transform → Edit Transform**.

The locks can stay enabled while you adjust filters.

## Plugin dependency

Install [OBS Retro Effects](https://github.com/lararosekelley/obs-retro-effects) separately. The fork's README documents Fedora build and user-local installation. Compiled plugins, credentials, logs, and backups are excluded from this directory's versioned configuration.
