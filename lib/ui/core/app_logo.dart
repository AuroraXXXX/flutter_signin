import 'package:flutter/material.dart';

/// 应用内展示的品牌图标，与应用启动图标使用同一张主图。
///
/// 启动图标由 `tool/generate_app_icons.py` 由 `assets/branding/app_icon.png`
/// 生成，这里的 [asset] 是同一次生成产物。
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 96, this.borderRadius = 20});

  static const String asset = 'assets/branding/app_logo.png';

  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.asset(
        asset,
        width: size,
        height: size,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
        // 图标仅用于装饰，读屏时由相邻文字说明用途。
        excludeFromSemantics: true,
      ),
    );
  }
}
