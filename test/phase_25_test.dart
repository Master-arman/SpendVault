import 'package:finance_app/features/automation/data/notification_listener_repo.dart';
import 'package:finance_app/features/automation/domain/category_classifier.dart';
import 'package:finance_app/features/automation/domain/models/parsed_transaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 25: Smart Keyword-to-Category Classifier Unit Tests', () {
    const classifier = CategoryClassifier();

    group('Classification Rules Dictionary Structure', () {
      test('contains exact classification rules categories and keywords', () {
        expect(CategoryClassifier.classificationRules.containsKey('Food & Dining'), isTrue);
        expect(CategoryClassifier.classificationRules.containsKey('Transportation'), isTrue);
        expect(CategoryClassifier.classificationRules.containsKey('Groceries'), isTrue);
        expect(CategoryClassifier.classificationRules.containsKey('Shopping'), isTrue);

        expect(
          CategoryClassifier.classificationRules['Food & Dining'],
          containsAll(['tea', 'chai', 'coffee', 'cafe', 'restaurant', 'dhaba', 'swiggy', 'zomato', 'bakery', 'kitchen']),
        );
        expect(
          CategoryClassifier.classificationRules['Transportation'],
          containsAll(['fuel', 'petrol', 'diesel', 'cng', 'iocl', 'bpcl', 'hpcl', 'uber', 'ola', 'rapido', 'metro']),
        );
        expect(
          CategoryClassifier.classificationRules['Groceries'],
          containsAll(['blinkit', 'zepto', 'instamart', 'supermarket', 'kirana', 'mart', 'dmart']),
        );
        expect(
          CategoryClassifier.classificationRules['Shopping'],
          containsAll(['amazon', 'flipkart', 'myntra', 'zara', 'meesho', 'ajio']),
        );
      });
    });

    group('Food & Dining Categorization', () {
      test('classifies tea, coffee, cafe, restaurant, swiggy, zomato keywords', () {
        expect(classifier.classify('Chai Point Indiranagar'), equals('Food & Dining'));
        expect(classifier.classify('Starbucks Coffee'), equals('Food & Dining'));
        expect(classifier.classify('Blue Tokai Cafe'), equals('Food & Dining'));
        expect(classifier.classify('Punjab Grill Restaurant'), equals('Food & Dining'));
        expect(classifier.classify('Highway Dhaba Murthal'), equals('Food & Dining'));
        expect(classifier.classify('Swiggy Order #8821'), equals('Food & Dining'));
        expect(classifier.classify('Zomato Online Delivery'), equals('Food & Dining'));
        expect(classifier.classify('The French Bakery'), equals('Food & Dining'));
        expect(classifier.classify('Cloud Kitchen Foods'), equals('Food & Dining'));
      });
    });

    group('Transportation Categorization', () {
      test('classifies fuel, petrol, uber, ola, rapido, metro keywords', () {
        expect(classifier.classify('Uber India Rides'), equals('Transportation'));
        expect(classifier.classify('Ola Cabs Mobility'), equals('Transportation'));
        expect(classifier.classify('Rapido Bike Taxi'), equals('Transportation'));
        expect(classifier.classify('HPCL Petrol Pump'), equals('Transportation'));
        expect(classifier.classify('IOCL Fuel Station'), equals('Transportation'));
        expect(classifier.classify('BPCL CNG Gas'), equals('Transportation'));
        expect(classifier.classify('Delhi Metro Card Recharge'), equals('Transportation'));
        expect(classifier.classify('Diesel auto refill'), equals('Transportation'));
      });
    });

    group('Groceries Categorization', () {
      test('classifies blinkit, zepto, instamart, dmart, kirana keywords', () {
        expect(classifier.classify('Blinkit Commerce Pvt Ltd'), equals('Groceries'));
        expect(classifier.classify('Zepto 10 min grocery'), equals('Groceries'));
        expect(classifier.classify('Instamart Grocery Delivery'), equals('Groceries'));
        expect(classifier.classify('DMart Hypermarket'), equals('Groceries'));
        expect(classifier.classify('Gupta Kirana Store'), equals('Groceries'));
        expect(classifier.classify('Reliance Fresh Supermarket'), equals('Groceries'));
      });
    });

    group('Shopping Categorization', () {
      test('classifies amazon, flipkart, myntra, zara, meesho, ajio keywords', () {
        expect(classifier.classify('Amazon Seller Services'), equals('Shopping'));
        expect(classifier.classify('Flipkart Internet Private Ltd'), equals('Shopping'));
        expect(classifier.classify('Myntra Designs'), equals('Shopping'));
        expect(classifier.classify('Zara Clothing Mall'), equals('Shopping'));
        expect(classifier.classify('Meesho Supplier Payment'), equals('Shopping'));
        expect(classifier.classify('Ajio Online Retail'), equals('Shopping'));
      });
    });

    group('Fallback & Edge Cases', () {
      test('returns Miscellaneous for unknown merchants and handles nulls', () {
        expect(classifier.classify('Acme Industrial Consulting'), equals('Miscellaneous'));
        expect(classifier.classify(''), equals('Miscellaneous'));
        expect(classifier.classify(null), equals('Miscellaneous'));
        expect(classifier.classify('Unknown Vendor', fallback: 'Uncategorized'), equals('Uncategorized'));
      });
    });
  });

  group('Phase 25: Automated Pipeline Integration with CategoryClassifier', () {
    test('NotificationListenerRepo auto-assigns smart category to incoming events', () async {
      final repo = NotificationListenerRepo();
      await repo.startListening();

      final List<ParsedTransaction> emitted = [];
      final subscription = repo.onTransactionReceived.listen(emitted.add);

      // 1. Google Pay to Chai Point -> Food & Dining
      repo.onNotificationReceived(
        title: 'Google Pay',
        content: 'Paid ₹150.00 to Chai Point Bangalore',
        packageName: 'com.google.android.apps.nbu.paisa.user',
      );

      // 2. PhonePe to Uber -> Transportation
      repo.onNotificationReceived(
        title: 'PhonePe',
        content: 'Payment of ₹450.00 to Uber India successful',
        packageName: 'com.phonepe.app',
      );

      // 3. Paytm to Zepto -> Groceries
      repo.onNotificationReceived(
        title: 'Paytm',
        content: 'Paid ₹620.00 successfully to Zepto Grocery',
        packageName: 'net.one97.paytm',
      );

      // 4. SMS from Amazon -> Shopping
      repo.onNotificationReceived(
        title: 'HDFCBK',
        content: 'Acct XX1234 debited by Rs. 2,499.00 on a/c x1234 to AMAZON INDIA. Avl Bal Rs. 15,000.00',
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(emitted.length, equals(4));
      expect(emitted[0].category, equals('Food & Dining'));
      expect(emitted[1].category, equals('Transportation'));
      expect(emitted[2].category, equals('Groceries'));
      expect(emitted[3].category, equals('Shopping'));

      await subscription.cancel();
      repo.dispose();
    });
  });
}
