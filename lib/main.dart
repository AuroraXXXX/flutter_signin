import 'package:flutter/material.dart';

import 'bootstrap.dart';

void main() {
  // sqflite 和其他平台插件需要在创建 Flutter 应用前完成绑定。
  WidgetsFlutterBinding.ensureInitialized();
  // 先显示初始化页面，数据库准备好后再创建真正的应用界面。
  runApp(const BootstrapApp());
}
