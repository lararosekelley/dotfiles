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

The microphone keeps the sax-tested compressor/limiter settings, with a subtle reverb added between them:

1. Compressor: 1.5:1 ratio, 30 ms attack, 250 ms release, +2 dB output gain; other settings use OBS defaults.
2. **Reverb - subtle plate (TAL)**: TAL-Reverb-2 VST2 with the custom **Sax - Subtle Plate** program. Saved normalized controls: dry 0.50 (unity gain), wet 0.05, room size 0.35, pre-delay 0.10. These are plugin parameter positions, not a 5% wet/dry crossfade or physical decay/delay units. This is a starting point to audition with the sax, not part of the previously tested dry chain.
3. Limiter: -1 dB threshold; other settings use OBS defaults.

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
3. Select **Compressor** or **Limiter** to edit its controls. For reverb, select **Reverb - subtle plate (TAL)** and click **Open Plug-in Interface**.

In TAL, adjust **Wet** for the amount of reverb, **Room Size** for the reverb's size/tail, and **Pre Delay** for separation from note attacks. Keep **Dry** at its saved setting initially. Toggle the reverb filter's eye icon for a dry/wet comparison. Selecting another preset replaces the custom settings. Reverb is baked into OBS recordings.

The TAL editor was confirmed working with OBS launched through XWayland on Fedora/KDE:

```bash
QT_QPA_PLATFORM=xcb obs
```

Close OBS before using that command. Use this launch when editing VST controls. Dragonfly's editor crashed under native Wayland and remained black with XWayland, so it was replaced and its installed plugins removed.

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

## Using the retro video in Zoom

OBS Virtual Camera makes the finished scene, including its video filters, available to Zoom as a webcam. Recording or streaming is not required.

### Fedora prerequisite

Linux requires the **v4l2loopback** kernel module for OBS Virtual Camera. Install a package compatible with your Fedora release and running kernel, then load the module. With Secure Boot enabled, the module also needs an accepted signature. This setup has not yet been completed here; the earlier OBS log reported `v4l2loopback not installed, virtual camera not registered`.

After installing and loading the module, restart OBS. If Virtual Camera is unavailable, check **Help → Log Files → View Current Log** for v4l2loopback errors.

### Start a call

1. Open OBS and choose the scene to send to Zoom. The widescreen master gives a milder look; the 4:3 reference gives the stronger VHS/TV look. The phone reference includes large side bars in the landscape output.
2. In **Controls**, click **Start Virtual Camera**.
3. In Zoom, open **Settings → Video → Camera** and select the OBS virtual camera device. Its displayed name may depend on the v4l2loopback configuration. If it is missing, restart Zoom after starting Virtual Camera.
4. Turn off Zoom backgrounds and appearance filters initially so they do not interfere with the retro treatment.
5. Keep OBS and Virtual Camera running for the call, then click **Stop Virtual Camera** when finished.

By default, Virtual Camera sends OBS's program output: changing scenes changes what the call sees. Use the settings/gear beside **Start Virtual Camera** to select a specific **Scene** as the output when you want a fixed call composition.

### Audio and call quality

- Virtual Camera sends **video only**. In **Zoom → Settings → Audio**, select the Scarlett microphone directly. This bypasses OBS's compressor, reverb, and limiter; sending processed OBS audio would require separate virtual-audio routing.
- Heavy noise and scanlines can become blocky under Zoom's compression. For regular work calls, consider a dedicated landscape call scene with milder NTSC/VHS effects. Such a scene is not included yet.

## Plugin dependency

Install [OBS Retro Effects](https://github.com/lararosekelley/obs-retro-effects) separately. The fork's README documents Fedora build and user-local installation. Compiled plugins, credentials, logs, and backups are excluded from this directory's versioned configuration.

Audio additionally uses [TAL-Reverb-2](https://tal-software.com/products/tal-reverb), the Linux VST2 build. Its binary is included at `content/.vst/libTAL-Reverb-2.so`; see the [audio-plugin sync guide](../../.vst/README.md). OBS's VST filter stores an absolute path (currently `/home/lara/.vst/libTAL-Reverb-2.so`); on another account, re-select the plugin in the reverb filter. The saved state is tied to the installed binary's hash. If a different TAL build resets it, adjust its interface and let OBS save the new state.
