"""Generate launcher icons + splash logo from assets/logo.png.

Run after `flutter create .` (platform folders aren't committed):

    pip install pillow
    python tool/gen_icons.py

Writes Android mipmaps (legacy + adaptive), the Android splash bitmap,
web icons and the iOS AppIcon set. See PLATFORM_SETUP.md -> Branding.
"""
import os
from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BG = (10, 9, 7, 255)  # Gold Noir #0a0907

logo = Image.open(os.path.join(ROOT, "assets", "logo.png")).convert("RGBA")
logo = logo.crop(logo.getbbox())


def place(size, frac, bg=None, radius=0.0):
    im = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    if bg:
        mask = Image.new("L", (size, size), 0)
        ImageDraw.Draw(mask).rounded_rectangle(
            [0, 0, size - 1, size - 1], radius=int(size * radius), fill=255)
        im.paste(Image.new("RGBA", (size, size), bg), (0, 0), mask)
    w = int(size * frac)
    h = int(w * logo.height / logo.width)
    im.alpha_composite(logo.resize((w, h), Image.LANCZOS),
                       ((size - w) // 2, (size - h) // 2))
    return im


def p(*parts):
    return os.path.join(ROOT, *parts)


res = p("android", "app", "src", "main", "res")
if os.path.isdir(res):
    for d, px in {"mdpi": 48, "hdpi": 72, "xhdpi": 96,
                  "xxhdpi": 144, "xxxhdpi": 192}.items():
        os.makedirs(os.path.join(res, f"mipmap-{d}"), exist_ok=True)
        place(px, 0.62, BG, 0.22).save(
            os.path.join(res, f"mipmap-{d}", "ic_launcher.png"))
        place(px * 108 // 48, 0.40).save(
            os.path.join(res, f"mipmap-{d}", "ic_launcher_foreground.png"))
    os.makedirs(os.path.join(res, "mipmap-anydpi-v26"), exist_ok=True)
    with open(os.path.join(res, "mipmap-anydpi-v26", "ic_launcher.xml"), "w") as f:
        f.write(
            '<?xml version="1.0" encoding="utf-8"?>\n'
            '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
            '    <background android:drawable="@color/ic_launcher_background"/>\n'
            '    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n'
            '    <monochrome android:drawable="@mipmap/ic_launcher_foreground"/>\n'
            '</adaptive-icon>\n')
    place(288, 0.5).save(os.path.join(res, "drawable", "launch_logo.png"))

if os.path.isdir(p("web")):
    place(192, 0.62, BG, 0.22).save(p("web", "icons", "Icon-192.png"))
    place(512, 0.62, BG, 0.22).save(p("web", "icons", "Icon-512.png"))
    place(192, 0.5, BG).save(p("web", "icons", "Icon-maskable-192.png"))
    place(512, 0.5, BG).save(p("web", "icons", "Icon-maskable-512.png"))
    place(64, 0.9).save(p("web", "favicon.png"))

ios = p("ios", "Runner", "Assets.xcassets", "AppIcon.appiconset")
if os.path.isdir(ios):
    for fn in os.listdir(ios):
        if fn.endswith(".png"):
            size = Image.open(os.path.join(ios, fn)).size[0]
            place(size, 0.62, BG).convert("RGB").save(os.path.join(ios, fn))

print("icons written")
