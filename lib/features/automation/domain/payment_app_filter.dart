/// Filter and registry for whitelisted payment applications.
/// Ensures the notification listener only processes events originated
/// from verified financial and payment apps.
class PaymentAppFilter {
  const PaymentAppFilter._();

  /// Whitelisted payment application package identifiers mapped to their display names.
  static const paymentApps = {
    'com.google.android.apps.nbu.paisa.user': 'Google Pay',
    'com.phonepe.app': 'PhonePe',
    'net.one97.paytm': 'Paytm',
    'in.org.npci.upiapp': 'BHIM',
    'in.amazon.mShop.android.shopping': 'Amazon Pay',
  };

  /// Validates whether the given Android [packageName] is within the whitelisted payment apps.
  static bool isWhitelisted(String? packageName) {
    if (packageName == null) return false;
    return paymentApps.containsKey(packageName);
  }

  /// Returns the human-readable app name for a whitelisted package, or null if unknown.
  static String? getAppName(String? packageName) {
    if (packageName == null) return null;
    return paymentApps[packageName];
  }

  /// Retrieves all whitelisted package names.
  static Set<String> get whitelistedPackages => paymentApps.keys.toSet();

  /// Retrieves all supported payment app display names.
  static List<String> get supportedAppNames => paymentApps.values.toList();
}
