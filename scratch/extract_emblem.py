import os
from PIL import Image

def extract_transparent_logo():
    src_path = r"C:\Users\mdsak\.gemini\antigravity-ide\brain\1d4cb30d-7e32-4ff6-a472-97b6690663cb\.user_uploaded\media_1787107413331.jpg"
    dest_dir = r"d:\sakil\mess_finder\assets\images"
    
    img = Image.open(src_path).convert("RGBA")
    w, h = img.size

    # Isolate the Pin Emblem (top ~68% of the image)
    emblem_box = (int(w * 0.15), int(h * 0.04), int(w * 0.85), int(h * 0.68))
    emblem = img.crop(emblem_box)
    emblem.save(os.path.join(dest_dir, "app_logo_emblem.png"), "PNG", optimize=True)

    # Clean transparent cutout of emblem: pixels with near white (>240) get alpha 0
    emblem_trans = emblem.copy()
    datas = emblem_trans.getdata()
    new_data = []
    for item in datas:
        # If nearly pure white background
        if item[0] > 240 and item[1] > 240 and item[2] > 240:
            new_data.append((255, 255, 255, 0))
        else:
            new_data.append(item)
    emblem_trans.putdata(new_data)
    emblem_trans.save(os.path.join(dest_dir, "app_logo_emblem_transparent.png"), "PNG", optimize=True)

    print("Emblem and transparent assets created!")

if __name__ == "__main__":
    extract_transparent_logo()
