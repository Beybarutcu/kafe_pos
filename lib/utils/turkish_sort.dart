// lib/utils/turkish_sort.dart
class TurkishSort {
  // Turkish alphabetical order
  static const String turkishOrder = 'AaBbCcÇçDdEeFfGgĞğHhIıİiJjKkLlMmNnOoÖöPpRrSsŞşTtUuÜüVvYyZz';

  /// Compare two strings using Turkish alphabetical order
  static int compare(String a, String b) {
    int minLength = a.length < b.length ? a.length : b.length;
    
    for (int i = 0; i < minLength; i++) {
      int indexA = turkishOrder.indexOf(a[i]);
      int indexB = turkishOrder.indexOf(b[i]);
      
      // If character not found in Turkish order, use Unicode value
      if (indexA == -1) indexA = 1000 + a.codeUnitAt(i);
      if (indexB == -1) indexB = 1000 + b.codeUnitAt(i);
      
      if (indexA != indexB) {
        return indexA - indexB;
      }
    }
    
    return a.length - b.length;
  }

  /// Sort a list of strings using Turkish alphabetical order
  static void sortList(List<String> list) {
    list.sort(compare);
  }
}