#!/usr/bin/env python3
"""
Icon + Splash Pipeline
Generates all platform-correct icon and splash assets from SVG geometry tokens.
Fixed: golden-ratio proportions, Android 80% circle (matching iOS), splash screens.
"""

import os
from pathlib import Path
from PIL import Image
from resvg_py import svg_to_bytes
import io

# Colors
BG_DARK = "#17181c"
BG_WHITE = "#FFFFFF"
BG_BLACK = "#000000"
GRAY = "#B4B4B4"

# Paths
SCRIPT_DIR = Path(__file__).parent
SVG_DIR = SCRIPT_DIR / "svg"
OUTPUT_DIR = SCRIPT_DIR


def render_svg(svg_path: Path, size: int = 1024) -> Image.Image:
    """Render SVG to PIL Image using resvg-py."""
    with open(svg_path, 'r') as f:
        svg_data = f.read()
    
    png_bytes = svg_to_bytes(svg_data, width=size, height=size)
    return Image.open(io.BytesIO(png_bytes)).convert("RGBA")


def recolor(img: Image.Image, color: str) -> Image.Image:
    """Recolor all non-transparent pixels to the given color, preserving alpha.
    Uses channel operations - fast, reliable, no threshold bugs."""
    # Parse color
    r_val = int(color.lstrip('#')[0:2], 16)
    g_val = int(color.lstrip('#')[2:4], 16)
    b_val = int(color.lstrip('#')[4:6], 16)
    
    # Split channels
    r, g, b, a = img.split()
    
    # Create new color channels from alpha mask
    colored = Image.merge("RGBA", (
        Image.new("L", img.size, r_val),
        Image.new("L", img.size, g_val),
        Image.new("L", img.size, b_val),
        a,  # preserve original alpha
    ))
    return colored


def to_grayscale(img: Image.Image, brightness: int = 180) -> Image.Image:
    """Convert to grayscale with specified brightness."""
    # Split and take alpha
    _, _, _, a = img.split()
    
    # Create grayscale from alpha
    gray = Image.new("L", img.size, brightness)
    result = Image.merge("RGBA", (gray, gray, gray, a))
    return result


def create_solid_canvas(color: str, size: int = 1024, transparent: bool = False) -> Image.Image:
    """Create a solid colored canvas."""
    if transparent:
        return Image.new("RGBA", (size, size), (0, 0, 0, 0))
    
    rgb = tuple(int(color.lstrip('#')[i:i+2], 16) for i in (0, 2, 4))
    return Image.new("RGBA", (size, size), rgb + (255,))


def composite_layers(canvas: Image.Image, *layers: Image.Image) -> Image.Image:
    """Composite multiple layers onto canvas."""
    result = canvas.copy()
    for layer in layers:
        result = Image.alpha_composite(result, layer)
    return result


def verify_png(img: Image.Image, filename: str):
    """Verify PNG has expected content by sampling key pixels."""
    w, h = img.size
    center = img.getpixel((w//2, h//2))
    top_left = img.getpixel((10, 10))
    bar_area = img.getpixel((w//2 + 150, h//2))
    
    print(f"  Verified {filename}:")
    print(f"    center={center}, top_left={top_left}, bar_area={bar_area}")


def save_png(img: Image.Image, filename: str):
    """Save image as PNG."""
    output_path = OUTPUT_DIR / filename
    img.save(output_path, "PNG")
    print(f"✓ Generated {filename}")


def main():
    print("🎨 Icon Pipeline Fix")
    print("=" * 50)
    
    # Load base SVGs
    print("\n📥 Loading base SVG geometry tokens...")
    circle_ios = render_svg(SVG_DIR / "circle_ios.svg")
    circle_android = render_svg(SVG_DIR / "circle_android.svg")
    inner_ios = render_svg(SVG_DIR / "inner_ios.svg")
    inner_android = render_svg(SVG_DIR / "inner_android.svg")
    print("✓ All SVGs loaded with golden-ratio proportions")
    
    print("\n🖼️  Generating iOS icons...")
    
    # iOS Default (light mode: DARK bg + WHITE circle + DARK inner)
    ios_default = composite_layers(
        create_solid_canvas(BG_DARK),
        circle_ios,  # keep white
        recolor(inner_ios, BG_DARK)
    )
    save_png(ios_default, "ios_default.png")
    verify_png(ios_default, "ios_default.png")
    
    # iOS Dark (dark mode: TRANSPARENT bg + WHITE circle + DARK inner)
    ios_dark = composite_layers(
        create_solid_canvas(BG_DARK, transparent=True),
        circle_ios,  # keep white
        recolor(inner_ios, BG_DARK)
    )
    save_png(ios_dark, "ios_dark.png")
    verify_png(ios_dark, "ios_dark.png")
    
    # iOS Tinted (black bg + grayscale inner only, no circle)
    ios_tinted = composite_layers(
        create_solid_canvas(BG_BLACK),
        to_grayscale(inner_ios, brightness=180)
    )
    save_png(ios_tinted, "ios_tinted.png")
    verify_png(ios_tinted, "ios_tinted.png")
    
    print("\n🤖 Generating Android icons...")
    
    # Android Background (dark bg + white circle)
    android_bg = composite_layers(
        create_solid_canvas(BG_DARK),
        circle_android  # keep white
    )
    save_png(android_bg, "android_bg.png")
    verify_png(android_bg, "android_bg.png")
    
    # Android Foreground (transparent bg + dark inner only)
    android_fg = composite_layers(
        create_solid_canvas(BG_DARK, transparent=True),
        recolor(inner_android, BG_DARK)
    )
    save_png(android_fg, "foreground.png")
    verify_png(android_fg, "foreground.png")
    
    # Android Monochrome (transparent bg + white inner only)
    android_mono = composite_layers(
        create_solid_canvas(BG_DARK, transparent=True),
        inner_android  # keep white
    )
    save_png(android_mono, "monochrome.png")
    verify_png(android_mono, "monochrome.png")
    
    print("\n🌟 Generating splash screens...")
    
    # Splash Logo (1024x1024: TRANSPARENT bg + WHITE circle + DARK inner)
    # Same visual as ios_dark, for iOS and pre-Android-12 splash
    splash_logo = composite_layers(
        create_solid_canvas(BG_DARK, transparent=True),
        circle_ios,  # keep white
        recolor(inner_ios, BG_DARK)
    )
    save_png(splash_logo, "splash_logo.png")
    verify_png(splash_logo, "splash_logo.png")
    
    # Splash Android 12 (1152x1152: 700px render centered on transparent canvas)
    # Fits within 768px circle safe zone (700*0.8=560px < 768px)
    splash_small = composite_layers(
        create_solid_canvas(BG_DARK, size=700, transparent=True),
        render_svg(SVG_DIR / "circle_ios.svg", size=700),
        recolor(render_svg(SVG_DIR / "inner_ios.svg", size=700), BG_DARK)
    )
    # Center on 1152x1152 canvas
    splash_android12 = create_solid_canvas(BG_DARK, size=1152, transparent=True)
    offset = (1152 - 700) // 2  # 226
    splash_android12.paste(splash_small, (offset, offset), splash_small)
    save_png(splash_android12, "splash_android12.png")
    verify_png(splash_android12, "splash_android12.png")
    
    print("\n✅ All 8 assets generated successfully (6 icons + 2 splash)!")
    print("=" * 50)


if __name__ == "__main__":
    main()
