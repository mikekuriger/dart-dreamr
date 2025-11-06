// models/subscription.dart
import 'package:flutter/foundation.dart';

/// Represents a subscription plan in the app
class SubscriptionPlan {
  final String id;
  final String name;
  final String description;
  final double price;
  final String period; // 'monthly', 'yearly', etc.
  final List<String> features;
  final String? productId; // Store/platform specific product ID

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.period,
    required this.features,
    this.productId,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      period: json['period'] as String,
      features: (json['features'] as List<dynamic>).map((e) => e as String).toList(),
      productId: json['product_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'period': period,
      'features': features,
      'product_id': productId,
    };
  }
}

/// Represents the user's subscription status
class SubscriptionStatus {
  final String tier; // 'free', 'pro', etc.
  final DateTime? expiryDate;
  final bool isActive;
  final bool autoRenew;
  final String? paymentMethod;

  const SubscriptionStatus({
    required this.tier,
    this.expiryDate,
    required this.isActive,
    required this.autoRenew,
    this.paymentMethod,
  });

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatus(
      tier: json['tier'] as String,
      expiryDate: json['expiry_date'] != null 
          ? DateTime.parse(json['expiry_date'] as String) 
          : null,
      isActive: json['is_active'] as bool,
      autoRenew: json['auto_renew'] as bool,
      paymentMethod: json['payment_method'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tier': tier,
      'expiry_date': expiryDate?.toIso8601String(),
      'is_active': isActive,
      'auto_renew': autoRenew,
      'payment_method': paymentMethod,
    };
  }

  /// Default free tier status
  factory SubscriptionStatus.free() {
    return const SubscriptionStatus(
      tier: 'free',
      expiryDate: null,
      isActive: true,
      autoRenew: false,
      paymentMethod: null,
    );
  }
}