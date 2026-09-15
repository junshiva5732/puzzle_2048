"""Google Play 스토어 등록용 이미지 생성 (ko / en / ja).
실행: python tool/make_store_assets.py [ko|en|ja ...]   (인자 없으면 세 언어 모두)
입력: assets/icon/icon.png, store/raw/<lang>/*.png (에뮬레이터 스크린샷 720x1280)
출력: store/icon-512.png, store/<lang>/feature-graphic.png, store/<lang>/screenshots/NN.png (1080x1920)
"""
import os
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.join(os.path.dirname(__file__), "..")
STORE = os.path.join(ROOT, "store")
RAW = os.path.join(STORE, "raw")

# 아이콘과 같은 갈색 그라데이션 + 금색 포인트
TOP = (160, 138, 116)
BOTTOM = (112, 92, 74)
CREAM = (249, 246, 242)
GOLD = (237, 194, 46)
FONT_NUM = r"C:\Windows\Fonts\ariblk.ttf"

# 언어별 폰트와 문구
LANGS = {
    "ko": {
        "bold": r"C:\Windows\Fonts\malgunbd.ttf",
        "reg": r"C:\Windows\Fonts\malgun.ttf",
        "tagline": "밀고, 합치고, 2048 도전!",
        "sub": "되돌리기 · 이어하기 · 최고 기록",
        "shots": [
            ("s_play1.png", "밀어서 합치는", "중독성 숫자 퍼즐"),
            ("s_play2.png", "같은 숫자를 합쳐", "2048을 만들어 보세요"),
            ("s_over.png", "실수했다면", "되돌리기와 이어하기"),
            ("s_help.png", "회원가입 없이", "바로 시작하는 두뇌 게임"),
        ],
    },
    "en": {
        "bold": r"C:\Windows\Fonts\segoeuib.ttf",
        "reg": r"C:\Windows\Fonts\segoeui.ttf",
        "tagline": "Swipe. Merge. Reach 2048!",
        "sub": "Undo  ·  Continue  ·  Best score",
        "shots": [
            ("s_play1.png", "Swipe to merge", "Addictive number puzzle"),
            ("s_play2.png", "Join matching tiles", "and reach 2048"),
            ("s_over.png", "Made a mistake?", "Undo or keep going"),
            ("s_help.png", "No sign-up needed", "Just tap and play"),
        ],
    },
    "ja": {
        "bold": r"C:\Windows\Fonts\YuGothB.ttc",
        "reg": r"C:\Windows\Fonts\YuGothM.ttc",
        "tagline": "スワイプして合体、2048に挑戦！",
        "sub": "戻す ・ 続ける ・ ベストスコア",
        "shots": [
            ("s_play1.png", "スワイプで合体する", "ハマる数字パズル"),
            ("s_play2.png", "同じ数字を合わせて", "2048を作ろう"),
            ("s_over.png", "ミスしても大丈夫", "戻す・続けるで再挑戦"),
            ("s_help.png", "登録不要", "すぐに遊べる脳トレ"),
        ],
    },
}


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


def fit_font(draw, text, path, size, max_w):
    """max_w 를 넘지 않도록 폰트 크기를 줄인다."""
    while size > 20:
        f = font(path, size)
        if draw.textlength(text, font=f) <= max_w:
            return f
        size -= 2
    return font(path, size)


# ---------------------------------------------------------------- 512 아이콘 (언어 공통)
icon = Image.open(os.path.join(ROOT, "assets", "icon", "icon.png")).convert("RGB")
icon.resize((512, 512), Image.LANCZOS).save(os.path.join(STORE, "icon-512.png"))


def build(lang):
    L = LANGS[lang]
    out = os.path.join(STORE, lang)
    shots_dir = os.path.join(out, "screenshots")
    os.makedirs(shots_dir, exist_ok=True)
    raw = os.path.join(RAW, lang)

    # ------------------------------------------------------------ 피처 그래픽 1024x500
    W, H = 1024, 500
    fg = gradient(W, H).convert("RGBA")
    isz = 300
    ic = icon.resize((isz, isz), Image.LANCZOS).convert("RGBA")
    ipos = (90, (H - isz) // 2)
    shadow(fg, (isz, isz), ipos, 64)
    fg.paste(ic, ipos, rounded_mask((isz, isz), 64))

    d = ImageDraw.Draw(fg)
    tx = 450
    d.text((tx, 92), "2048", font=font(FONT_NUM, 110), fill=GOLD)
    d.text((tx + 4, 258), L["tagline"], font=fit_font(d, L["tagline"], L["bold"], 40, W - tx - 40), fill=CREAM)
    d.text((tx + 4, 318), L["sub"], font=fit_font(d, L["sub"], L["reg"], 28, W - tx - 40), fill=(232, 224, 212))
    fg.convert("RGB").save(os.path.join(out, "feature-graphic.png"))

    # ------------------------------------------------------------ 스크린샷 1080x1920
    SW, SH = 1080, 1920
    for n, (fname, line1, line2) in enumerate(L["shots"], start=1):
        bg = gradient(SW, SH).convert("RGBA")
        d = ImageDraw.Draw(bg)

        # 상단 캡션
        for text, path, size, y, col in ((line1, L["reg"], 58, 150, CREAM), (line2, L["bold"], 76, 230, GOLD)):
            f = fit_font(d, text, path, size, SW - 120)
            w = d.textlength(text, font=f)
            d.text(((SW - w) / 2, y), text, font=f, fill=col)

        # 폰 스크린샷 (상태바와 하단 테스트 배너·내비 바 잘라내고 둥근 모서리)
        src = Image.open(os.path.join(raw, fname)).convert("RGBA")
        src = src.crop((0, 48, src.width, src.height - 175))
        ph = SH - 420
        pw = int(src.width * ph / src.height)
        src = src.resize((pw, ph), Image.LANCZOS)
        ppos = ((SW - pw) // 2, 380)
        shadow(bg, (pw, ph), ppos, 48)
        border = Image.new("RGBA", (pw + 16, ph + 16), (255, 255, 255, 60))
        bg.paste(border, (ppos[0] - 8, ppos[1] - 8), rounded_mask((pw + 16, ph + 16), 56))
        bg.paste(src, ppos, rounded_mask((pw, ph), 48))

        bg.convert("RGB").save(os.path.join(shots_dir, f"{n:02d}.png"))
    print("done:", os.path.abspath(out))


for lang in (sys.argv[1:] or LANGS):
    build(lang)
