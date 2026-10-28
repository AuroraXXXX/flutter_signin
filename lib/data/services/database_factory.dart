// 条件导出根据编译目标选择移动端、桌面端、Web 或默认实现。
export 'database_factory_stub.dart'
    if (dart.library.io) 'database_factory_io.dart'
    if (dart.library.js_interop) 'database_factory_web.dart';
