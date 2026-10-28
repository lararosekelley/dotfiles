# IG Stories

Chrome extension for posting Instagram stories from desktop. Instagram web only
offers story upload to mobile browsers, so this makes the installed Instagram
app (PWA) present as mobile Safari. Instagram in regular browser tabs is not
affected.

## Install

1. Open `chrome://extensions` and enable Developer mode.
2. Click "Load unpacked" and choose this directory.
3. Install Instagram as an app from the install icon in Chrome's address bar,
   if it is not installed already.

Opening the Instagram app resizes it to phone proportions and reloads it once
with mobile request headers. Keep the window taller than it is wide.

After editing files, click the reload icon on the extension's card, then
reopen the app.

## How it works

The extension watches for Instagram pages in app windows. For each one, a
`declarativeNetRequest` session rule sends a mobile Safari `User-Agent` and
drops Chrome's client hint headers. A script that runs before Instagram's own
reports the same identity to the page, along with a portrait phone screen,
touch support, and touchscreen answers to pointer and hover media queries.

Instagram will not add to a story from a landscape viewport, so the extension
also resizes the app window to phone proportions.

In the app, choosing a photo opens a webcam view instead of the file picker.
"Take photo" captures a mirrored 1080x1920 image. By default it shows the whole
webcam frame over a blurred backdrop; "Crop" switches to filling the frame
instead. The review step that follows can add text, which is drawn into the
image because Instagram's mobile web editor has no text tool. "Use photo" hands
the JPEG to Instagram as if it were picked from disk. "Choose file" opens the
normal picker, which is also the way to pick videos. Chrome asks for camera
access for Instagram the first time.

Text fonts come from the local machine: "Elegant" uses P052 italic and "Script"
uses Z003, both from the URW base fonts.

Instagram's composer has no way to back out, so a "Discard" button in the top
left returns to the feed.

Instagram changes its web app often, so this may stop working without notice.
