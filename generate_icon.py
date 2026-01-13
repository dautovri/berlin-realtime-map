#!/usr/bin/env python3
"""
Generate app icon for Berlin Transport Map
A modern icon featuring Berlin transit colors and a live location concept
"""

from PIL import Image, ImageDraw, ImageFont, ImageFilter
import math
import os

def create_app_icon(size=1024):
    """Create a modern app icon for Berlin Transport Map"""
    
    # Create base image with gradient background
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Berlin transport colors
    ubahn_blue = (0, 91, 152)  # U-Bahn blue
    sbahn_green = (0, 128, 0)  # S-Bahn green
    tram_red = (204, 0, 0)     # Tram red
    bus_purple = (128, 0, 128) # Bus purple
    
    # Background gradient - deep blue to purple
    for y in range(size):
        ratio = y / size
        r = int(25 + ratio * 30)
        g = int(25 + ratio * 15)
        b = int(80 + ratio * 60)
        for x in range(size):
            # Add slight radial gradient
            dx = x - size/2
            dy = y - size/2
            dist = math.sqrt(dx*dx + dy*dy) / (size/2)
            factor = max(0, 1 - dist * 0.3)
            draw.point((x, y), fill=(
                int(r + 20 * factor),
                int(g + 10 * factor),
                int(b + 30 * factor)
            ))
    
    # Draw stylized map/transit lines in background
    line_width = size // 40
    
    # U-Bahn style curved line (blue)
    points_u = []
    for i in range(50):
        t = i / 49
        x = size * 0.2 + t * size * 0.6
        y = size * 0.3 + math.sin(t * math.pi * 1.5) * size * 0.15
        points_u.append((x, y))
    draw.line(points_u, fill=(*ubahn_blue, 180), width=line_width)
    
    # S-Bahn style line (green)
    points_s = []
    for i in range(50):
        t = i / 49
        x = size * 0.15 + t * size * 0.7
        y = size * 0.6 + math.sin(t * math.pi * 2) * size * 0.1
        points_s.append((x, y))
    draw.line(points_s, fill=(*sbahn_green, 180), width=line_width)
    
    # Tram line (red, horizontal)
    draw.line([(size*0.1, size*0.75), (size*0.9, size*0.75)], 
              fill=(*tram_red, 150), width=line_width//2)
    
    # Draw small station dots along lines
    dot_radius = size // 60
    for i in range(5):
        t = (i + 1) / 6
        # U-Bahn stations
        x = size * 0.2 + t * size * 0.6
        y = size * 0.3 + math.sin(t * math.pi * 1.5) * size * 0.15
        draw.ellipse([x-dot_radius, y-dot_radius, x+dot_radius, y+dot_radius], 
                     fill=(255, 255, 255, 200))
        # S-Bahn stations
        x = size * 0.15 + t * size * 0.7
        y = size * 0.6 + math.sin(t * math.pi * 2) * size * 0.1
        draw.ellipse([x-dot_radius, y-dot_radius, x+dot_radius, y+dot_radius], 
                     fill=(255, 255, 255, 200))
    
    # Main location pin in center
    pin_center_x = size // 2
    pin_center_y = size // 2 - size // 20
    pin_height = size * 0.4
    pin_width = size * 0.28
    
    # Pin shadow
    shadow_offset = size // 40
    draw_pin(draw, pin_center_x + shadow_offset, pin_center_y + shadow_offset, 
             pin_width, pin_height, (0, 0, 0, 80))
    
    # Main pin with gradient effect (bright cyan/teal)
    draw_pin(draw, pin_center_x, pin_center_y, pin_width, pin_height, 
             (0, 200, 220, 255))
    
    # Inner circle on pin (white with live indicator)
    inner_radius = pin_width * 0.28
    inner_y = pin_center_y - pin_height * 0.2
    draw.ellipse([pin_center_x - inner_radius, inner_y - inner_radius,
                  pin_center_x + inner_radius, inner_y + inner_radius],
                 fill=(255, 255, 255, 255))
    
    # Live pulse rings
    pulse_colors = [(0, 200, 220, 100), (0, 200, 220, 60), (0, 200, 220, 30)]
    for i, color in enumerate(pulse_colors):
        pulse_radius = inner_radius * (1.4 + i * 0.4)
        draw.ellipse([pin_center_x - pulse_radius, inner_y - pulse_radius,
                      pin_center_x + pulse_radius, inner_y + pulse_radius],
                     outline=color, width=size//80)
    
    # Transit vehicle icon inside pin (simplified train/tram)
    vehicle_size = inner_radius * 1.2
    draw_vehicle_icon(draw, pin_center_x, inner_y, vehicle_size, (0, 91, 152))
    
    return img

def draw_pin(draw, cx, cy, width, height, color):
    """Draw a location pin shape"""
    # Pin body (circle top, pointed bottom)
    radius = width / 2
    
    # Top circle
    draw.ellipse([cx - radius, cy - height * 0.5, 
                  cx + radius, cy - height * 0.5 + width],
                 fill=color)
    
    # Bottom triangle/point
    points = [
        (cx - radius * 0.7, cy - height * 0.5 + radius * 0.8),
        (cx + radius * 0.7, cy - height * 0.5 + radius * 0.8),
        (cx, cy + height * 0.5)
    ]
    draw.polygon(points, fill=color)

def draw_vehicle_icon(draw, cx, cy, size, color):
    """Draw a simplified transit vehicle icon"""
    # Simple train front view
    half = size / 2
    quarter = size / 4
    
    # Main body rectangle
    draw.rounded_rectangle([cx - half * 0.7, cy - half * 0.6,
                           cx + half * 0.7, cy + half * 0.4],
                          radius=size/8, fill=color)
    
    # Window
    draw.rounded_rectangle([cx - half * 0.45, cy - half * 0.4,
                           cx + half * 0.45, cy - half * 0.05],
                          radius=size/16, fill=(200, 230, 255))
    
    # Headlights
    light_radius = size / 12
    draw.ellipse([cx - half * 0.4 - light_radius, cy + half * 0.15 - light_radius,
                  cx - half * 0.4 + light_radius, cy + half * 0.15 + light_radius],
                 fill=(255, 255, 200))
    draw.ellipse([cx + half * 0.4 - light_radius, cy + half * 0.15 - light_radius,
                  cx + half * 0.4 + light_radius, cy + half * 0.15 + light_radius],
                 fill=(255, 255, 200))

def create_dark_variant(img):
    """Create dark mode variant"""
    dark = img.copy()
    # Slightly adjust for dark mode - make background darker
    pixels = dark.load()
    for y in range(dark.height):
        for x in range(dark.width):
            r, g, b, a = pixels[x, y]
            # Darken the background slightly
            pixels[x, y] = (max(0, r-10), max(0, g-10), max(0, b-5), a)
    return dark

def create_tinted_variant(img):
    """Create tinted (monochrome) variant for iOS"""
    tinted = Image.new('RGBA', img.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(tinted)
    
    size = img.size[0]
    
    # Simple monochrome version - just the pin outline
    pin_center_x = size // 2
    pin_center_y = size // 2 - size // 20
    pin_height = size * 0.4
    pin_width = size * 0.28
    
    # Draw pin outline
    draw_pin(draw, pin_center_x, pin_center_y, pin_width, pin_height, 
             (255, 255, 255, 255))
    
    # Inner circle
    inner_radius = pin_width * 0.28
    inner_y = pin_center_y - pin_height * 0.2
    draw.ellipse([pin_center_x - inner_radius * 0.7, inner_y - inner_radius * 0.7,
                  pin_center_x + inner_radius * 0.7, inner_y + inner_radius * 0.7],
                 fill=(0, 0, 0, 255))
    
    return tinted

def main():
    output_dir = "/Users/rd/Documents/GitHub/berlin-realtime-map/BerlinTransportMap/Assets.xcassets/AppIcon.appiconset"
    
    print("Generating Berlin Transport Map icon...")
    
    # Create main icon
    icon = create_app_icon(1024)
    
    # Save main icon
    icon_path = os.path.join(output_dir, "AppIcon.png")
    icon.save(icon_path, "PNG")
    print(f"✓ Saved main icon: {icon_path}")
    
    # Create and save dark variant
    dark_icon = create_dark_variant(icon)
    dark_path = os.path.join(output_dir, "AppIcon-Dark.png")
    dark_icon.save(dark_path, "PNG")
    print(f"✓ Saved dark icon: {dark_path}")
    
    # Create and save tinted variant
    tinted_icon = create_tinted_variant(icon)
    tinted_path = os.path.join(output_dir, "AppIcon-Tinted.png")
    tinted_icon.save(tinted_path, "PNG")
    print(f"✓ Saved tinted icon: {tinted_path}")
    
    # Update Contents.json
    contents = {
        "images": [
            {
                "filename": "AppIcon.png",
                "idiom": "universal",
                "platform": "ios",
                "size": "1024x1024"
            },
            {
                "appearances": [
                    {"appearance": "luminosity", "value": "dark"}
                ],
                "filename": "AppIcon-Dark.png",
                "idiom": "universal",
                "platform": "ios",
                "size": "1024x1024"
            },
            {
                "appearances": [
                    {"appearance": "luminosity", "value": "tinted"}
                ],
                "filename": "AppIcon-Tinted.png",
                "idiom": "universal",
                "platform": "ios",
                "size": "1024x1024"
            }
        ],
        "info": {
            "author": "xcode",
            "version": 1
        }
    }
    
    import json
    contents_path = os.path.join(output_dir, "Contents.json")
    with open(contents_path, 'w') as f:
        json.dump(contents, f, indent=2)
    print(f"✓ Updated Contents.json")
    
    print("\n🎉 App icon generation complete!")

if __name__ == "__main__":
    main()
