import sys
import os
import shutil
import colorsys
from PIL import Image

def rgb_to_hsv(rgb):
    return colorsys.rgb_to_hsv(rgb[0]/255.0, rgb[1]/255.0, rgb[2]/255.0)

def hsv_to_rgb(hsv):
    rgb = colorsys.hsv_to_rgb(hsv[0], hsv[1], hsv[2])
    return (int(rgb[0]*255), int(rgb[1]*255), int(rgb[2]*255))

def rgb_to_hex(rgb):
    return '#{:02x}{:02x}{:02x}'.format(rgb[0], rgb[1], rgb[2])

def get_dominant_colors(image_path, num_colors=16):
    img = Image.open(image_path)
    img = img.resize((100, 100))
    quantized = img.quantize(colors=num_colors)
    palette = quantized.getpalette()
    colors = []
    for i in range(min(num_colors, len(palette) // 3)):
        r = palette[i*3]
        g = palette[i*3+1]
        b = palette[i*3+2]
        colors.append((r, g, b))
    return colors

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 generate_theme.py <path_to_wallpaper>")
        sys.exit(1)
    
    wallpaper_path = os.path.abspath(sys.argv[1])
    if not os.path.exists(wallpaper_path):
        print(f"Error: Wallpaper not found at {wallpaper_path}")
        sys.exit(1)

    # 1. Extract Colors
    try:
        colors = get_dominant_colors(wallpaper_path)
    except Exception as e:
        print(f"Error reading image: {e}")
        sys.exit(1)

    # 2. Select Accent & Base
    # Primary: Find the most vibrant color (highest S * V)
    vibrant_colors = []
    for c in colors:
        h, s, v = rgb_to_hsv(c)
        vibrant_colors.append((c, s * v, h, s, v))
    
    vibrant_colors.sort(key=lambda x: x[1], reverse=True)
    best_vibrant = vibrant_colors[0]
    
    h_p, s_p, v_p = best_vibrant[2], best_vibrant[3], best_vibrant[4]
    
    # Generate high quality primary
    primary_hsv = (h_p, max(s_p, 0.45), max(v_p, 0.8))
    primary_rgb = hsv_to_rgb(primary_hsv)
    
    # Generate dark base background
    bg_hsv = (h_p, min(s_p, 0.14), 0.08)
    bg_rgb = hsv_to_rgb(bg_hsv)
    
    # Generate complementary theme palette
    bg_alt_rgb = hsv_to_rgb((h_p, min(s_p, 0.14), 0.06))
    bg_soft_rgb = hsv_to_rgb((h_p, min(s_p, 0.14), 0.13))
    bg_hover_rgb = hsv_to_rgb((h_p, min(s_p, 0.14), 0.18))
    
    text_rgb = hsv_to_rgb((h_p, 0.04, 0.94))
    subtext_rgb = hsv_to_rgb((h_p, 0.06, 0.76))
    
    # Hex codes
    hex_primary = rgb_to_hex(primary_rgb)
    hex_bg = rgb_to_hex(bg_rgb)
    hex_bg_alt = rgb_to_hex(bg_alt_rgb)
    hex_bg_soft = rgb_to_hex(bg_soft_rgb)
    hex_bg_hover = rgb_to_hex(bg_hover_rgb)
    hex_text = rgb_to_hex(text_rgb)
    hex_subtext = rgb_to_hex(subtext_rgb)
    
    # 3. Create target directory
    target_dir = os.path.expanduser("~/.config/themes/current")
    os.makedirs(target_dir, exist_ok=True)
    
    # 4. Copy Wallpaper
    target_wallpaper = os.path.join(target_dir, "background.jpg")
    try:
        shutil.copy2(wallpaper_path, target_wallpaper)
    except Exception as e:
        print(f"Error copying wallpaper: {e}")

    # 5. Write colors.conf (Hyprland format)
    colors_conf = f"""$primary = rgba({hex_primary.lstrip('#')}ff)
$background = rgba({hex_bg.lstrip('#')}b8)
$surface = rgba({hex_bg_soft.lstrip('#')}ad)
$text = rgba({hex_text.lstrip('#')}ff)
$subtext = rgba({hex_subtext.lstrip('#')}ff)
$border = rgba({hex_primary.lstrip('#')}47)
$font_family = Inter
$font_family_bold = Inter Bold
"""
    with open(os.path.join(target_dir, "colors.conf"), "w") as f:
        f.write(colors_conf)

    # 6. Write colors.css (Waybar/SwayNC/GTK CSS format)
    colors_css = f"""@define-color primary {hex_primary};
@define-color background rgba({bg_rgb[0]}, {bg_rgb[1]}, {bg_rgb[2]}, 0.85);
@define-color surface rgba({bg_soft_rgb[0]}, {bg_soft_rgb[1]}, {bg_soft_rgb[2]}, 0.80);
@define-color text {hex_text};
@define-color subtext {hex_subtext};
@define-color border rgba({primary_rgb[0]}, {primary_rgb[1]}, {primary_rgb[2]}, 0.25);
"""
    with open(os.path.join(target_dir, "colors.css"), "w") as f:
        f.write(colors_css)

    # 7. Write colors.rasi (Rofi format)
    colors_rasi = f"""* {{
    background:             rgba({bg_rgb[0]}, {bg_rgb[1]}, {bg_rgb[2]}, 0.90);
    background-alt:         rgba({bg_alt_rgb[0]}, {bg_alt_rgb[1]}, {bg_alt_rgb[2]}, 0.95);
    background-soft:        rgba({bg_soft_rgb[0]}, {bg_soft_rgb[1]}, {bg_soft_rgb[2]}, 1.0);
    background-hover:       rgba({bg_hover_rgb[0]}, {bg_hover_rgb[1]}, {bg_hover_rgb[2]}, 1.0);
    foreground:             {hex_text}ff;
    foreground-muted:       {hex_subtext}ff;
    selected:               {hex_primary}ff;
    edge:                   rgba({primary_rgb[0]}, {primary_rgb[1]}, {primary_rgb[2]}, 0.35);
    active:                 {hex_primary}ff;
    urgent:                 #f38ba8ff;
}}
"""
    with open(os.path.join(target_dir, "colors.rasi"), "w") as f:
        f.write(colors_rasi)

    # 8. Write colors.lua (Hyprland Lua format)
    colors_lua = f"""return {{
    primary = "rgba({hex_primary.lstrip('#')}ff)",
    background = "rgba({hex_bg.lstrip('#')}b8)",
    surface = "rgba({hex_bg_soft.lstrip('#')}ad)",
    text = "rgba({hex_text.lstrip('#')}ff)",
    subtext = "rgba({hex_subtext.lstrip('#')}ff)",
    border = "rgba({hex_primary.lstrip('#')}47)",
    border_inactive = "rgba({hex_bg_soft.lstrip('#')}aa)",
}}
"""
    with open(os.path.join(target_dir, "colors.lua"), "w") as f:
        f.write(colors_lua)

    print("Theme generated successfully!")

if __name__ == "__main__":
    main()
