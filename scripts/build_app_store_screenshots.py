#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[1]
ASSET_DIR = ROOT / "docs/StayAwake/main/12-运营素材"
RAW_DIR = ASSET_DIR / "raw"
FINAL_DIR = ASSET_DIR / "final"
FINAL_DIR.mkdir(parents=True, exist_ok=True)
APP_ICON = ROOT / "macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_1024.png"
AI_BACKGROUND = Path(
    "/Users/linzhibin/.codex/generated_images/019f13b7-06bb-7641-b422-ee4c7bc71a7a/"
    "ig_04a1d16418b80156016a447fd3c1c481998251b2802726248d.png"
)

W, H = 2880, 1800


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    candidates = [
        "/System/Library/Fonts/Hiragino Sans GB.ttc",
        "/System/Library/Fonts/Supplemental/Arial Unicode.ttf",
        "/System/Library/Fonts/Helvetica.ttc",
    ]
    for path in candidates:
        try:
            return ImageFont.truetype(path, size=size, index=1 if bold else 0)
        except Exception:
            continue
    return ImageFont.load_default()


TITLE = font(86, True)
SUBTITLE = font(39)
BODY = font(31)
SMALL = font(25)


def rounded_rect(draw: ImageDraw.ImageDraw, box, radius, fill, outline=None, width=1):
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=width)


def gradient_background(accent=(15, 126, 110)) -> Image.Image:
    if AI_BACKGROUND.exists():
        img = Image.open(AI_BACKGROUND).convert("RGB")
        ratio = max(W / img.width, H / img.height)
        size = (int(img.width * ratio), int(img.height * ratio))
        img = img.resize(size, Image.Resampling.LANCZOS)
        left = (img.width - W) // 2
        top = (img.height - H) // 2
        img = img.crop((left, top, left + W, top + H))
        veil = Image.new("RGB", (W, H), "#f8fbf8")
        img = Image.blend(img, veil, 0.54)
    else:
        img = Image.new("RGB", (W, H), "#f7faf7")
        px = img.load()
        for y in range(H):
            for x in range(W):
                t = (x / W) * 0.55 + (y / H) * 0.45
                r = int(247 * (1 - t) + 230 * t)
                g = int(250 * (1 - t) + 244 * t)
                b = int(247 * (1 - t) + 240 * t)
                px[x, y] = (r, g, b)
    layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    d.ellipse((1740, -260, 3260, 1120), fill=(*accent, 42))
    d.ellipse((-430, 760, 920, 2160), fill=(199, 157, 54, 42))
    d.ellipse((1120, 920, 3080, 2420), fill=(42, 126, 181, 28))
    layer = layer.filter(ImageFilter.GaussianBlur(90))
    img = Image.alpha_composite(img.convert("RGBA"), layer)
    return img


def rounded_icon(path: Path, size: int, radius: int = 24) -> Image.Image:
    icon = Image.open(path).convert("RGBA").resize((size, size), Image.Resampling.LANCZOS)
    mask = Image.new("L", (size, size), 0)
    md = ImageDraw.Draw(mask)
    md.rounded_rectangle((0, 0, size, size), radius=radius, fill=255)
    out = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    out.alpha_composite(icon)
    out.putalpha(mask)
    return out


def draw_wrapped(draw: ImageDraw.ImageDraw, text: str, xy, width: int, font_obj, fill, line_gap=12):
    x, y = xy
    line = ""
    for char in text:
        test = line + char
        if draw.textbbox((0, 0), test, font=font_obj)[2] <= width:
            line = test
        else:
            draw.text((x, y), line, font=font_obj, fill=fill)
            y += font_obj.size + line_gap
            line = char
    if line:
        draw.text((x, y), line, font=font_obj, fill=fill)
        y += font_obj.size + line_gap
    return y


def fit_image(img: Image.Image, max_w: int, max_h: int) -> Image.Image:
    img = img.convert("RGB")
    ratio = min(max_w / img.width, max_h / img.height)
    size = (int(img.width * ratio), int(img.height * ratio))
    return img.resize(size, Image.Resampling.LANCZOS)


def shadow(size, radius=34, blur=34):
    s = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(s)
    d.rounded_rectangle((blur, blur, size[0] - blur, size[1] - blur), radius=radius, fill=(0, 0, 0, 110))
    return s.filter(ImageFilter.GaussianBlur(blur))


def paste_window(canvas: Image.Image, shot_path: Path, box):
    x, y, max_w, max_h = box
    shot = fit_image(Image.open(shot_path), max_w, max_h)
    frame_pad = 22
    frame_w = shot.width + frame_pad * 2
    frame_h = shot.height + frame_pad * 2 + 52
    sx = x
    sy = y
    canvas.alpha_composite(shadow((frame_w + 82, frame_h + 82), 32, 30), (sx - 41, sy - 25))
    frame = Image.new("RGBA", (frame_w, frame_h), (255, 255, 255, 244))
    fd = ImageDraw.Draw(frame)
    rounded_rect(fd, (0, 0, frame_w - 1, frame_h - 1), 30, (255, 255, 255, 245), (222, 233, 227), 2)
    for i, color in enumerate(("#ff5f57", "#febc2e", "#28c840")):
        fd.ellipse((28 + i * 30, 23, 48 + i * 30, 43), fill=color)
    shot = shot.convert("RGBA")
    frame.alpha_composite(shot, (frame_pad, frame_pad + 52))
    canvas.alpha_composite(frame, (sx, sy))


def draw_badge(draw, x, y, text):
    tw = draw.textbbox((0, 0), text, font=SMALL)[2]
    rounded_rect(draw, (x, y, x + tw + 42, y + 48), 24, (232, 245, 240), (188, 218, 208), 2)
    draw.text((x + 21, y + 10), text, font=SMALL, fill=(15, 126, 110))
    return x + tw + 56


def make_slide(index: int, shot: str, title: str, subtitle: str, bullets: list[str], accent=(15, 126, 110)):
    canvas = gradient_background(accent)
    d = ImageDraw.Draw(canvas)
    rounded_rect(d, (92, 102, 790, 1512), 38, (255, 255, 255, 218), (231, 238, 234), 2)
    # Brand mark
    canvas.alpha_composite(rounded_icon(APP_ICON, 90, 24), (124, 118))
    d.text((235, 128), "StayAwake", font=font(46, True), fill=(25, 32, 38))
    d.text((126, 226), "Mac 保持唤醒工具", font=SMALL, fill=(92, 105, 100))

    d.text((124, 356), title, font=TITLE, fill=(28, 35, 41))
    y = draw_wrapped(d, subtitle, (130, 494), 600, SUBTITLE, (74, 88, 82), 18)
    y += 42
    for b in bullets:
        rounded_rect(d, (128, y + 4, 156, y + 32), 14, accent, None)
        d.text((176, y), b, font=BODY, fill=(36, 48, 43))
        y += 70
    y += 28
    x = 130
    for badge in ["macOS 原生", "本地运行", "菜单栏控制"]:
        x = draw_badge(d, x, y, badge)

    paste_window(canvas, RAW_DIR / shot, (920, 300, 1770, 1100))
    d.text((124, 1635), f"{index:02d}", font=font(42, True), fill=accent)
    d.text((196, 1644), "StayAwake for macOS", font=SMALL, fill=(92, 105, 100))
    out = FINAL_DIR / f"stayawake-appstore-{index:02d}.png"
    canvas.convert("RGB").save(out, quality=96)
    return out


slides = [
    (
        "status.png",
        "让 Mac 保持唤醒",
        "会议、下载、演示和远程连接时，StayAwake 帮你保持在线。",
        ["一键开启 1 小时或无限期", "清楚显示当前状态", "使用 macOS 原生电源断言"],
    ),
    (
        "sessions.png",
        "快速会话，随时掌控",
        "从 15 分钟到无限期，按任务节奏快速开启或停止。",
        ["预设时长一键启动", "会话历史清晰可查", "菜单栏操作同步记录"],
    ),
    (
        "rules.png",
        "智能规则自动保持清醒",
        "接入电源、下载文件、运行指定 App 时自动保持唤醒。",
        ["电源状态自动触发", "下载任务不中断", "按运行中的 App 启动会话"],
    ),
    (
        "settings.png",
        "本地偏好，细节可控",
        "默认时长、屏幕保护程序、低电量策略都在本机保存。",
        ["无账号，无云同步压力", "支持显示器与系统睡眠策略", "适合长期后台任务"],
    ),
    (
        "promotions.png",
        "轻量工具箱工作流",
        "反馈、多语言和应用推荐入口集中在桌面侧栏中。",
        ["支持中文与多语言切换", "反馈记录连接服务器", "发现更多效率工具"],
    ),
]


def main():
    generated = []
    for idx, (shot, title, subtitle, bullets) in enumerate(slides, start=1):
        generated.append(make_slide(idx, shot, title, subtitle, bullets))
    for path in generated:
        print(path)


if __name__ == "__main__":
    main()
