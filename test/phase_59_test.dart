import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 59: App Assets & Native Cold-Boot Splash Tests', () {
    test('App icon master assets exist with proper formats', () {
      final appIcon = File('assets/icons/app_icon.png');
      final appIconFg = File('assets/icons/app_icon_foreground.png');
      final splashLogo = File('assets/splash/splash_logo.png');

      expect(appIcon.existsSync(), isTrue);
      expect(appIconFg.existsSync(), isTrue);
      expect(splashLogo.existsSync(), isTrue);

      expect(appIcon.lengthSync(), greaterThan(10000));
      expect(appIconFg.lengthSync(), greaterThan(5000));
      expect(splashLogo.lengthSync(), greaterThan(5000));
    });

    test('Android adaptive launcher icons and mipmaps are generated', () {
      final mipmapHdpi = File('android/app/src/main/res/mipmap-hdpi/ic_launcher.png');
      final mipmapXxhdpi = File('android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png');
      final mipmapXxxhdpi = File('android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png');

      expect(mipmapHdpi.existsSync(), isTrue);
      expect(mipmapXxhdpi.existsSync(), isTrue);
      expect(mipmapXxxhdpi.existsSync(), isTrue);
    });

    test('Android 12+ native splash configurations and styles are configured', () {
      final valuesV31Styles = File('android/app/src/main/res/values-v31/styles.xml');
      final launchBackground = File('android/app/src/main/res/drawable/launch_background.xml');

      expect(valuesV31Styles.existsSync(), isTrue);
      expect(launchBackground.existsSync(), isTrue);

      final stylesContent = valuesV31Styles.readAsStringSync();
      expect(stylesContent, contains('windowSplashScreenBackground'));
      expect(stylesContent, contains('windowSplashScreenAnimatedIcon'));

      final bgContent = launchBackground.readAsStringSync();
      expect(bgContent, contains('item'));
    });
  });
}
