"""Draws the Gambade app icons (PNG) from the shapes of docs/conception/logo.svg.

The logo is only a rounded square and 5 ellipses, so they are painted pixel by pixel:
no image tool to install. Run from the project root:  python3 script/generate_icons.py
"""
import math
import struct
import zlib

FOREST = (0x2F, 0x5D, 0x50)
SAND = (0xF5, 0xF0, 0xE6)

# Paw shapes in the 100x100 logo: (center x, center y, radius x, radius y, rotation in degrees)
PAW = [(50, 63, 17, 14, 0), (29, 44, 7, 9, -20), (42, 32, 7, 9.5, -6), (58, 32, 7, 9.5, 6), (71, 44, 7, 9, 20)]


def in_ellipse(x, y, cx, cy, rx, ry, angle):
    a = math.radians(-angle)
    dx, dy = x - cx, y - cy
    ux = dx * math.cos(a) - dy * math.sin(a)
    uy = dx * math.sin(a) + dy * math.cos(a)
    return (ux / rx) ** 2 + (uy / ry) ** 2 <= 1


def in_rounded_square(x, y, radius):
    nearest_x = min(max(x, radius), 100 - radius)
    nearest_y = min(max(y, radius), 100 - radius)
    return (x - nearest_x) ** 2 + (y - nearest_y) ** 2 <= radius**2


def draw(size, full_bleed):
    """full_bleed: square without rounded corners and a smaller paw (Android "maskable" icons are cut into a circle)."""
    paw_scale = 0.8 if full_bleed else 1.0
    samples = [(0.25, 0.25), (0.75, 0.25), (0.25, 0.75), (0.75, 0.75)]  # 4 samples per pixel: smooth edges
    rows = []
    for py in range(size):
        row = bytearray([0])  # PNG filter type "none"
        for px in range(size):
            r = g = b = alpha = 0
            for sx, sy in samples:
                x, y = (px + sx) * 100 / size, (py + sy) * 100 / size
                if not full_bleed and not in_rounded_square(x, y, 24):
                    continue  # transparent corner
                lx, ly = 50 + (x - 50) / paw_scale, 50 + (y - 50) / paw_scale
                color = SAND if any(in_ellipse(lx, ly, *shape) for shape in PAW) else FOREST
                r, g, b, alpha = r + color[0], g + color[1], b + color[2], alpha + 255
            n = len(samples)
            row += bytes([r // n, g // n, b // n, alpha // n])
        rows.append(bytes(row))
    return png(size, b"".join(rows))


def png(size, raw):
    def chunk(kind, data):
        return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF)

    header = struct.pack(">IIBBBBB", size, size, 8, 6, 0, 0, 0)  # 8 bits, RGBA
    return b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", header) + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b"")


if __name__ == "__main__":
    icons = {"public/icon.png": (512, False), "public/icon-192.png": (192, False),
             "public/icon-maskable.png": (512, True), "public/apple-touch-icon.png": (180, True)}
    for path, (size, full_bleed) in icons.items():
        with open(path, "wb") as file:
            file.write(draw(size, full_bleed))
        print(f"{path} ({size}x{size})")
