class StoreProducts {
  // Product IDs for Android - matching Play Console exactly
  static const String monthlySubAndroid = 'thesismonth';
  static const String yearlySubAndroid = 'thesisyear';

  // Product IDs for iOS remain unchanged
  static const String monthlySubIOS = 'com.thesisgenerator.monthly';
  static const String yearlySubIOS = 'com.thesisgenerator.yearly';

  static const Set<String> allProducts = {
    monthlySubIOS,
    yearlySubIOS,
    monthlySubAndroid,
    yearlySubAndroid,
  };
}
