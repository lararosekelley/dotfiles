# RGB lighting (OpenRGB)

If you use `openrgb` and know what you're doing:

```bash
D=~/folder/you/cloned/repo/to/dotfiles/system

mkdir -p ~/.config/OpenRGB
cp $D/*.orp $D/*.ors $D/OpenRGB.json ~/.config/OpenRGB/

sudo mkdir -p /root/.config/OpenRGB
sudo cp $D/*.orp /root/.config/OpenRGB/

sudo install -m 644 $D/openrgb*.service /etc/systemd/system/

sudo systemctl daemon-reload
sudo systemctl enable --now openrgb.service
sudo systemctl enable openrgb-resume.service openrgb-sleep.service
```

Modify the profiles (defaults are `off.orp` and `pink.orp`, from `system/`) to suit your
case lighting setup.
