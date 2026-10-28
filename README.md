# flutter_signin

signin project

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Web 端（sqflite）必需的两个运行文件

Web 平台使用 `sqflite_common_ffi_web`，它需要 `web/` 目录下同时存在两个文件，缺任何一个都会在启动时抛出
`应用启动失败 SqfliteFfiWebException()`：

| 文件 | 作用 |
| --- | --- |
| `web/sqlite3.wasm` | SQLite 的 WebAssembly 二进制，由 `package:sqlite3` 加载 |
| `web/sqflite_sw.js` | 共享 worker，真正执行 SQL 并写入 IndexedDB |

这两个文件必须随 `web/` 一起提交或在构建前生成，否则 `flutter run -d chrome` /
`flutter build web` 出来的页面都只会显示启动失败。

### 重新生成

官方方式（需要联网，会从 GitHub Releases 下载 wasm）：

```bash
dart run sqflite_common_ffi_web:setup
# 需要更新时
dart run sqflite_common_ffi_web:setup --force
```

离线方式（只有 `sqflite_sw.js` 需要编译，wasm 从本地缓存复制）：

```bash
# 1) 编译共享 worker，产物直接写进 web/
dart compile js -O2 -o web/sqflite_sw.js tool/sqflite_worker.dart
# 2) 把与 package:sqlite3 版本匹配的 sqlite3.wasm 放回 web/sqlite3.wasm
```

`tool/sqflite_worker.dart` 只是把 `sqflite_common_ffi_web` 自带的
`mainSharedWorker` 暴露成可编译入口，内容与官方 `web/sqflite_sw.dart` 一致。

> 注意：`sqlite3.wasm` 的导出符号必须覆盖当前 `package:sqlite3` 的绑定。升级
> `sqlite3` / `sqflite_common_ffi_web` 后如果出现 wasm 相关报错，请用上面的官方命令
> 重新生成一次，而不是继续沿用旧 wasm。

## 应用图标

启动图标与 App 内展示的 logo 都来自同一张主图 `assets/branding/app_icon.png`
（1024×1024）。改动主图后重新生成全部平台资源：

```bash
python tool/generate_app_icons.py
```

脚本会覆盖以下文件（需要 Pillow 和 numpy）：

| 平台 | 产物 |
| --- | --- |
| Android | `res/mipmap-*/ic_launcher.png`（传统图标）、`res/mipmap-*/ic_launcher_foreground.png` + `res/mipmap-anydpi-v26/ic_launcher.xml` + `res/drawable/ic_launcher_background.xml`（Android 8+ 自适应图标） |
| iOS | `ios/Runner/Assets.xcassets/AppIcon.appiconset/*.png`，尺寸取自该目录的 `Contents.json`，且不带 alpha 通道 |
| Web | `web/favicon.png`、`web/icons/Icon-{192,512}.png`、`web/icons/Icon-maskable-{192,512}.png` |
| Windows | `windows/runner/resources/app_icon.ico`（16–256 多尺寸） |
| 应用内 | `assets/branding/app_logo.png`，由 `lib/ui/core/app_logo.dart` 的 `AppLogo` 使用 |

自适应图标与 maskable 图标会被系统裁切，脚本会把整图缩小后再用边缘像素延展补齐四周，
使圆环和箭头始终落在安全区内。

