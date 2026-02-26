class PricingConstants {
  static const String monthlySubscriptionId = 'vyra_premium_monthly';
  static const String yearlySubscriptionId = 'vyra_premium_yearly';
  
  static const Set<String> productIds = {
    monthlySubscriptionId,
    yearlySubscriptionId,
  };

  static const int freeDailyLimit = 5;
  static const int premiumDailyLimit = 100;
}