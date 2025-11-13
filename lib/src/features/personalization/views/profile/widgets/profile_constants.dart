class ProfileConstants {
  ProfileConstants._();

  /// Diet Preference Options
  static const List<String> dietPreferences = [
    'No Preference',
    'Vegetarian',
    'Vegan',
    'Halal',
    'Kosher',
    'Gluten-Free',
    'Dairy-Free',
    'Low-Carb',
    'Keto',
    'Paleo',
    'Mediterranean',
  ];

  /// Common Allergen Options
  static const List<String> commonAllergens = [
    'Peanuts',
    'Tree Nuts',
    'Milk',
    'Eggs',
    'Wheat',
    'Soy',
    'Fish',
    'Shellfish',
    'Sesame',
    'Corn',
    'Gluten',
    'Sulfites',
  ];

  /// Gender Options
  static const Map<String, String> genderOptions = {
    'M': 'Male',
    'F': 'Female',
  };

  /// Validation Messages
  static const String genderLockedMessage =
      'Gender can only be changed once after initial setup. Are you sure you want to change it?';

  static const String dobLockedMessage =
      'Date of birth can only be changed once after initial setup. Are you sure you want to change it?';
}