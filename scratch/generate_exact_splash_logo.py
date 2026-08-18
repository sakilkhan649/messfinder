import math
from PIL import Image, ImageDraw, ImageFilter

def create_perfect_splash_logo(size=1024):
    canvas_size = size * 2
    img = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))

    # 1. Base Squircle with AppTheme.primaryGradient (Top-Left #10B981 to Bottom-Right #047857)
    c_start = (16, 185, 129) # #10B981
    c_end = (4, 120, 87)     # #047857

    bg = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    bg_draw = ImageDraw.Draw(bg)

    squircle_margin = int(canvas_size * 0.04)
    corner_radius = int(canvas_size * 0.22)
    squircle_rect = [squircle_margin, squircle_margin, canvas_size - squircle_margin, canvas_size - squircle_margin]

    # Smooth diagonal gradient sweep
    for i in range(2 * canvas_size):
        t = i / (2 * canvas_size)
        r = int(c_start[0] * (1 - t) + c_end[0] * t)
        g = int(c_start[1] * (1 - t) + c_end[1] * t)
        b = int(c_start[2] * (1 - t) + c_end[2] * t)
        x0 = max(0, i - canvas_size)
        y0 = i - x0
        x1 = min(canvas_size, i)
        y1 = i - x1
        bg_draw.line([(x0, y0), (x1, y1)], fill=(r, g, b, 255), width=2)

    # Mask to squircle
    mask = Image.new("L", (canvas_size, canvas_size), 0)
    m_draw = ImageDraw.Draw(mask)
    m_draw.rounded_rectangle(squircle_rect, radius=corner_radius, fill=255)
    bg.putalpha(mask)

    # 2. Splash Circular Frosted Glass Badge (Exact match to splash_screen.dart)
    cx = canvas_size // 2
    cy = canvas_size // 2
    circle_r = int(canvas_size * 0.32)

    # Circular Shadow
    shadow = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    s_draw = ImageDraw.Draw(shadow)
    spread = int(canvas_size * 0.015)
    s_draw.ellipse(
        [cx - circle_r - spread, cy - circle_r - spread + int(canvas_size * 0.02),
         cx + circle_r + spread, cy + circle_r + spread + int(canvas_size * 0.02)],
        fill=(0, 0, 0, 60)
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(radius=int(canvas_size * 0.035)))

    # Circle Glass (fill: white 15%, border: white 30%)
    circle_layer = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    c_draw = ImageDraw.Draw(circle_layer)
    border_w = int(canvas_size * 0.012)

    c_draw.ellipse(
        [cx - circle_r, cy - circle_r, cx + circle_r, cy + circle_r],
        fill=(255, 255, 255, 38),
        outline=(255, 255, 255, 77),
        width=border_w
    )

    # 3. Exact Material Icons.home_work_rounded in Pure White
    icon_layer = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    i_draw = ImageDraw.Draw(icon_layer)

    scale = canvas_size * 0.36
    white = (255, 255, 255, 255)
    emerald_bg = (6, 115, 82, 255)

    # Right Apartment Building
    bldg_w = int(scale * 0.44)
    bldg_h = int(scale * 0.74)
    bldg_right = cx + int(scale * 0.50)
    bldg_left = bldg_right - bldg_w
    bldg_bottom = cy + int(scale * 0.38)
    bldg_top = bldg_bottom - bldg_h
    bldg_r = int(scale * 0.05)

    i_draw.rounded_rectangle(
        [bldg_left, bldg_top, bldg_right, bldg_bottom],
        radius=bldg_r,
        fill=white
    )

    # 6 Windows (2 columns x 3 rows)
    win_sz = int(scale * 0.08)
    win_cr = int(scale * 0.02)
    col1_x = bldg_left + int(scale * 0.09)
    col2_x = bldg_left + int(scale * 0.26)

    for row in range(3):
        row_y = bldg_top + int(scale * 0.11) + row * int(scale * 0.16)
        i_draw.rounded_rectangle([col1_x, row_y, col1_x + win_sz, row_y + win_sz], radius=win_cr, fill=emerald_bg)
        i_draw.rounded_rectangle([col2_x, row_y, col2_x + win_sz, row_y + win_sz], radius=win_cr, fill=emerald_bg)

    # Left House (Seamlessly connected in front)
    house_w = int(scale * 0.60)
    house_left = cx - int(scale * 0.50)
    house_right = house_left + house_w
    house_bottom = bldg_bottom
    house_cx = (house_left + house_right) // 2

    roof_peak_y = cy - int(scale * 0.16)
    roof_base_y = roof_peak_y + int(scale * 0.26)
    house_body_top = roof_base_y - int(scale * 0.02)

    # House Body
    i_draw.rounded_rectangle(
        [house_left + int(scale * 0.03), house_body_top, house_right - int(scale * 0.03), house_bottom],
        radius=int(scale * 0.02),
        fill=white
    )

    # Clean Gable Roof
    roof_pts = [
        (house_cx, roof_peak_y),
        (house_right, roof_base_y),
        (house_left, roof_base_y)
    ]
    i_draw.polygon(roof_pts, fill=white)

    # House Door (Rounded Arch)
    door_w = int(scale * 0.14)
    door_h = int(scale * 0.22)
    door_left = house_cx - door_w // 2
    door_right = house_cx + door_w // 2
    door_top = house_bottom - door_h

    i_draw.rounded_rectangle(
        [door_left, door_top, door_right, house_bottom],
        radius=int(door_w * 0.38),
        fill=emerald_bg
    )

    # Composite All Layers
    comp = Image.alpha_composite(bg, shadow)
    comp = Image.alpha_composite(comp, circle_layer)
    comp = Image.alpha_composite(comp, icon_layer)

    output = comp.resize((size, size), Image.Resampling.LANCZOS)
    return output

if __name__ == "__main__":
    # Generate 512x512 Play Store Standard Icon
    icon_512 = create_perfect_splash_logo(512)
    icon_512.save(r"d:\sakil\mess_finder\assets\images\playstore_icon_512.png", "PNG", optimize=True)
    icon_512.save(r"d:\sakil\mess_finder\assets\images\app_logo.png", "PNG", optimize=True)
    icon_512.save(r"d:\sakil\mess_finder\assets\images\app_logo_functional.png", "PNG", optimize=True)

    # Generate 1024x1024 Master Icon
    icon_1024 = create_perfect_splash_logo(1024)
    icon_1024.save(r"d:\sakil\mess_finder\assets\images\app_logo_1024.png", "PNG", optimize=True)

    # Update Android mipmap launcher icons
    densities = {
        r"d:\sakil\mess_finder\android\app\src\main\res\mipmap-mdpi\ic_launcher.png": (48, 48),
        r"d:\sakil\mess_finder\android\app\src\main\res\mipmap-hdpi\ic_launcher.png": (72, 72),
        r"d:\sakil\mess_finder\android\app\src\main\res\mipmap-xhdpi\ic_launcher.png": (96, 96),
        r"d:\sakil\mess_finder\android\app\src\main\res\mipmap-xxhdpi\ic_launcher.png": (144, 144),
        r"d:\sakil\mess_finder\android\app\src\main\res\mipmap-xxxhdpi\ic_launcher.png": (192, 192),
    }
    for path, d_size in densities.items():
        resized = icon_1024.resize(d_size, Image.Resampling.LANCZOS)
        resized.save(path, "PNG", optimize=True)

    print("Success: Perfect Splash Screen Logo updated!")
