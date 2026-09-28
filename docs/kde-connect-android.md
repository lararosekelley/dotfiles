# KDE Connect (Android)

Android only lets the foreground app or the active keyboard read the clipboard, so
KDE Connect sends the desktop clipboard to the phone but not the reverse. It works
around this by watching the system log, which needs two permissions granted over
adb (`sudo dnf install android-tools`, then enable USB debugging on the phone):

```bash
adb shell pm grant org.kde.kdeconnect_tp android.permission.READ_LOGS
adb shell appops set org.kde.kdeconnect_tp SYSTEM_ALERT_WINDOW allow
adb shell am force-stop org.kde.kdeconnect_tp
```

Each command returns instantly and prints nothing on success; one that hangs means
the device dropped. The grants survive reboots but not a reinstall of the app.

If `adb devices` shows the phone as `offline`, run `adb kill-server` and replug it
unlocked. `unauthorized` means the "Allow USB debugging?" prompt on the phone is
waiting to be accepted; if it never appears, revoke USB debugging authorizations in
Developer options and switch the USB mode to File transfer. A connection that keeps
dropping is usually the cable or port. Wireless debugging (`adb pair`, then
`adb connect`) avoids both.

To keep KDE Connect running in the background, set its battery usage to
Unrestricted in the app's Android settings and enable Persistent notification in
KDE Connect's own settings.
