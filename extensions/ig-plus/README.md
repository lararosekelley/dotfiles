# IG Plus

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

## Settings

The toolbar button opens the settings. Both are on by default, in every
Instagram tab:

- "Hide home feed posts" hides posts on the home page. The stories tray stays,
  and no more posts load.
- "Hide Reels" hides links to the Reels tab and sends `/reels/` to messages.
  Single reels, such as ones sent in messages, still open.

## How it works

The extension watches for Instagram pages in app windows. For each one, a
`declarativeNetRequest` session rule sends a mobile Safari `User-Agent` and
drops Chrome's client hint headers. A script that runs before Instagram's own
reports the same identity to the page, along with a portrait phone screen,
touch support, and touchscreen answers to pointer and hover media queries.

Instagram will not add to a story from a landscape viewport, so the extension
also resizes the app window to phone proportions.

In the app, choosing a photo for a story opens a webcam view instead of the
file picker. A story upload is one opened right after clicking something
labeled "Story", such as the Story menu item; posts keep Instagram's picker.
The webcam view has four ways to start a story:

- "Take photo" captures a mirrored webcam frame, fitted whole by default or
  filling the frame after "Crop".
- "Choose file" opens a picker. Images go to the editor fitted whole; videos go
  straight to Instagram.
- "Google Photos" opens Google's picker in a popup. Photos go to the editor
  like chosen files; videos go straight to Instagram.
- "Colors" starts from a solid or gradient background, picked from swatches.

The editor composes a 1080x1920 image, filling any uncovered space with a
blurred copy of the photo. Its tools are Photo, Text and Brush, and dragging on
the image moves the photo, places the text, or draws, depending on which is
chosen. The zoom slider or scroll wheel zooms the photo. Brush strokes sit
between the photo and the text and start over with each new photo or
background. Text and drawing go into the image because Instagram's mobile web
editor has neither. "Done" hands the JPEG to Instagram as if it were
picked from disk. Chrome asks for camera access for Instagram the first time.

## Close friends

Instagram's mobile web composer always shares to everyone. With "Close friends"
on, the extension adds `audience=besties` to the composer's
`configure_to_story` request, the setting the phone apps send, and drops the
Facebook cross-post the web composer would otherwise add. Instagram's response
says which audience it applied, and a notice reports it. If the request cannot
be read, the share is stopped rather than sent to everyone. Instagram does not
document this, so it may stop working without notice.

## Look

The editor uses the colors, shapes and type of
[Callie](https://callieapp.org), following the system's light or dark setting.
`fonts/` bundles Callie's Nunito under the SIL Open Font License.

Text fonts come from the local machine: "Elegant" uses P052 italic and "Script"
uses Z003, both from the URW base fonts.

## Google Photos

The picker signs in with the Google account the Chrome profile uses, through
the OAuth client in `manifest.json`. That client belongs to a Google Cloud
project with the Photos Picker API enabled and is of type "Chrome Extension",
bound to the extension ID. Chrome derives an unpacked extension's ID from its
folder path, so moving this folder breaks sign-in until the client is updated.

While the consent screen is in testing mode, only its listed test users can
sign in.

## Discard

Instagram's composer has no way to back out, so a "Discard" button in the top
left returns to the feed. Like Callie's destructive buttons, it asks for a
second click to confirm.

Instagram changes its web app often, so this may stop working without notice.
