class AppConstants {
  static const String dbName = 'kafe_pos.db';
  static const int dbVersion = 2;
  
  // Order Status
  static const String orderStatusPending = 'beklemede';
  static const String orderStatusWaitingPayment = 'ödeme_bekliyor';
  static const String orderStatusPaid = 'ödendi';
  static const String orderStatusCompleted = 'tamamlandı';
  
  // Table Status
  static const String tableStatusEmpty = 'boş';
  static const String tableStatusOccupied = 'dolu';
  
  // Payment Methods
  static const String paymentCash = 'nakit';
  static const String paymentCard = 'kart';
  
  // Discount Types
  static const String discountTypePercent = 'yüzde';
  static const String discountTypeAmount = 'tutar';
}