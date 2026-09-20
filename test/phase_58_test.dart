import 'package:flutter_test/flutter_test.dart';
import 'unit/crash_data_sanitizer_test.dart' as sanitizer_tests;

void main() {
  group('Phase 58: Data Scrubbing & Crashlytics Integration Suite', () {
    sanitizer_tests.main();
  });
}
