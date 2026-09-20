/// Smart keyword-to-category classifier for automated transaction labeling.
/// Analyzes merchant names and transaction descriptions against a curated dictionary engine.
class CategoryClassifier {
  const CategoryClassifier();

  /// Curated dictionary rules mapping standard category names to identifier keywords.
  static const Map<String, List<String>> classificationRules = {
    'Food & Dining': [
      'tea',
      'chai',
      'coffee',
      'cafe',
      'restaurant',
      'dhaba',
      'swiggy',
      'zomato',
      'bakery',
      'kitchen',
    ],
    'Transportation': [
      'fuel',
      'petrol',
      'diesel',
      'cng',
      'iocl',
      'bpcl',
      'hpcl',
      'uber',
      'ola',
      'rapido',
      'metro',
    ],
    'Groceries': [
      'blinkit',
      'zepto',
      'instamart',
      'supermarket',
      'kirana',
      'mart',
      'dmart',
    ],
    'Shopping': [
      'amazon',
      'flipkart',
      'myntra',
      'zara',
      'meesho',
      'ajio',
    ],
  };

  /// Fallback category label when no dictionary keywords match.
  static const String defaultCategory = 'Miscellaneous';

  /// Classifies a given [input] (merchant name, description, or raw SMS/notification text)
  /// into a category based on the dictionary engine.
  String classify(String? input, {String fallback = defaultCategory}) {
    if (input == null || input.trim().isEmpty) {
      return fallback;
    }

    final String normalized = input.toLowerCase();

    for (final entry in classificationRules.entries) {
      final String category = entry.key;
      final List<String> keywords = entry.value;

      for (final keyword in keywords) {
        // Match word boundaries or distinct substring token
        final RegExp regex = RegExp(
          r'(?:\b|_)' + RegExp.escape(keyword.toLowerCase()) + r'(?:\b|_)',
          caseSensitive: false,
        );

        if (regex.hasMatch(normalized) || normalized.contains(keyword.toLowerCase())) {
          return category;
        }
      }
    }

    return fallback;
  }

  /// Returns true if the input text matches any category rule.
  bool canClassify(String? input) {
    if (input == null || input.trim().isEmpty) return false;
    return classify(input, fallback: '') != '';
  }

  /// Retrieves list of keywords associated with a given [category].
  List<String>? getKeywordsForCategory(String category) {
    return classificationRules[category];
  }
}
