"""由 assets/branding/app_icon.png（1024x1024 主图）生成各平台的启动图标。

用法：
    python tool/generate_app_icons.py

覆盖范围：
    android  普通图标 mipmap-*/ic_launcher.png、Android 8+ 自适应图标
             （mipmap-anydpi-v26/ic_launcher.xml + 前景图 + 渐变背景）
    ios      AppIcon.appiconset 中 Contents.json 声明的全部尺寸（无 alpha）
    web      favicon.png、icons/Icon-*.png（PWA 图标，含 maskable 安全区）
    windows  runner/resources/app_icon.ico（多尺寸 ICO）

图标主体的安全区处理：
    Android 自适应图标与 PWA maskable 图标会被系统裁切，因此先把整张图缩小、
    再用「边缘延展」补齐四周，让关键图形留在安全区内且不会出现接缝。
"""

from __future__ import annotations

import json
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets" / "branding" / "app_icon.png"

# Android 自适应图标前景：108dp 画布，安全区是中心直径 66dp 的圆（半径 66/108 ≈ 0.306）。
# 主图内容自身最大半径约为画布的 0.389，因此整图缩到 77% 后半径约 0.30，
# 即使被圆角或圆形遮罩裁切也不会切到圆环和箭头。
ADAPTIVE_CONTENT_SCALE = 0.77

# PWA maskable 图标：安全区是居中的圆，半径 0.4。缩到 90% 时内容半径约 0.35，
# 既充满画布又给圆形/圆角裁切留出余量。
MASKABLE_CONTENT_SCALE = 0.90


def load_source() -> Image.Image:
    """读取主图并统一成 1024 的 RGB 图。"""
    image = Image.open(SOURCE).convert("RGB")
    if image.size != (1024, 1024):
        image = image.resize((1024, 1024), Image.LANCZOS)
    return image


def resize(image: Image.Image, size: int) -> Image.Image:
    return image.resize((size, size), Image.LANCZOS)


def scale_with_edge_extension(image: Image.Image, scale: float) -> Image.Image:
    """把整图缩到 scale 大小并居中放到 1024 画布上。

    画布其余部分用最近边缘像素延展填充，主图背景是平滑渐变，
    延展后与原图无缝衔接，适合被系统裁切的场景（自适应图标、maskable 图标）。
    """
    side = round(1024 * scale)
    offset = (1024 - side) // 2
    scaled = np.asarray(resize(image, side))
    coords = np.clip(np.arange(1024) - offset, 0, side - 1)
    return Image.fromarray(scaled[coords][:, coords])


def save(image: Image.Image, path: Path, *, mode: str = "RGBA") -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    converted = image.convert(mode)
    converted.save(path, optimize=True)
    print(f"  {path.relative_to(ROOT)}  {converted.width}x{converted.height}")


def generate_android(source: Image.Image) -> None:
    print("android")
    res = ROOT / "android" / "app" / "src" / "main" / "res"
    legacy = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }
    adaptive_foreground = scale_with_edge_extension(source, ADAPTIVE_CONTENT_SCALE)
    foreground = {
        "mipmap-mdpi": 108,
        "mipmap-hdpi": 162,
        "mipmap-xhdpi": 216,
        "mipmap-xxhdpi": 324,
        "mipmap-xxxhdpi": 432,
    }
    for folder, size in legacy.items():
        save(resize(source, size), res / folder / "ic_launcher.png")
        save(
            resize(adaptive_foreground, foreground[folder]),
            res / folder / "ic_launcher_foreground.png",
        )

    # Android 8+ 自适应图标：渐变背景 + 前景图，交由系统裁切形状。
    anydpi = res / "mipmap-anydpi-v26" / "ic_launcher.xml"
    anydpi.parent.mkdir(parents=True, exist_ok=True)
    anydpi.write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        "<adaptive-icon xmlns:android=\"http://schemas.android.com/apk/res/android\">\n"
        '    <background android:drawable="@drawable/ic_launcher_background" />\n'
        '    <foreground android:drawable="@mipmap/ic_launcher_foreground" />\n'
        "</adaptive-icon>\n",
        encoding="utf-8",
    )
    print(f"  {anydpi.relative_to(ROOT)}")

    background = res / "drawable" / "ic_launcher_background.xml"
    background.parent.mkdir(parents=True, exist_ok=True)
    background.write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        "<!-- 自适应图标背景：与主图一致的深蓝渐变 -->\n"
        '<shape xmlns:android="http://schemas.android.com/apk/res/android"\n'
        '    android:shape="rectangle">\n'
        '    <gradient\n'
        '        android:angle="315"\n'
        '        android:startColor="#FF13324F"\n'
        '        android:endColor="#FF08131F"\n'
        '        android:type="linear" />\n'
        "</shape>\n",
        encoding="utf-8",
    )
    print(f"  {background.relative_to(ROOT)}")


def generate_ios(source: Image.Image) -> None:
    print("ios")
    appicon = ROOT / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
    contents = json.loads((appicon / "Contents.json").read_text(encoding="utf-8"))
    generated = set()
    for entry in contents["images"]:
        filename = entry.get("filename")
        if not filename or filename in generated:
            continue
        width, _, scale = entry["size"].partition("x")
        pixels = round(float(width) * float(entry["scale"].rstrip("x")))
        # App Store 图标不允许带 alpha 通道。
        save(resize(source, pixels), appicon / filename, mode="RGB")
        generated.add(filename)


def generate_web(source: Image.Image) -> None:
    print("web")
    web = ROOT / "web"
    save(resize(source, 32), web / "favicon.png")
    save(resize(source, 192), web / "icons" / "Icon-192.png")
    save(resize(source, 512), web / "icons" / "Icon-512.png")
    # maskable 图标会被裁成圆形/圆角方形，主体必须留在半径 0.4 的安全区内，
    # 因此单独用比自适应图标更大的比例，尽量充满画布又不会被裁到。
    maskable = scale_with_edge_extension(source, MASKABLE_CONTENT_SCALE)
    save(resize(maskable, 192), web / "icons" / "Icon-maskable-192.png")
    save(resize(maskable, 512), web / "icons" / "Icon-maskable-512.png")


def generate_windows(source: Image.Image) -> None:
    print("windows")
    ico = ROOT / "windows" / "runner" / "resources" / "app_icon.ico"
    ico.parent.mkdir(parents=True, exist_ok=True)
    sizes = [(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)]
    source.convert("RGBA").save(ico, format="ICO", sizes=sizes)
    print(f"  {ico.relative_to(ROOT)}  多尺寸 ICO")


def generate_flutter_assets(source: Image.Image) -> None:
    print("flutter assets")
    save(resize(source, 512), ROOT / "assets" / "branding" / "app_logo.png")


def main() -> None:
    source = load_source()
    generate_android(source)
    generate_ios(source)
    generate_web(source)
    generate_windows(source)
    generate_flutter_assets(source)


if __name__ == "__main__":
    main()
