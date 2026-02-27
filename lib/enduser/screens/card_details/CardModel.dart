class CardModel {
  final String id;
  final String cardType;
  final String maskedNumber;
  final String? fullNumber; // Optional as API doesn't return full number
  final String expiryDate; // Formatted from expiry_month and expiry_year
  final String? cvv; // Optional as API doesn't return CVV
  final String nameOnCard;
  final int? expiryMonth;
  final int? expiryYear;
  final bool isDefault;
  final String? userId;

  CardModel({
    required this.id,
    required this.cardType,
    required this.maskedNumber,
    this.fullNumber,
    required this.expiryDate,
    this.cvv,
    required this.nameOnCard,
    this.expiryMonth,
    this.expiryYear,
    this.isDefault = false,
    this.userId,
  });

  // Factory constructor from API response
  factory CardModel.fromJson(Map<String, dynamic> json) {
    int expiryMonth = json['expiry_month'] ?? 0;
    int expiryYear = json['expiry_year'] ?? 0;
    String expiryDate = expiryMonth > 0 && expiryYear > 0
        ? '${expiryMonth.toString().padLeft(2, '0')}/${expiryYear.toString().substring(2)}'
        : '';
    
    String last4 = json['last4']?.toString() ?? '';
    String maskedNumber = last4.isNotEmpty ? '.... $last4' : '....';
    
    return CardModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      cardType: json['card_type']?.toString().toUpperCase() ?? 'VISA',
      maskedNumber: maskedNumber,
      expiryDate: expiryDate,
      nameOnCard: json['card_holder_name']?.toString() ?? '',
      expiryMonth: expiryMonth,
      expiryYear: expiryYear,
      isDefault: json['is_default'] ?? false,
      userId: json['user_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'card_type': cardType.toLowerCase(),
      'masked_number': maskedNumber,
      'expiry_date': expiryDate,
      'name_on_card': nameOnCard,
      'expiry_month': expiryMonth,
      'expiry_year': expiryYear,
      'is_default': isDefault,
      'user_id': userId,
    };
  }
}

