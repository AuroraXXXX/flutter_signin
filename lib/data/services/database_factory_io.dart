import 'dart:io';

import 'package:sqflite/sqflite.dart' as mobile;
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;

ffi.DatabaseFactory createDatabaseFactory() {
  // Windows/Linux 使用 FFI；Android/iOS 使用 sqflite 原生工厂。
  if (Platform.isWindows || Platform.isLinux) {
    ffi.sqfliteFfiInit();
    return ffi.databaseFactoryFfi;
  }
  return mobile.databaseFactory;
}
