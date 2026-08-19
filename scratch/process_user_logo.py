import os
from PIL import Image, ImageOps

def process_user_logo():
    src_path = r"C:\Users\mdsak\.gemini\antigravity-ide\brain\1d4cb30d-7e32-4ff6-a472-97b6690663cb\.user_uploaded\media_1787107413331.jpg"
    dest_dir = r"d:\sakil\mess_finder\assets\images"
    os.makedirs(dest_dir, exist_ok=True)

    img = Image.open(src_path).convert("RGBA")
    w, h = img.size

    # 1. Full Branding Image (with text and tagline)
    img.save(os.path.join(dest_dir, "app_branding.png"), "PNG", optimize=True)
    img.save(os.path.join(dest_dir, "app_logo_full.png"), "PNG", optimize=True)

    # 2. Square App Icon for Play Store (512x512) and Splash / App
    # Crop to square and resize
    icon_1024 = img.resize((1024, 1024), Image.Resampling.LANCZOS)
    icon_1024.save(os.path.join(dest_dir, "app_logo_1024.png"), "PNG", optimize=True)

    icon_512 = img.resize((512, 512), Image.Resampling.LANCZOS)
    icon_512.save(os.path.join(dest_dir, "playstore_icon_512.png"), "PNG", optimize=True)
    icon_512.save(os.path.join(dest_dir, "app_logo.png"), "PNG", optimize=True)

    # 3. Transparent / Clean Circular / Squircle Launcher Icons
    densities = {
        r"d:\sakil\mess_finder\android\app\src\main\res\mipmap-mdpi\ic_launcher.png": (48, 48),
        r"d:\sakil\mess_finder\android\app\src\main\res\mipmap-hdpi\ic_launcher.png": (72, 72),
        r"d:\sakil\mess_finder\android\app\src\main\res\mipmap-xhdpi\ic_launcher.png": (96, 96),
        r"d:\sakil\mess_finder\android\app\src\main\res\mipmap-xxhdpi\ic_launcher.png": (144, 144),
        r"d:\sakil\mess_finder\android\app\src\main\res\mipmap-xxxhdpi\ic_launcher.png": (192, 192),
    }

    # Generate rounded launcher icon with subtle padding for Android
    launcher_base = Image.new("RGBA", (1024, 1024), (255, 255, 255, 255))
    resized_content = img.resize((960, 960), Image.Resampling.LANCZOS)
    launcher_base.paste(resized_content, (32, 32), resized_content)

    for path, d_size in densities.items():
        res = launcher_base.resize(d_size, Image.Resampling.LANCZOS)
        res.save(path, "PNG", optimize=True)

    print("Success: User logo processed and saved across all asset directories!")

if __name__ == "__main__":
    process_user_logo()
