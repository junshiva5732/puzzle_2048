"""Google Play 스토어 등록용 이미지 생성.
실행: python tool/make_store_assets.py
입력: assets/icon/icon.png, store/raw/*.png (에뮬레이터 스크린샷 720x1280)
출력: store/icon-512.png, store/feature-graphic.png, store/screenshots/NN.png (1080x1920)
"""
import os

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.join(os.path.dirname(__file__), "..")
STORE = os.path.join(ROOT, "store")
RAW = os.path.join(STORE, "raw")
SHOTS = os.path.join(STORE, "screenshots")
os.makedirs(SHOTS, exist_ok=True)

# 아이콘과 같은 갈색 그라데이션 + 금색 포인트
TOP = (160, 138, 116)
BOTTOM = (112, 92, 74)
CREAM = (249, 246, 242)
GOLD = (237, 194, 46)

FONT_BOLD = r"C:\Windows\Fonts\malgunbd.ttf"
FONT_REG = r"C:\Windows\Fonts\malgun.ttf"
FONT_NUM = r"C:\Windows\Fonts\ariblk.ttf"


def font(path, size):
    return ImageFont.truetype(path, size)


def gradient(w, h):
    img = Image.new("RGB", (w, h))
    px = img.load()
    for y in range(h):
        for x in range(w):
            k = (y / max(h - 1, 1)) * 0.65 + (x / max(w - 1, 1)) * 0.35
            px[x, y] = tuple(int(TOP[i] + (BOTTOM[i] - TOP[i]) * k) for i in range(3))
    return img


def rounded_mask(size, radius):
    m = Image.new("L", size, 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, size[0] - 1, size[1] - 1], radius=radius, fill=255)
    return m


def shadow(base, box_size, pos, radius, blur=40, alpha=110):
    sh = Image.new("RGBA", base.size, (0, 0, 0, 0))
    layer = Image.new("RGBA", box_size, (0, 0, 0, alpha))
    sh.paste(layer, (pos[0], pos[1] + 24), rounded_mask(box_size, radius))
    sh = sh.filter(ImageFilter.GaussianBlur(blur))
    base.alpha_composite(sh)


# ---------------------------------------------------------------- 512 아이콘
icon = Image.open(os.path.join(ROOT, "assets", "icon", "icon.png")).convert("RGB")
icon.resize((512, 512), Image.LANCZOS).save(os.path.join(STORE, "icon-512.png"))

# ---------------------------------------------------------------- 피처 그래픽 1024x500
W, H = 1024, 500
fg = gradient(W, H).convert("RGBA")

# 왼쪽: 둥근 아이콘
isz = 300
ic = icon.resize((isz, isz), Image.LANCZOS).convert("RGBA")
ipos = (90, (H - isz) // 2)
shadow(fg, (isz, isz), ipos, 64)
fg.paste(ic, ipos, rounded_mask((isz, isz), 64))

# 오른쪽: 텍스트
d = ImageDraw.Draw(fg)
tx = 450
d.text((tx, 92), "2048", font=font(FONT_NUM, 110), fill=GOLD)
d.text((tx + 4, 258), "밀고, 합치고, 2048 도전!", font=font(FONT_BOLD, 40), fill=CREAM)
d.text((tx + 4, 318), "되돌리기 · 최고 기록 · 이어하기", font=font(FONT_REG, 28), fill=(232, 224, 212))
fg.convert("RGB").save(os.path.join(STORE, "feature-graphic.png"))

# ---------------------------------------------------------------- 스크린샷 1080x1920
SW, SH = 1080, 1920
shots = [
    ("s_play1.png", "밀어서 합치는", "중독성 숫자 퍼즐"),
    ("s_play2.png", "같은 숫자를 합쳐", "2048을 만들어 보세요"),
    ("s_over.png", "실수했다면", "되돌리기로 한 번 더"),
    ("s_help.png", "회원가입 없이", "바로 시작하는 가벼운 게임"),
]
for n, (fname, line1, line2) in enumerate(shots, start=1):
    bg = gradient(SW, SH).convert("RGBA")
    d = ImageDraw.Draw(bg)

    # 상단 캡션
    f1 = font(FONT_REG, 58)
    f2 = font(FONT_BOLD, 76)
    for text, f, y, col in ((line1, f1, 150, CREAM), (line2, f2, 230, GOLD)):
        w = d.textlength(text, font=f)
        d.text(((SW - w) / 2, y), text, font=f, fill=col)

    # 폰 스크린샷 (상태바와 하단 테스트 배너·내비 바 잘라내고 둥근 모서리)
    src = Image.open(os.path.join(RAW, fname)).convert("RGBA")
    src = src.crop((0, 48, src.width, src.height - 175))
    ph = SH - 420
    pw = int(src.width * ph / src.height)
    src = src.resize((pw, ph), Image.LANCZOS)
    ppos = ((SW - pw) // 2, 380)
    shadow(bg, (pw, ph), ppos, 48)
    # 테두리
    border = Image.new("RGBA", (pw + 16, ph + 16), (255, 255, 255, 60))
    bg.paste(border, (ppos[0] - 8, ppos[1] - 8), rounded_mask((pw + 16, ph + 16), 56))
    bg.paste(src, ppos, rounded_mask((pw, ph), 48))

    bg.convert("RGB").save(os.path.join(SHOTS, f"{n:02d}.png"))

print("done:", os.path.abspath(STORE))
