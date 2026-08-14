class SubscriptionPlan {
  final String? id;
  final String? planKey;
  final String name;
  final double price;
  final double equivalentMonthlyPrice;
  final String highlightLabel;
  final List<String> features;
  final String billingCycle;
  final int billingCycleCount;
  final bool isCurrentPlan;
  final bool isFeatured;
  final String? description;
  final String? cutPriceLabel;
  final String? perMonthLabel;
  final String? promoLabel;
  final String? stripePriceId;
  final String? stripeProductId;

  SubscriptionPlan({
    this.id,
    this.planKey,
    required this.name,
    required this.price,
    required this.equivalentMonthlyPrice,
    required this.highlightLabel,
    required this.features,
    required this.billingCycle,
    this.billingCycleCount = 1,
    required this.isCurrentPlan,
    required this.isFeatured,
    this.description,
    this.cutPriceLabel,
    this.perMonthLabel,
    this.promoLabel,
    this.stripePriceId,
    this.stripeProductId,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    // Handle features - could be List<String> or List<dynamic>
    List<String> featuresList = [];
    if (json['features'] != null) {
      if (json['features'] is List) {
        featuresList = (json['features'] as List)
            .map((e) => e.toString())
            .toList();
      }
    }

    // Handle price_amount - could be int, double, or String
    double priceValue = 0.0;
    if (json['price_amount'] != null) {
      if (json['price_amount'] is num) {
        priceValue = json['price_amount'].toDouble();
      } else if (json['price_amount'] is String) {
        priceValue = double.tryParse(json['price_amount']) ?? 0.0;
      }
    }

    // Handle equivalent_monthly_price
    double equivalentMonthlyPriceValue = 0.0;
    if (json['equivalent_monthly_price'] != null) {
      if (json['equivalent_monthly_price'] is num) {
        equivalentMonthlyPriceValue =
            json['equivalent_monthly_price'].toDouble();
      } else if (json['equivalent_monthly_price'] is String) {
        equivalentMonthlyPriceValue =
            double.tryParse(json['equivalent_monthly_price']) ?? 0.0;
      }
    }

    // Get highlight_label for display
    final highlightLabelValue =
        json['highlight_label'] as String? ?? '£${priceValue.toStringAsFixed(2)}';

    // Get billing cycle
    final billingCycleValue =
        json['billing_cycle'] as String? ?? 'monthly';
    final billingCycleLower = billingCycleValue.toLowerCase();

    // Get billing cycle count
    final billingCycleCountValue = int.tryParse(json['billing_cycle_count']?.toString() ?? '1') ?? 1;

    // Pricing labels logic
    final currency = json['currency_code']?.toString() == 'GBP' ? '£' : '£';
    final priceLabelValue = '$currency${priceValue.toInt()}/$billingCycleValue';
    
    String? cutPriceLabelValue;
    if (equivalentMonthlyPriceValue > 0 && equivalentMonthlyPriceValue != priceValue) {
      cutPriceLabelValue = '$currency${equivalentMonthlyPriceValue.toInt()}/$billingCycleValue';
    }

    // Calculate perMonthLabel: price_amount / billing_cycle_count
    String? perMonthLabelValue;
    if (billingCycleCountValue > 1) {
      final monthlyPrice = (priceValue / billingCycleCountValue).round();
      perMonthLabelValue = '$currency$monthlyPrice/monthly';
    }

    // Promo label for yearly plans
    String? promoLabelValue;
    if (billingCycleLower.contains('year') || (json['plan_name']?.toString().toLowerCase().contains('year') ?? false)) {
      promoLabelValue = 'or one month free!';
    }

    // Check if this is the current plan (might come from user subscription data)
    final isCurrentPlanValue = json['is_current_plan'] as bool? ??
        json['isCurrentPlan'] as bool? ??
        false;

    // Get is_featured
    final isFeaturedValue = json['is_featured'] as bool? ?? false;

    return SubscriptionPlan(
      id: json['_id'] as String? ?? json['id'] as String?,
      planKey: json['plan_key'] as String?,
      name: json['plan_name'] as String? ?? json['name'] as String? ?? '',
      price: priceValue,
      equivalentMonthlyPrice: equivalentMonthlyPriceValue,
      highlightLabel: priceLabelValue, // Use our calculated price label
      features: featuresList,
      billingCycle: billingCycleValue,
      billingCycleCount: billingCycleCountValue,
      isCurrentPlan: isCurrentPlanValue,
      isFeatured: isFeaturedValue,
      description: json['description'] as String?,
      cutPriceLabel: cutPriceLabelValue,
      perMonthLabel: perMonthLabelValue,
      promoLabel: promoLabelValue,
      stripePriceId: json['stripe_price_id'] as String?,
      stripeProductId: json['stripe_product_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) '_id': id,
        if (planKey != null) 'plan_key': planKey,
        'plan_name': name,
        'price_amount': price,
        'equivalent_monthly_price': equivalentMonthlyPrice,
        'highlight_label': highlightLabel,
        'features': features,
        'billing_cycle': billingCycle,
        'is_current_plan': isCurrentPlan,
        'is_featured': isFeatured,
        if (description != null) 'description': description,
      };
}

