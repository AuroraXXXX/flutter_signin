import 'package:flutter/material.dart';
import 'package:flutter_signin/ui/core/app_logo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AppLogo 渲染打包进产物的品牌图标', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Center(child: AppLogo(size: 64)))),
    );

    final image = tester.widget<Image>(find.byType(Image));
    expect((image.image as AssetImage).assetName, AppLogo.asset);
    expect(image.width, 64);
    // 测试环境下资源由 AssetBundle 加载，解析成功即说明 assets 声明正确。
    await tester.pumpAndSettle();
    expect(find.byType(AppLogo), findsOneWidget);
  });
}
