import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class BudgetCategory {
  final String id;
  final String name;
  final String banglaName;
  final double defaultPercent;
  final Color color;
  final IconData icon;
  double allocatedPercent;
  bool isLocked;

  BudgetCategory({
    required this.id,
    required this.name,
    required this.banglaName,
    required this.defaultPercent,
    required this.color,
    required this.icon,
    double? allocatedPercent,
    this.isLocked = false,
  }) : allocatedPercent = allocatedPercent ?? defaultPercent;

  double get allocatedAmount => 0; // Computed at runtime with total

  BudgetCategory copyWith({
    double? allocatedPercent,
    bool? isLocked,
  }) {
    return BudgetCategory(
      id: id,
      name: name,
      banglaName: banglaName,
      defaultPercent: defaultPercent,
      color: color,
      icon: icon,
      allocatedPercent: allocatedPercent ?? this.allocatedPercent,
      isLocked: isLocked ?? this.isLocked,
    );
  }
}

class BudgetPlan {
  final double totalBudget;
  final int guestCount;
  final List<BudgetCategory> categories;

  BudgetPlan({
    required this.totalBudget,
    required this.guestCount,
    required this.categories,
  });

  double amountFor(BudgetCategory cat) =>
      totalBudget * (cat.allocatedPercent / 100);

  double get perHeadCost =>
      guestCount > 0 ? totalBudget / guestCount : 0;
}

List<BudgetCategory> defaultBudgetCategories() => [
      BudgetCategory(
        id: 'venue',
        name: 'Venue & Catering',
        banglaName: 'ভেন্যু ও ক্যাটারিং',
        defaultPercent: 45,
        color: AppColors.budgetVenue,
        icon: Icons.location_city_rounded,
      ),
      BudgetCategory(
        id: 'attire',
        name: 'Attire & Jewelry',
        banglaName: 'পোশাক ও গহনা',
        defaultPercent: 20,
        color: AppColors.budgetAttire,
        icon: Icons.diamond_rounded,
      ),
      BudgetCategory(
        id: 'decor',
        name: 'Decor & Lighting',
        banglaName: 'সাজসজ্জা ও আলো',
        defaultPercent: 15,
        color: AppColors.budgetDecor,
        icon: Icons.auto_awesome_rounded,
      ),
      BudgetCategory(
        id: 'photo',
        name: 'Photography & Video',
        banglaName: 'ফটোগ্রাফি ও ভিডিও',
        defaultPercent: 12,
        color: AppColors.budgetPhoto,
        icon: Icons.camera_alt_rounded,
      ),
      BudgetCategory(
        id: 'makeup',
        name: 'Makeup & Logistics',
        banglaName: 'মেকআপ ও লজিস্টিক্স',
        defaultPercent: 8,
        color: AppColors.budgetMakeup,
        icon: Icons.brush_rounded,
      ),
    ];
