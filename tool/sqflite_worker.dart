// Entrypoint used to build the shared worker required by
// `package:sqflite_common_ffi_web`.
//
// Build with:
//   dart compile js -O2 -o web/sqflite_sw.js tool/sqflite_worker.dart
//
// The generated `web/sqflite_sw.js` is normally produced by
// `dart run sqflite_common_ffi_web:setup`; this file produces the same shared
// worker without needing `webdev`/network access.
import 'package:sqflite_common_ffi_web/src/sw/shared_worker.dart';

void main(List<String> args) {
  mainSharedWorker(args);
}
