import '../models/budget_model.dart';

class BudgetLogic {
  /// Builds a fresh BudgetPlan from total budget and guest count.
  static BudgetPlan createPlan({
    required double totalBudget,
    required int guestCount,
  }) {
    return BudgetPlan(
      totalBudget: totalBudget,
      guestCount: guestCount,
      categories: defaultBudgetCategories(),
    );
  }

  /// Adjusts a category's allocation percentage while redistributing the delta
  /// across all non-locked categories proportionally.
  /// Returns the updated categories list.
  static List<BudgetCategory> adjustCategory({
    required List<BudgetCategory> categories,
    required String categoryId,
    required double newPercent,
  }) {
    final index = categories.indexWhere((c) => c.id == categoryId);
    if (index == -1) return categories;

    final oldPercent = categories[index].allocatedPercent;
    final delta = newPercent - oldPercent;

    // Identify which categories can absorb the delta (not locked, not the target)
    final adjustable = categories
        .where((c) => !c.isLocked && c.id != categoryId)
        .toList();

    if (adjustable.isEmpty) return categories;

    final totalAdjustable =
        adjustable.fold<double>(0, (sum, c) => sum + c.allocatedPercent);

    if (totalAdjustable == 0) return categories;

    // Distribute delta proportionally across adjustable categories
    final updated = categories.map((cat) {
      if (cat.id == categoryId) {
        return cat.copyWith(allocatedPercent: newPercent.clamp(1, 90));
      }
      if (!cat.isLocked) {
        final share = cat.allocatedPercent / totalAdjustable;
        final adjustment = -delta * share;
        final newVal = (cat.allocatedPercent + adjustment).clamp(1.0, 90.0);
        return cat.copyWith(allocatedPercent: newVal);
      }
      return cat;
    }).toList();

    // Normalize to ensure total == 100
    final total = updated.fold<double>(0, (sum, c) => sum + c.allocatedPercent);
    if (total == 0) return updated;

    return updated.map((c) {
      return c.copyWith(allocatedPercent: (c.allocatedPercent / total) * 100);
    }).toList();
  }

  /// Toggles the lock state of a category.
  static List<BudgetCategory> toggleLock({
    required List<BudgetCategory> categories,
    required String categoryId,
  }) {
    return categories.map((cat) {
      if (cat.id == categoryId) return cat.copyWith(isLocked: !cat.isLocked);
      return cat;
    }).toList();
  }

  /// Returns true if total allocations sum to ~100%.
  static bool isValid(List<BudgetCategory> categories) {
    final total =
        categories.fold<double>(0, (sum, c) => sum + c.allocatedPercent);
    return (total - 100).abs() < 0.5;
  }
}
