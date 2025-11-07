import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';

import '../constants/colors.dart';
import '../constants/enums.dart';

/// SubscriptionStatus 扩展
extension SubscriptionStatusExtensions on SubscriptionStatus {
  IconData get icon {
    switch (this) {
      case SubscriptionStatus.active:
        return Iconsax.tick_circle_bold;
      case SubscriptionStatus.pending:
        return Iconsax.info_circle_bold;
      case SubscriptionStatus.expired:
        return Iconsax.clock_bold;
      case SubscriptionStatus.failed:
        return Iconsax.close_circle_bold;
      case SubscriptionStatus.cancelled:
        return Iconsax.close_square_bold;
    }
  }

  String get message {
    switch (this) {
      case SubscriptionStatus.active:
        return 'Your subscription is currently active';
      case SubscriptionStatus.pending:
        return 'Your subscription is currently pending';
      case SubscriptionStatus.expired:
        return 'This subscription has expired';
      case SubscriptionStatus.failed:
        return 'Subscription activation failed';
      case SubscriptionStatus.cancelled:
        return 'This subscription was cancelled';
    }
  }
}

/// PaymentStatus 扩展
extension PaymentStatusExtensions on PaymentStatus {
  Color get color {
    switch (this) {
      case PaymentStatus.succeeded:
        return TColors.success;
      case PaymentStatus.pending:
        return TColors.warning;
      case PaymentStatus.failed:
        return TColors.error;
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentStatus.succeeded:
        return Iconsax.tick_circle_bold;
      case PaymentStatus.pending:
        return Iconsax.clock_bold;
      case PaymentStatus.failed:
        return Iconsax.close_circle_bold;
    }
  }

  String get message {
    switch (this) {
      case PaymentStatus.succeeded:
        return 'Payment processed successfully';
      case PaymentStatus.pending:
        return 'Payment is being processed';
      case PaymentStatus.failed:
        return 'Payment could not be completed';
    }
  }

  List<Color> get gradient {
    switch (this) {
      case PaymentStatus.succeeded:
        return [TColors.success.withOpacity(0.8), TColors.success];
      case PaymentStatus.pending:
        return [TColors.warning.withOpacity(0.8), TColors.warning];
      case PaymentStatus.failed:
        return [TColors.error.withOpacity(0.8), TColors.error];
    }
  }
}

/// PaymentMethod 扩展
extension PaymentMethodExtensions on String {
  IconData get paymentMethodIcon {
    switch (toLowerCase()) {
      case 'credit card':
        return Iconsax.card_bold;
      case 'paypal':
        return Iconsax.wallet_bold;
      case 'apple pay':
        return Iconsax.apple_bold;
      case 'google pay':
        return Iconsax.google_bold;
      case 'bank transfer':
        return Iconsax.bank_outline;
      case 'stripe':
        return Iconsax.card_bold;
      default:
        return Iconsax.wallet_bold;
    }
  }
}