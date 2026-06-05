import 'dart:developer' as dev;
import '../models/budget_model.dart';
import 'supabase_service.dart';

class SavedBudgetPlan {
  final String id;
  final String planName;
  final double totalBudget;
  final int guestCount;
  final String eventType;
  final List<BudgetCategory> categories;
  final String? notes;
  final DateTime createdAt;

  SavedBudgetPlan({
    required this.id,
    this.planName = 'My Budget',
    required this.totalBudget,
    required this.guestCount,
    required this.eventType,
    required this.categories,
    this.notes,
    required this.createdAt,
  });

  factory SavedBudgetPlan.fromMap(Map<dynamic, dynamic> m) {
    final cats = defaultBudgetCategories();
    try {
      final json = m['categories_json'];
      if (json is List) {
        for (final item in json) {
          final idx = cats.indexWhere((c) => c.id == item['id']);
          if (idx >= 0) {
            cats[idx] = cats[idx].copyWith(
              allocatedPercent: (item['percent'] as num?)?.toDouble(),
            );
          }
        }
      }
    } catch (_) {}
    return SavedBudgetPlan(
      id: m['id'] as String,
      planName: (m['plan_name'] as String?) ?? 'My Budget',
      totalBudget: (m['total_budget'] as num).toDouble(),
      guestCount: m['guest_count'] as int,
      eventType: (m['event_type'] as String?) ?? 'Wedding',
      categories: cats,
      notes: m['notes'] as String?,
      createdAt: DateTime.tryParse(m['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class BudgetService {
  static Future<SavedBudgetPlan?> savePlan({
    required String userId,
    required double totalBudget,
    required int guestCount,
    required String eventType,
    required List<BudgetCategory> categories,
    String planName = 'My Budget',
    String? notes,
  }) async {
    dev.log('[BudgetService] Saving plan for $userId: ৳$totalBudget', name: 'BiyerBajar');
    try {
      final categoriesJson = categories.map((c) => {
        'id': c.id,
        'name': c.name,
        'percent': c.allocatedPercent,
        'amount': totalBudget * c.allocatedPercent / 100,
      }).toList();

      final data = await SupabaseService.budgetPlans.insert({
        'user_id': userId,
        'plan_name': planName,
        'total_budget': totalBudget,
        'guest_count': guestCount,
        'event_type': eventType,
        'categories_json': categoriesJson,
        'notes': notes,
      }).select().single();

      return SavedBudgetPlan.fromMap(data);
    } catch (e) {
      SupabaseService.debugLog('savePlan error', error: e);
      return null;
    }
  }

  static Future<SavedBudgetPlan?> getLatestPlan(String userId) async {
    try {
      final data = await SupabaseService.budgetPlans
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (data == null) return null;
      return SavedBudgetPlan.fromMap(data);
    } catch (e) {
      SupabaseService.debugLog('getLatestPlan error', error: e);
      return null;
    }
  }

  static Future<List<SavedBudgetPlan>> getAllPlans(String userId) async {
    try {
      final data = await SupabaseService.budgetPlans
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return (data as List).map((d) => SavedBudgetPlan.fromMap(d)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get the allocated amount for a specific category from the latest plan.
  static double? getCategoryAmount(SavedBudgetPlan plan, String categoryId) {
    final cat = plan.categories.where((c) => c.id == categoryId).toList();
    if (cat.isEmpty) return null;
    return plan.totalBudget * cat.first.allocatedPercent / 100;
  }

  /// Returns unallocated percentage remaining in a plan.
  static double unallocatedPercent(SavedBudgetPlan plan) {
    final used = plan.categories.fold(0.0, (sum, c) => sum + c.allocatedPercent);
    return (100.0 - used).clamp(0.0, 100.0);
  }

  /// Suggests a budget amount for a new service not in the plan.
  /// Uses half of unallocated budget, or 5% of total if nothing unallocated.
  static double suggestAmountForNewService(SavedBudgetPlan plan) {
    final unallocatedPct = unallocatedPercent(plan);
    final pct = unallocatedPct > 2 ? unallocatedPct / 2 : 5.0;
    return plan.totalBudget * pct / 100;
  }

  /// Adds a new budget category to an existing saved plan and updates Supabase.
  static Future<bool> addCategoryToPlan({
    required SavedBudgetPlan plan,
    required String categoryId,
    required String categoryName,
    required double allocatedPercent,
  }) async {
    dev.log('[BudgetService] Adding $categoryName ($allocatedPercent%) to plan ${plan.id}',
        name: 'BiyerBajar');
    try {
      final updatedCategories = [
        ...plan.categories,
        // Add as a plain map — will be parsed on next load
      ].map((c) => {
        'id': c.id,
        'name': c.name,
        'percent': c.allocatedPercent,
        'amount': plan.totalBudget * c.allocatedPercent / 100,
      }).toList();

      // Append the new category
      updatedCategories.add({
        'id': categoryId,
        'name': categoryName,
        'percent': allocatedPercent,
        'amount': plan.totalBudget * allocatedPercent / 100,
      });

      await SupabaseService.budgetPlans
          .update({'categories_json': updatedCategories})
          .eq('id', plan.id);

      dev.log('[BudgetService] Category added successfully', name: 'BiyerBajar');
      return true;
    } catch (e) {
      SupabaseService.debugLog('addCategoryToPlan error', error: e);
      return false;
    }
  }
}
