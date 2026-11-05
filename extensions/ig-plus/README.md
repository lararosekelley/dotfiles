# IG Plus

Browser extension for Instagram on Chrome, Firefox, and Firefox for Android. It
posts stories from desktop, with an editor for photos, text, and drawing and
an option to share to close friends. It can also hide the home feed and Reels.

## Install

IG Plus is not in the Chrome Web Store or on addons.mozilla.org. Instagram
changes its site often, so any part of it may stop working without notice.

### Chrome

1. Download this `ig-plus` folder and keep it somewhere it can stay.
2. Open `chrome://extensions`, turn on "Developer mode", click "Load
   unpacked", and choose the folder.
3. Pin IG Plus from the puzzle piece menu. Its button holds the settings and
   "Open phone window".

To post a story, open the phone window, or install Instagram as an app from
the install icon in Chrome's address bar, and tap Story there.

### Firefox

1. Download the signed `.xpi` from the newest
   [IG Plus release](https://github.com/lararosekelley/dotfiles/releases?q=ig-plus),
   or sign your own (see Development). Open it in Firefox, by dragging it into
   a window or with File, Open File, and click "Add".
2. Firefox grants site access only when asked. Open `about:addons`, then IG
   Plus, then Permissions, and allow all three sites. Reload Instagram.
3. Pin IG Plus from the Extensions menu and open the phone window from it.

### Firefox for Android

1. Download the same signed `.xpi` from the release onto the phone.
2. In Firefox, open Settings, About Firefox, and tap the Firefox logo five
   times to enable the debug menu.
3. In Settings, tap "Install extension from file" and choose the `.xpi`.

The settings are under the Firefox menu, Extensions, IG Plus. Firefox for
Android already gets Instagram's phone site, so stories work in any tab.

## Settings

The toolbar button opens the settings. Both are on by default:

- "Hide home feed posts" hides posts on the home page. The stories tray stays,
  and no more posts load.
- "Hide Reels" hides links to the Reels tab and sends `/reels/` to messages.
  Single reels, such as ones sent in messages, still open.

On desktop, "Open phone window" opens Instagram in a phone-sized window.

## Phone tabs

Instagram web only offers story upload to phones, so the extension makes some
tabs present as mobile Safari. These are the installed Instagram app in
Chrome, and the phone window in either browser. Regular Instagram tabs are not
affected. Firefox for Android is a phone already and is left as it is.

For each phone tab, a `declarativeNetRequest` session rule sends a mobile
Safari `User-Agent` and drops Chrome's client hint headers. A script that runs
before Instagram's own reports the same identity to the page, along with a
portrait phone screen, touch support, and touchscreen answers to pointer and
hover media queries.

Instagram will not add to a story from a landscape viewport, so the extension
also resizes the app window to phone proportions. Keep it taller than it is
wide.

## Stories

In a phone tab, choosing a photo for a story opens a webcam view instead of
the file picker. A story upload is one opened right after clicking something
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
picked from disk. The browser asks for camera access for Instagram the first
time.

## Close friends

Instagram's mobile web composer always shares to everyone. With "Close friends"
on, the extension adds `audience=besties` to the composer's
`configure_to_story` request, the setting the phone apps send, and drops the
Facebook cross-post the web composer would otherwise add. Instagram's response
says which audience it applied, and a notice reports it. If the request cannot
be read, the share is stopped rather than sent to everyone. Instagram does not
document this, so it may stop working without notice.

## Look

The editor and settings use the colors, shapes and type of
[Callie](https://callieapp.org), following the system's light or dark setting.
`fonts/` bundles Callie's Nunito under the SIL Open Font License.

Text fonts come from the local machine: "Elegant" uses P052 italic and "Script"
uses Z003, both from the URW base fonts.

`icons/icon.svg` is the source of the icon. After editing it, render the PNGs
Chrome needs from this directory:

```bash
for size in 16 32 48 128; do
  magick -background none -density 600 icons/icon.svg -resize ${size}x${size} \
    -depth 8 PNG32:icons/icon-$size.png
done
```

## Google Photos

Google Photos needs a Google sign-in through an OAuth client in a Google Cloud
project. The clients in this folder, and the released `.xpi`, only accept the
Google accounts their owner lists as test users. Anyone else sees "Access
blocked" when signing in, while the rest of IG Plus works. To use Google
Photos, ask the owner to add your account as a test user, or make your own
clients:

1. Create a project in the [Google Cloud console](https://console.cloud.google.com/)
   and enable the
   [Photos Picker API](https://console.cloud.google.com/apis/library/photospicker.googleapis.com)
   in it.
2. Under Google Auth Platform, set up the consent screen for "External" users,
   leave it in testing, and add your Google account under Audience as a test
   user. Testing allows up to 100 test users, without Google's app review.
3. Create the client for each browser, under Google Auth Platform, Clients.

Chrome:

1. Create a client of type "Chrome Extension" with item ID
   `lalkkejobicceencckpheojogphlhcmb`. The `key` in `manifest.json` gives every
   copy of this folder that ID.
2. Put its client ID in `oauth2.client_id` in `manifest.json`, then reload the
   extension. It signs in with the Chrome profile's Google account.

Firefox, which has to be signed again:

1. Change `browser_specific_settings.gecko.id` in `manifest.json` to an ID of
   your own, such as `ig-plus@example.com`. Only the account that first signed
   an ID can sign it again.
2. Build and load it temporarily (see Development), then run
   `browser.identity.getRedirectURL()` in the console from its "Inspect"
   button. The result is derived from the ID.
3. Create a client of type "Web application" with that URL as its authorized
   redirect URI, and put its client ID in `WEB_CLIENT_ID` in `background.js`.
4. Build and sign it. Firefox for Android cannot sign in to Google, so Google
   Photos is desktop only.

## Discard

Instagram's composer has no way to back out, so a "Discard" button in the top
left returns to the feed. Like Callie's destructive buttons, it asks for a
second click to confirm.

## Development

### Chrome

Load this directory unpacked as above. After editing files, click the reload
icon on the extension's card, then reopen the app or phone window.

For the Chrome Web Store, `just build-ig-plus-chrome` writes
`target/ig-plus-chrome.zip` without the manifest `key`. The store assigns its
own item ID, so Google Photos there needs a Chrome Extension client for that
ID in `oauth2.client_id`.

### Firefox

Chrome and Firefox need different manifests, so Firefox loads a build of this
directory. From the repository root:

```bash
just build-ig-plus-firefox
```

For a session, open `about:debugging#/runtime/this-firefox`, click "Load
Temporary Add-on", and choose `target/ig-plus-firefox/manifest.json`. Firefox
removes it on restart. Rebuild and reload it after editing files.

A Flatpak browser such as Zen can read only the one file picked, so it loads
an empty popup and no background script. Copy the build somewhere its sandbox
can read, usually `~/Downloads`, and load it from there.

To try it on a phone without signing, enable "Remote debugging via USB" in
Firefox for Android, connect the phone over adb, and run:

```bash
npx web-ext run -t firefox-android --android-device <device-id> \
  --firefox-apk org.mozilla.firefox --source-dir target/ig-plus-firefox
```

To make an `.xpi` anyone can install, sign the build as an unlisted add-on with
[web-ext](https://extensionworkshop.com/documentation/develop/web-ext-command-reference/#web-ext-sign)
and AMO API keys. The signed file lands in `web-ext-artifacts/` and works on
desktop and Android. Unlisted add-ons do not update themselves, so sign each
new version and attach it to a release tagged `ig-plus@v<version>`:

```bash
npx web-ext sign --channel=unlisted --source-dir target/ig-plus-firefox \
  --api-key "$AMO_JWT_ISSUER" --api-secret "$AMO_JWT_SECRET"
```
