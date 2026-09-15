"""앱 아이콘 생성 스크립트. 실행: python tool/make_icon.py
assets/icon/icon.png (1024x1024, 배경 포함) 과
assets/icon/icon_fg.png (Android adaptive 전경, 투명 배경) 을 만든다."""
import os

from PIL import Image, ImageDraw, ImageFilter, ImageFont

SIZE = 1024
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "icon")
os.makedirs(OUT, exist_ok=True)

# 배경: 앱 버튼색(#8F7A66) 계열 갈색 그라데이션, 타일: 2048 타일 색(#EDC22E)
TOP = (160, 138, 116)
BOTTOM = (112, 92, 74)
TILE = (237, 194, 46)
TILE_EDGE = (215, 168, 25)
TEXT = (249, 246, 242)
FONT = r"C:\Windows\Fonts\ariblk.ttf"  # Arial Black


def gradient_bg(size):
    img = Image.new("RGB", (size, size))
    px = img.load()
    for y in range(size):
        t = y / (size - 1)
        for x in range(size):
            k = t * 0.7 + (x / (size - 1)) * 0.3
            px[x, y] = tuple(int(TOP[i] + (BOTTOM[i] - TOP[i]) * k) for i in range(3))
    return img


def draw_symbol(layer, scale=1.0):
    """가운데 둥근 타일 + '2048' 글자. layer 는 RGBA."""
    d = ImageDraw.Draw(layer)
    s = SIZE * scale
    cx = cy = SIZE / 2
    half = s * 0.36
    r = s * 0.075
    # 타일 그림자
    sh = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    ImageDraw.Draw(sh).rounded_rectangle(
        [cx - half, cy - half + s * 0.02, cx + half, cy + half + s * 0.02], radius=r, fill=(90, 60, 0, 110))
    sh = sh.filter(ImageFilter.GaussianBlur(s * 0.02))
    layer.alpha_composite(sh)
    # 타일 본체
    d.rounded_rectangle([cx - half, cy - half, cx + half, cy + half], radius=r, fill=TILE + (255,),
                        outline=TILE_EDGE + (255,), width=int(s * 0.006))
    # 글자 (두 줄: 20 / 48) — 작은 크기에서도 읽히도록 크게
    f = ImageFont.truetype(FONT, int(s * 0.30))
    for text, dy in (("20", -s * 0.15), ("48", s * 0.15)):
        bbox = d.textbbox((0, 0), text, font=f)
        w, h = bbox[2] - bbox[0], bbox[3] - bbox[1]
        d.text((cx - w / 2 - bbox[0], cy + dy - h / 2 - bbox[1]), text, font=f, fill=TEXT + (255,))


# 1) 풀 아이콘 (iOS / 스토어용, 불투명)
bg = gradient_bg(SIZE).convert("RGBA")
sym = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
draw_symbol(sym)
bg.alpha_composite(sym)
bg.convert("RGB").save(os.path.join(OUT, "icon.png"))

# 2) Adaptive 전경 (Android): 배경 없이 타일만. flutter_launcher_icons 가 16% 인셋을 넣는다.
fg = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
draw_symbol(fg, scale=1.15)
fg.save(os.path.join(OUT, "icon_fg.png"))

print("written:", os.path.abspath(OUT))
