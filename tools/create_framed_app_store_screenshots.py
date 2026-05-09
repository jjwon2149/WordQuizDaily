from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "AppStoreScreenshots"
SOURCE_DIR = Path("/Users/smith/Downloads")

CANVAS_W = 1242
CANVAS_H = 2688
REF_W = 1242
REF_H = 2688
FONT = "/System/Library/Fonts/AppleSDGothicNeo.ttc"


def sx(value: int) -> int:
    return round(value * CANVAS_W / REF_W)


def sy(value: int) -> int:
    return round(value * CANVAS_H / REF_H)


def font(size: int, weight: str = "regular") -> ImageFont.FreeTypeFont:
    indexes = {
        "regular": 0,
        "medium": 2,
        "semibold": 4,
        "bold": 6,
        "light": 8,
    }
    return ImageFont.truetype(FONT, size=size, index=indexes[weight])


def fit_cover(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    target_w, target_h = size
    scale = max(target_w / image.width, target_h / image.height)
    resized = image.resize((round(image.width * scale), round(image.height * scale)), Image.Resampling.LANCZOS)
    left = (resized.width - target_w) // 2
    top = (resized.height - target_h) // 2
    return resized.crop((left, top, left + target_w, top + target_h))


def fit_contain(image: Image.Image, size: tuple[int, int], fill=(255, 255, 255, 255)) -> Image.Image:
    target_w, target_h = size
    scale = min(target_w / image.width, target_h / image.height)
    resized = image.resize((round(image.width * scale), round(image.height * scale)), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", size, fill)
    canvas.alpha_composite(resized, ((target_w - resized.width) // 2, (target_h - resized.height) // 2))
    return canvas


def rounded_mask(size: tuple[int, int], radius: int) -> Image.Image:
    mask = Image.new("L", size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle((0, 0, size[0], size[1]), radius=radius, fill=255)
    return mask


def gradient_bg(top: tuple[int, int, int], bottom: tuple[int, int, int]) -> Image.Image:
    img = Image.new("RGBA", (CANVAS_W, CANVAS_H), top + (255,))
    pixels = img.load()
    for y in range(CANVAS_H):
        t = y / (CANVAS_H - 1)
        color = tuple(int(top[i] * (1 - t) + bottom[i] * t) for i in range(3))
        for x in range(CANVAS_W):
            pixels[x, y] = color + (255,)
    return img


def soft_blob(base: Image.Image, xy: tuple[int, int], radius: int, color: tuple[int, int, int, int]) -> None:
    layer = Image.new("RGBA", base.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    x, y = xy
    draw.ellipse((x - radius, y - radius, x + radius, y + radius), fill=color)
    layer = layer.filter(ImageFilter.GaussianBlur(radius // 8))
    base.alpha_composite(layer)


def multiline_center(draw: ImageDraw.ImageDraw, text: str, y: int, typeface: ImageFont.FreeTypeFont, fill) -> int:
    line_gap = 10
    for line in text.split("\n"):
        draw.text((CANVAS_W // 2, y), line, font=typeface, fill=fill, anchor="ma")
        bbox = draw.textbbox((0, 0), line, font=typeface)
        y += bbox[3] - bbox[1] + line_gap
    return y


def draw_header(draw: ImageDraw.ImageDraw, title: str, subtitle: str) -> None:
    title_font = font(sy(76), "bold")
    subtitle_font = font(sy(33), "semibold")
    y = multiline_center(draw, title, sy(122), title_font, (28, 36, 54, 255))
    draw.text(
        (CANVAS_W // 2, y + sy(34)),
        subtitle,
        font=subtitle_font,
        fill=(143, 151, 165, 255),
        anchor="ma",
    )


def paste_phone(base: Image.Image, source: str, crop: tuple[int, int, int, int], fit: str = "contain") -> None:
    phone = (sx(72), sy(478), sx(1170), sy(2644))
    inner = (sx(114), sy(530), sx(1128), sy(2596))
    outer_radius = sy(78)
    inner_radius = sy(58)

    shadow = Image.new("RGBA", base.size, (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    shadow_draw.rounded_rectangle(
        (phone[0], phone[1] + sy(28), phone[2], phone[3] + sy(28)),
        radius=outer_radius,
        fill=(30, 41, 59, 42),
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(sy(26)))
    base.alpha_composite(shadow)

    draw = ImageDraw.Draw(base)
    draw.rounded_rectangle(phone, radius=outer_radius, fill=(255, 255, 255, 255))

    source_img = Image.open(SOURCE_DIR / source).convert("RGBA").crop(crop)
    inner_size = (inner[2] - inner[0], inner[3] - inner[1])
    if fit == "cover":
        screen = fit_cover(source_img, inner_size)
    else:
        screen = fit_contain(source_img, inner_size, fill=(246, 247, 251, 255))

    base.paste(screen, (inner[0], inner[1]), rounded_mask(inner_size, inner_radius))
    draw.rounded_rectangle(phone, radius=outer_radius, outline=(255, 255, 255, 235), width=sy(10))
    draw.rounded_rectangle((inner[0], inner[1], inner[2], inner[3]), radius=inner_radius, outline=(223, 228, 238, 180), width=sy(2))


def make_slide(spec: dict) -> Path:
    base = gradient_bg(spec["bg_top"], spec["bg_bottom"])
    soft_blob(base, spec["blob_left"], 250, spec["blob_left_color"])
    soft_blob(base, spec["blob_right"], 260, spec["blob_right_color"])
    draw = ImageDraw.Draw(base)
    draw_header(draw, spec["title"], spec["subtitle"])
    paste_phone(base, spec["source"], spec["crop"], spec.get("fit", "contain"))

    out = OUT_DIR / spec["output"]
    base.convert("RGB").save(out, "PNG", optimize=True)
    return out


def make_contact_sheet(paths: list[Path]) -> Path:
    thumb_w = 207
    thumb_h = 448
    margin = 18
    sheet = Image.new("RGB", (thumb_w * len(paths) + margin * (len(paths) + 1), thumb_h + margin * 2), (246, 248, 251))
    for i, path in enumerate(paths):
        img = Image.open(path).convert("RGB").resize((thumb_w, thumb_h), Image.Resampling.LANCZOS)
        sheet.paste(img, (margin + i * (thumb_w + margin), margin))
    out = OUT_DIR / f"preview_{CANVAS_W}x{CANVAS_H}.png"
    sheet.save(out, "PNG", optimize=True)
    return out


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    specs = [
        {
            "output": "01_quiz.png",
            "source": "IMG_4807.PNG",
            "title": "뜻을 보고\n정답을 고르는 퀴즈",
            "subtitle": "매일 새로운 우리말 단어를 익혀요",
            "crop": (0, 0, 1170, 2532),
            "fit": "contain",
            "bg_top": (255, 253, 248),
            "bg_bottom": (246, 250, 255),
            "blob_left": (-10, 340),
            "blob_left_color": (232, 244, 255, 255),
            "blob_right": (1180, 520),
            "blob_right_color": (227, 248, 237, 255),
        },
        {
            "output": "02_answer.png",
            "source": "IMG_4808.PNG",
            "title": "정답과 해설을\n바로 확인",
            "subtitle": "뜻, 난이도, 예문까지 한 번에",
            "crop": (0, 0, 1170, 2532),
            "fit": "contain",
            "bg_top": (255, 251, 246),
            "bg_bottom": (247, 250, 255),
            "blob_left": (-20, 360),
            "blob_left_color": (255, 232, 218, 255),
            "blob_right": (1180, 510),
            "blob_right_color": (232, 243, 255, 255),
        },
        {
            "output": "03_today_word.png",
            "source": "IMG_4809.PNG",
            "title": "오늘의 단어를\n쉽게 복습",
            "subtitle": "발음과 예문으로 자연스럽게 익혀요",
            "crop": (0, 650, 1170, 2532),
            "fit": "cover",
            "bg_top": (252, 253, 255),
            "bg_bottom": (248, 252, 247),
            "blob_left": (-12, 370),
            "blob_left_color": (239, 244, 255, 255),
            "blob_right": (1180, 530),
            "blob_right_color": (255, 244, 216, 255),
        },
        {
            "output": "04_reminder.png",
            "source": "IMG_4811.PNG",
            "title": "원하는 시간에\n학습 알림",
            "subtitle": "하루 한 번, 꾸준한 어휘 습관",
            "crop": (0, 645, 1170, 2532),
            "fit": "cover",
            "bg_top": (249, 255, 252),
            "bg_bottom": (247, 249, 255),
            "blob_left": (-22, 365),
            "blob_left_color": (225, 250, 235, 255),
            "blob_right": (1180, 520),
            "blob_right_color": (233, 242, 255, 255),
        },
        {
            "output": "05_settings.png",
            "source": "IMG_4810.PNG",
            "title": "필요한 설정을\n깔끔하게 관리",
            "subtitle": "알림과 지원 정보를 쉽게 확인해요",
            "crop": (0, 650, 1170, 2532),
            "fit": "cover",
            "bg_top": (253, 253, 255),
            "bg_bottom": (247, 250, 252),
            "blob_left": (-20, 360),
            "blob_left_color": (242, 245, 255, 255),
            "blob_right": (1180, 520),
            "blob_right_color": (255, 240, 218, 255),
        },
    ]

    outputs = [make_slide(spec) for spec in specs]
    preview = make_contact_sheet(outputs)
    print("Generated:")
    for output in outputs:
        print(output)
    print(preview)


if __name__ == "__main__":
    main()
