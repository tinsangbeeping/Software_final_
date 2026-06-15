import '../../models/transaction_model.dart';
import '../../models/budget_model.dart';

/// Service that generates suggested per-category budget breakdowns
/// based on smart defaults or historical spending patterns.
class BudgetAllocationService {
  // Smart default ratios (must sum to 1.0)
  static const Map<String, double> _defaultRatios = {
    'Food': 0.35,
    'Transport': 0.12,
    'Shopping': 0.15,
    'Entertainment': 0.08,
    'Bills': 0.12,
    'Health': 0.05,
    'Other': 0.13,
  };

  // Minimum ratio per category (must be <= default and <= max)
  static const Map<String, double> _minBounds = {
    'Food': 0.15,
    'Transport': 0.05,
    'Shopping': 0.05,
    'Entertainment': 0.03,
    'Bills': 0.05,
    'Health': 0.02,
    'Other': 0.05,
  };

  // Maximum ratio per category (must be >= default and >= min)
  static const Map<String, double> _maxBounds = {
    'Food': 0.50,
    'Transport': 0.25,
    'Shopping': 0.30,
    'Entertainment': 0.20,
    'Bills': 0.25,
    'Health': 0.15,
    'Other': 0.25,
  };

  /// Mapping of common category name variants to canonical names.
  static final Map<String, String> _categoryAliases = {
    // Food
    'food': 'Food',
    'lunch': 'Food',
    'dinner': 'Food',
    'breakfast': 'Food',
    'meals': 'Food',
    'groceries': 'Food',
    'restaurant': 'Food',
    'coffee': 'Food',
    'snack': 'Food',
    'snacks': 'Food',
    'takeout': 'Food',
    'delivery': 'Food',
    'dining': 'Food',
    // Transport
    'transport': 'Transport',
    'transportation': 'Transport',
    'uber': 'Transport',
    'lyft': 'Transport',
    'bus': 'Transport',
    'taxi': 'Transport',
    'cab': 'Transport',
    'metro': 'Transport',
    'subway': 'Transport',
    'train': 'Transport',
    'gas': 'Transport',
    'fuel': 'Transport',
    'parking': 'Transport',
    'commute': 'Transport',
    // Shopping
    'shopping': 'Shopping',
    'clothes': 'Shopping',
    'clothing': 'Shopping',
    'electronics': 'Shopping',
    'amazon': 'Shopping',
    'store': 'Shopping',
    'retail': 'Shopping',
    'gift': 'Shopping',
    'gifts': 'Shopping',
    // Entertainment
    'entertainment': 'Entertainment',
    'movie': 'Entertainment',
    'movies': 'Entertainment',
    'cinema': 'Entertainment',
    'concert': 'Entertainment',
    'concerts': 'Entertainment',
    'streaming': 'Entertainment',
    'subscription': 'Entertainment',
    'game': 'Entertainment',
    'games': 'Entertainment',
    'gaming': 'Entertainment',
    'sports': 'Entertainment',
    'fun': 'Entertainment',
    'night out': 'Entertainment',
    // Bills
    'bills': 'Bills',
    'utilities': 'Bills',
    'electric': 'Bills',
    'electricity': 'Bills',
    'water': 'Bills',
    'internet': 'Bills',
    'phone': 'Bills',
    'rent': 'Bills',
    'insurance': 'Bills',
    'mortgage': 'Bills',
    'tv': 'Bills',
    'mobile': 'Bills',
    // Health
    'health': 'Health',
    'medical': 'Health',
    'doctor': 'Health',
    'pharmacy': 'Health',
    'medicine': 'Health',
    'gym': 'Health',
    'fitness': 'Health',
    'hospital': 'Health',
    'dental': 'Health',
    'dentalcare': 'Health',
    'vitamins': 'Health',
    'therapy': 'Health',
    // Other
    'other': 'Other',
    'misc': 'Other',
    'miscellaneous': 'Other',
  };

  /// Normalizes a free-form category string to a canonical category name.
  /// Falls back to 'Other' if no match is found.
  static String normalizeCategory(String raw) {
    final trimmed = raw.trim();
    final lower = trimmed.toLowerCase();

    // Direct canonical match
    if (_defaultRatios.containsKey(trimmed)) {
      return trimmed;
    }

    // Alias lookup
    final mapped = _categoryAliases[lower];
    if (mapped != null) {
      return mapped;
    }

    // Substring containment check for partial matches
    for (final entry in _categoryAliases.entries) {
      if (lower.contains(entry.key)) {
        return entry.value;
      }
    }

    return 'Other';
  }

  /// Clamps a ratio to the defined min/max bounds.
  static double _clampRatio(String category, double ratio) {
    final min = _minBounds[category] ?? 0.0;
    final max = _maxBounds[category] ?? 1.0;
    if (ratio < min) return min;
    if (ratio > max) return max;
    return ratio;
  }

  /// Renormalizes a map of category ratios so they sum to exactly 1.0.
  static Map<String, double> _renormalize(Map<String, double> ratios) {
    final total = ratios.values.fold(0.0, (a, b) => a + b);
    if (total == 0.0) {
      // Fallback to defaults if everything is zero
      return Map.from(_defaultRatios);
    }
    return ratios.map((k, v) => MapEntry(k, v / total));
  }

  /// Computes historical spending ratios from a list of transactions.
  /// Only expense transactions are considered.
  static Map<String, double> _computeHistoricalRatios(
      List<TransactionModel> transactions) {
    final Map<String, double> categoryTotals = {};

    for (final tx in transactions) {
      // Only consider expense transactions
      if (tx.type.toLowerCase() == 'expense' || tx.type.toLowerCase() == 'spending') {
        final canonical = normalizeCategory(tx.category);
        categoryTotals[canonical] = (categoryTotals[canonical] ?? 0.0) + tx.amount;
      }
    }

    // If no expense transactions found, return empty
    if (categoryTotals.isEmpty) {
      return {};
    }

    // Convert totals to ratios
    final totalSpending = categoryTotals.values.fold(0.0, (a, b) => a + b);
    final Map<String, double> ratios = {};
    for (final entry in categoryTotals.entries) {
      ratios[entry.key] = entry.value / totalSpending;
    }

    return ratios;
  }

  /// Generates a list of suggested budget allocations.
  ///
  /// [totalBudget] — the total monthly budget amount.
  /// [month] — target month (1–12).
  /// [year] — target year.
  /// [recentTransactions] — optional historical transactions. If provided with
  ///   10 or more items, historical spending patterns are used to suggest
  ///   allocations; otherwise smart defaults are applied.
  ///
  /// Returns a list of [BudgetModel] items, one per canonical category.
  List<BudgetModel> suggestAllocation(
    double totalBudget,
    int month,
    int year, {
    List<TransactionModel>? recentTransactions,
  }) {
    Map<String, double> ratios;

    // Use historical data if available and sufficient
    if (recentTransactions != null && recentTransactions.length >= 10) {
      final historical = _computeHistoricalRatios(recentTransactions);
      if (historical.isNotEmpty) {
        ratios = historical;
      } else {
        ratios = Map.from(_defaultRatios);
      }
    } else {
      ratios = Map.from(_defaultRatios);
    }

    // Clamp each ratio to its bounds
    final Map<String, double> clamped = {};
    for (final entry in ratios.entries) {
      final category = entry.key;
      final ratio = entry.value;
      clamped[category] = _clampRatio(category, ratio);
    }

    // Ensure all default categories are present (even if not in history)
    for (final cat in _defaultRatios.keys) {
      clamped.putIfAbsent(cat, () => _defaultRatios[cat]!);
    }

    // Renormalize to sum to 1.0
    final normalized = _renormalize(clamped);

    // Build BudgetModel list
    final List<BudgetModel> allocations = [];
    for (final entry in normalized.entries) {
      final limit = totalBudget * entry.value;
      allocations.add(
        BudgetModel(
          category: entry.key,
          limit: double.parse(limit.toStringAsFixed(2)),
        ),
      );
    }

    // Sort by descending allocation amount for consistency
    allocations.sort((a, b) => b.limit.compareTo(a.limit));

    return allocations;
  }
}
