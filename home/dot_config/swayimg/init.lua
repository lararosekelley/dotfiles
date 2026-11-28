-- swayimg, the image viewer, in the Callie theme
-- (https://github.com/greylocklabs/themes). It runs after swayimg's own
-- defaults, so only what changes is here. Reference: the example config in
-- swayimg's source (extra/example.lua). Colors are 0xAARRGGBB.

-- sway tiles the window, so it needs no title bar of its own
swayimg.decoration = false

-- the file details in IosevkaTerm, in Callie's text color
swayimg.text.font = "IosevkaTerm Nerd Font"
swayimg.text.size = 18
swayimg.text.color = 0xffe0d3df
swayimg.text.shadow = 0xa01c1220

-- Callie's background, and its surfaces for the checkerboard behind
-- transparency
swayimg.viewer.set_window_background(0xff1c1220)
swayimg.viewer.set_image_chessboard(20, 0xff261a2a, 0xff33243a)

-- gallery: the selected thumbnail framed in Callie pink
swayimg.gallery.window_color = 0xff1c1220
swayimg.gallery.unselected_color = 0xff261a2a
swayimg.gallery.selected_color = 0xff33243a
swayimg.gallery.border_color = 0xfff08fb8

-- Vim-style keys alongside the defaults: h and l for the previous and next
-- image, h/j/k/l to move around the gallery, and q to quit
swayimg.viewer.on_key("h", function()
  swayimg.viewer.open("prev")
end)
swayimg.viewer.on_key("l", function()
  swayimg.viewer.open("next")
end)
swayimg.viewer.on_key("q", function()
  swayimg.exit()
end)
for key, direction in pairs({ h = "left", j = "down", k = "up", l = "right" }) do
  swayimg.gallery.on_key(key, function()
    swayimg.gallery.select(direction)
  end)
end
swayimg.gallery.on_key("q", function()
  swayimg.exit()
end)
