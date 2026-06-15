# Budget Breakdown System — Implementation Plan

> **For Hermes:** Use subagent-driven-development skill to implement this plan task-by-task.

**Goal:** Turn a raw monthly budget number (e.g. $2000) into per-category allocations, track spending against each, and surface pacing warnings — all connected to the AI chat and analytics page.

**Architecture:** Three-layer system: Allocation Engine → Real-time Tracking → Pacing Engine. Allocation generates a suggested per-category breakdown from defaults or historical ratios. Tracking computes spent/remaining per category from Firestore transactions. Pacing compares burn rate against timeline to produce health signals (🟢🟡🔴⚫).

**Tech Stack:** Flutter, Firebase/Firestore, fl_chart, Gemini AI

---

## Task 1: Extend BudgetModel with computed fields

**Objective:** Add `spent`, `remaining`, `percentUsed`, and `month`/`year` to BudgetModel so it can represent both the allocation and the current spending state.

**Files:**
- Modify: `lib/models/budget_model.dart`

**Step 1: Update BudgetModel**

```dart
class BudgetModel {
  final String category;
  final double limit;          // allocated amount
  final int month;             // 1-12
  final int year;              // e.g. 2026
  final double spent;          // computed at read time
  final int transactionCount;  // computed at read time

  BudgetModel({
    required this.category,
    required this.limit,
    this.month = 0,            // 0 = legacy (no month)
    this.year = 0,
    this.spent = 0,
    this.transactionCount = 0,
  });

  double get remaining => limit - spent;
  double get percentUsed => limit > 0 ? (spent / limit * 100).clamp(0, 999) : 0;

  /// Health status: 'on_track', 'caution', 'over_pace', 'over_budget'
  String get healthStatus {
    if (percentUsed > 100) return 'over_budget';
    // Will be computed by BudgetPacingService with timeline context
    // Fallback: simple threshold
    if (percentUsed > 80) return 'over_pace';
    if (percentUsed > 50) return 'caution';
    return 'on_track';
  }

  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'limit': limit,
      'month': month,
      'year': year,
    };
  }

  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    return BudgetModel(
      category: map['category'] ?? '',
      limit: double.parse(map['limit'].toString()),
      month: map['month'] ?? 0,
      year: map['year'] ?? 0,
    );
  }

  /// Create a copy with computed fields filled in
  BudgetModel withSpending({required double spent, required int transactionCount}) {
    return BudgetModel(
      category: category,
      limit: limit,
      month: month,
      year: year,
      spent: spent,
      transactionCount: transactionCount,
    );
  }
}
```

**Step 2: Commit**

```bash
git add lib/models/budget_model.dart
git commit -m "feat: extend BudgetModel with month, spent, remaining, health status"
```

---

## Task 2: Create BudgetAllocationService

**Objective:** Generate a suggested per-category budget breakdown from a total budget amount. Uses smart defaults for new users, historical ratios for returning users.

**Files:**
- Create: `lib/core/services/budget_allocation_service.dart`

**Step 1: Create the service**

```dart
import '../../models/transaction_model.dart';
import '../../models/budget_model.dart';

class BudgetAllocationService {
  /// Smart default percentages for student budgets
  static const Map<String, double> _defaultPercentages = {
    'Food': 0.35,
    'Transport': 0.12,
    'Shopping': 0.15,
    'Entertainment': 0.08,
    'Bills': 0.12,
    'Health': 0.05,
    'Other': 0.13,
  };

  /// Min/max bounds per category (as fraction of total)
  static const Map<String, double> _minBounds = {
    'Food': 0.15,
    'Transport': 0.05,
    'Shopping': 0.05,
    'Entertainment': 0.03,
    'Bills': 0.05,
    'Health': 0.03,
    'Other': 0.05,
  };

  static const Map<String, double> _maxBounds = {
    'Food': 0.50,
    'Transport': 0.25,
    'Shopping': 0.30,
    'Entertainment': 0.20,
    'Bills': 0.25,
    'Health': 0.15,
    'Other': 0.25,
  };

  /// Generate suggested allocation for a given total budget.
  /// If user has transaction history, uses their actual spending ratios.
  /// Otherwise uses smart defaults.
  List<BudgetModel> suggestAllocation({
    required double totalBudget,
    required int month,
    required int year,
    List<TransactionModel>? recentTransactions,
  }) {
    Map<String, double> percentages;

    if (recentTransactions != null && recentTransactions.length >= 10) {
      percentages = _computeHistoricalRatios(recentTransactions);
    } else {
      percentages = Map.from(_defaultPercentages);
    }

    // Clamp to bounds
    percentages = _clampToBounds(percentages);

    // Renormalize to ensure sum = 1.0
    final sum = percentages.values.fold<double>(0, (a, b) => a + b);
    if (sum > 0) {
      percentages = percentages.map((k, v) => MapEntry(k, v / sum));
    }

    // Convert to BudgetModel with dollar amounts
    return percentages.entries.map((e) {
      final allocated = (totalBudget * e.value).roundToDouble();
      return BudgetModel(
        category: e.key,
        limit: allocated,
        month: month,
        year: year,
      );
    }).toList();
  }

  Map<String, double> _computeHistoricalRatios(List<TransactionModel> transactions) {
    final now = DateTime.now();
    final threeMonthsAgo = DateTime(now.year, now.month - 3, 1);

    final Map<String, double> categoryTotals = {};
    for (final t in transactions) {
      if (t.type == 'income') continue;
      if (t.createdAt.isBefore(threeMonthsAgo)) continue;
      // Normalize category name
      final cat = _normalizeCategory(t.category);
      categoryTotals[cat] = (categoryTotals[cat] ?? 0) + t.amount;
    }

    if (categoryTotals.isEmpty) return Map.from(_defaultPercentages);

    final total = categoryTotals.values.fold<double>(0, (a, b) => a + b);
    return categoryTotals.map((k, v) => MapEntry(k, v / total));
  }

  String _normalizeCategory(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('food') || lower.contains('lunch') || lower.contains('dinner') || lower.contains('breakfast')) return 'Food';
    if (lower.contains('transport') || lower.contains('uber') || lower.contains('bus')) return 'Transport';
    if (lower.contains('shop') || lower.contains('clothes') || lower.contains('cloth')) return 'Shopping';
    if (lower.contains('entertain') || lower.contains('movie') || lower.contains('game')) return 'Entertainment';
    if (lower.contains('bill') || lower.contains('utilit') || lower.contains('rent')) return 'Bills';
    if (lower.contains('health') || lower.contains('medical') || lower.contains('doctor')) return 'Health';
    return 'Other';
  }

  Map<String, double> _clampToBounds(Map<String, double> percentages) {
    return percentages.map((key, value) {
      final min = _minBounds[key] ?? 0.03;
      final max = _maxBounds[key] ?? 0.25;
      return MapEntry(key, value.clamp(min, max));
    });
  }
}
```

**Step 2: Commit**

```bash
git add lib/core/services/budget_allocation_service.dart
git commit -m "feat: add BudgetAllocationService with smart defaults and historical ratios"
```

---

## Task 3: Create BudgetPacingService

**Objective:** Compute per-category pacing status by comparing actual spending against allocated budget and timeline position.

**Files:**
- Create: `lib/core/services/budget_pacing_service.dart`

**Step 1: Create the service**

```dart
import '../../models/budget_model.dart';
import '../../models/transaction_model.dart';

class CategoryPacing {
  final String category;
  final double allocated;
  final double spent;
  final double remaining;
  final double percentUsed;
  final double daysElapsed;     // days into month so far
  final double daysInMonth;
  final double expectedPercent; // where you should be by now
  final double burnRate;        // $/day actual
  final double allowedBurnRate; // $/day allowed
  final String healthStatus;    // 'on_track', 'caution', 'over_pace', 'over_budget'
  final int daysUntilExhausted; // estimated days until budget runs out

  CategoryPacing({
    required this.category,
    required this.allocated,
    required this.spent,
    required this.remaining,
    required this.percentUsed,
    required this.daysElapsed,
    required this.daysInMonth,
    required this.expectedPercent,
    required this.burnRate,
    required this.allowedBurnRate,
    required this.healthStatus,
    required this.daysUntilExhausted,
  });
}

class BudgetPacingService {
  /// Compute pacing for all categories
  List<CategoryPacing> computePacing({
    required List<BudgetModel> budgets,
    required List<TransactionModel> transactions,
  }) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);
    final daysInMonth = monthEnd.day.toDouble();
    final daysElapsed = now.day.toDouble();
    final expectedPercent = (daysElapsed / daysInMonth * 100);

    // Aggregate spending by category this month
    final Map<String, double> categorySpent = {};
    for (final t in transactions) {
      if (t.type == 'income') continue;
      if (t.createdAt.isBefore(monthStart) || t.createdAt.isAfter(monthEnd)) continue;
      final cat = t.category;
      categorySpent[cat] = (categorySpent[cat] ?? 0) + t.amount;
    }

    // Match budgets to actual spending
    final List<CategoryPacing> results = [];
    for (final b in budgets) {
      final spent = categorySpent[b.category] ?? 0;
      final remaining = b.limit - spent;
      final percentUsed = b.limit > 0 ? (spent / b.limit * 100).clamp(0.0, 999.0) : 0.0;

      final burnRate = daysElapsed > 0 ? spent / daysElapsed : 0.0;
      final allowedBurnRate = daysInMonth > 0 ? b.limit / daysInMonth : 0.0;

      // Health status
      String healthStatus;
      if (percentUsed > 100) {
        healthStatus = 'over_budget';
      } else if (percentUsed > expectedPercent + 20) {
        healthStatus = 'over_pace';
      } else if (percentUsed > expectedPercent + 5) {
        healthStatus = 'caution';
      } else {
        healthStatus = 'on_track';
      }

      // Days until exhausted
      int daysUntilExhausted;
      if (burnRate <= 0) {
        daysUntilExhausted = 999;
      } else if (remaining <= 0) {
        daysUntilExhausted = 0;
      } else {
        daysUntilExhausted = (remaining / burnRate).floor();
      }

      results.add(CategoryPacing(
        category: b.category,
        allocated: b.limit,
        spent: spent,
        remaining: remaining,
        percentUsed: percentUsed,
        daysElapsed: daysElapsed,
        daysInMonth: daysInMonth,
        expectedPercent: expectedPercent,
        burnRate: burnRate,
        allowedBurnRate: allowedBurnRate,
        healthStatus: healthStatus,
        daysUntilExhausted: daysUntilExhausted,
      ));
    }

    return results;
  }

  /// Generate a text summary for AI consumption
  String summarizeForAI(List<CategoryPacing> pacing) {
    final buffer = StringBuffer();
    buffer.writeln('Monthly Budget Pacing:');
    for (final p in pacing) {
      final icon = _healthIcon(p.healthStatus);
      buffer.writeln('$icon ${p.category}: \$${p.spent.toStringAsFixed(0)}/\$${p.allocated.toStringAsFixed(0)} '
          '(${p.percentUsed.toStringAsFixed(0)}% used, ${p.healthStatus})');
      if (p.daysUntilExhausted < 999) {
        buffer.writeln('   At \$${p.burnRate.toStringAsFixed(0)}/day, budget runs out in ${p.daysUntilExhausted} days');
      }
    }
    return buffer.toString();
  }

  String _healthIcon(String status) {
    switch (status) {
      case 'on_track': return '🟢';
      case 'caution': return '🟡';
      case 'over_pace': return '🔴';
      case 'over_budget': return '⚫';
      default: return '⚪';
    }
  }
}
```

**Step 2: Commit**

```bash
git add lib/core/services/budget_pacing_service.dart
git commit -m "feat: add BudgetPacingService with per-category health and burn rate"
```

---

## Task 4: Update BudgetRepository for monthly filtering

**Objective:** Add month/year filtering to BudgetRepository so we only fetch and store budgets for the current month.

**Files:**
- Modify: `lib/repositories/budget_repository.dart`

**Step 1: Update the repository**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/budget_model.dart';

class BudgetRepository {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  /// Save or update a budget for a specific month
  Future<void> saveBudget(BudgetModel budget) async {
    final query = await firestore
        .collection('budgets')
        .where('category', isEqualTo: budget.category)
        .where('month', isEqualTo: budget.month)
        .where('year', isEqualTo: budget.year)
        .get();

    if (query.docs.isNotEmpty) {
      // Update existing
      await query.docs.first.reference.update(budget.toMap());
    } else {
      // Create new
      await firestore.collection('budgets').add(budget.toMap());
    }
  }

  /// Save all budgets for a month (bulk save after user confirms allocation)
  Future<void> saveMonthlyBudgets(List<BudgetModel> budgets) async {
    for (final b in budgets) {
      await saveBudget(b);
    }
  }

  /// Fetch budgets for a specific month
  Future<List<BudgetModel>> fetchBudgetsForMonth(int month, int year) async {
    final snapshot = await firestore
        .collection('budgets')
        .where('month', isEqualTo: month)
        .where('year', isEqualTo: year)
        .get();

    return snapshot.docs
        .map((doc) => BudgetModel.fromMap(doc.data()))
        .toList();
  }

  /// Legacy: fetch all budgets (backward compat)
  Future<List<BudgetModel>> fetchBudgets() async {
    final snapshot = await firestore.collection('budgets').get();
    return snapshot.docs
        .map((doc) => BudgetModel.fromMap(doc.data()))
        .toList();
  }

  Stream<QuerySnapshot> getBudgets() {
    return firestore.collection('budgets').snapshots();
  }
}
```

**Step 2: Commit**

```bash
git add lib/repositories/budget_repository.dart
git commit -m "feat: add monthly budget filtering and save/update to BudgetRepository"
```

---

## Task 5: Update AI Chat — budget setting flow

**Objective:** When user says "set budget $2000", the chatbot generates a suggested allocation, shows it as a confirmation card, and saves on user confirmation.

**Files:**
- Modify: `lib/screens/ai_assistant/ai_chat_page.dart`
- Modify: `lib/widgets/ai_assistant/chat_bubble.dart`
- Modify: `lib/core/services/gemini_service.dart`

**Step 1: Add extractBudgetAmount to GeminiService**

In `lib/core/services/gemini_service.dart`, the existing `extractBudget` method returns `{"category":"", "limit":0}`. Add a new method:

```dart
/// Extract total budget amount from user message
Future<String> extractBudgetAmount(String userMessage) async {
  if (_model == null) return _unavailableMsg;
  final prompt = """
Extract the total monthly budget amount from the user's message.
Return ONLY valid JSON.
Schema:
{"amount": 0}
Example:
User: Set my budget to 2000
Output: {"amount": 2000}
User: I want a 3000 dollar monthly budget
Output: {"amount": 3000}
User message:
$userMessage
""";
  final response = await _model!.generateContent([Content.text(prompt)]);
  return response.text ?? "";
}
```

**Step 2: Add BudgetAllocationCard widget**

In `lib/widgets/ai_assistant/chat_bubble.dart`, add:

```dart
class BudgetAllocationCard extends StatelessWidget {
  final double totalBudget;
  final List<Map<String, dynamic>> allocations; // [{category, amount, percent}]
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const BudgetAllocationCard({
    super.key,
    required this.totalBudget,
    required this.allocations,
    required this.onConfirm,
    required this.onCancel,
  });

  static const Map<String, Color> _categoryColors = {
    'Food': Color(0xFF00BFA6),
    'Transport': Color(0xFF1976D2),
    'Shopping': Color(0xFFFFB300),
    'Entertainment': Color(0xFFE91E63),
    'Bills': Color(0xFF7C4DFF),
    'Health': Color(0xFFFF7043),
    'Other': Color(0xFF5C6BC0),
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00BFA6).withOpacity(0.3)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00BFA6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.account_balance_wallet_rounded,
                    color: Color(0xFF00BFA6), size: 20),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Monthly Budget',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text('\$${totalBudget.toStringAsFixed(0)}/month',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...allocations.map((a) => _buildCategoryRow(a)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Edit'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00BFA6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Confirm'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryRow(Map<String, dynamic> a) {
    final color = _categoryColors[a['category']] ?? Colors.grey;
    final percent = a['percent'] as double;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(a['category'], style: const TextStyle(fontSize: 13)),
          ),
          Text('\$${(a['amount'] as double).toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(width: 6),
          Text('${percent.toStringAsFixed(0)}%',
              style: TextStyle(color: Colors.grey[500], fontSize: 12)),
        ],
      ),
    );
  }
}
```

**Step 3: Update AI Chat page budget flow**

In `ai_chat_page.dart`, update the `setBudget` / budget handling method to:

1. Extract total amount via `extractBudgetAmount()`
2. Call `BudgetAllocationService.suggestAllocation()` to get suggested breakdown
3. Show `BudgetAllocationCard` with confirm/edit buttons
4. On confirm → `BudgetRepository.saveMonthlyBudgets()`
5. On edit → let user adjust via follow-up messages

This is the most complex task — the full implementation should wire:
- `detectIntent` returns 'budget' → call new `handleBudgetFlow()`
- `handleBudgetFlow()` extracts amount → generates allocation → shows card
- Card confirm → saves to Firestore
- Card edit → sends message "You can say 'set Food to 800' to adjust"

**Step 4: Commit**

```bash
git add lib/screens/ai_assistant/ai_chat_page.dart lib/widgets/ai_assistant/chat_bubble.dart lib/core/services/gemini_service.dart
git commit -m "feat: add budget allocation flow with confirmation card in AI chat"
```

---

## Task 6: Update Analytics Page — fix hardcode, add pacing UI

**Objective:** Replace the hardcoded $1600 with actual Firestore budget data. Show per-category progress bars with health status.

**Files:**
- Modify: `lib/screens/analytics/analytics_page.dart`
- Modify: `lib/widgets/analytics/budget_chart.dart`

**Step 1: Fix the $1600 hardcode in analytics_page.dart**

Replace lines 106-113 (the hardcoded budget calculation) with:

```dart
// Fetch actual budgets for current month
final now = DateTime.now();
final budgets = budgetSnapshot.data ?? [];
final totalBudget = budgets.fold<double>(0, (sum, b) => sum + b.limit);
// Fallback if no budgets set
final budgetLimit = totalBudget > 0
    ? totalBudget
    : (_selectedPreset == 'This Week'
        ? 467.0
        : _selectedPreset == 'This Year'
            ? 19200.0
            : _selectedPreset == 'All Time'
                ? 38400.0
                : 1600.0);
```

Also update the `FutureBuilder<List<BudgetModel>>` to filter by current month:

```dart
future: budgetRepository.fetchBudgetsForMonth(now.month, now.year),
```

**Step 2: Update BudgetChart to show per-category progress bars**

Replace the current bar chart with a list of category progress bars showing allocated vs spent:

```dart
class BudgetChart extends StatelessWidget {
  final List<CategoryPacing> pacingData;

  const BudgetChart({super.key, required this.pacingData});

  static const Map<String, Color> _colors = {
    'Food': Color(0xFF00BFA6),
    'Transport': Color(0xFF1976D2),
    'Shopping': Color(0xFFFFB300),
    'Entertainment': Color(0xFFE91E63),
    'Bills': Color(0xFF7C4DFF),
    'Health': Color(0xFFFF7043),
    'Other': Color(0xFF5C6BC0),
  };

  @override
  Widget build(BuildContext context) {
    if (pacingData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.savings_outlined, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text('Set a budget to see progress',
                style: TextStyle(color: Colors.grey[500], fontSize: 14)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: pacingData.length,
      itemBuilder: (context, index) {
        final p = pacingData[index];
        final color = _colors[p.category] ?? Colors.grey;
        final healthIcon = _healthIcon(p.healthStatus);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 10, height: 10,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(p.category, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  ),
                  Text('\$${p.spent.toStringAsFixed(0)}/\$${p.allocated.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 4),
                  Text(healthIcon, style: const TextStyle(fontSize: 12)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (p.percentUsed / 100).clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: color.withOpacity(0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    p.healthStatus == 'over_budget'
                        ? Colors.red
                        : p.healthStatus == 'over_pace'
                            ? Colors.orange
                            : color,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                p.daysUntilExhausted < 999
                    ? '${p.daysUntilExhausted} days left at \$${p.burnRate.toStringAsFixed(0)}/day'
                    : '${p.remaining.toStringAsFixed(0)} remaining',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ],
          ),
        );
      },
    );
  }

  String _healthIcon(String status) {
    switch (status) {
      case 'on_track': return '🟢';
      case 'caution': return '🟡';
      case 'over_pace': return '🔴';
      case 'over_budget': return '⚫';
      default: return '⚪';
    }
  }
}
```

**Step 3: Wire pacing into analytics_page.dart**

In the `ChartSection`, pass pacing data instead of raw category totals:

```dart
// After fetching transactions and budgets:
final pacingService = BudgetPacingService();
final pacingData = pacingService.computePacing(
  budgets: budgets,
  transactions: allTransactions,
);

// Pass to ChartSection
ChartSection(
  categoryTotals: categoryTotals,
  transactions: allTransactions,
  pacingData: pacingData,  // NEW
),
```

**Step 4: Commit**

```bash
git add lib/screens/analytics/analytics_page.dart lib/widgets/analytics/budget_chart.dart
git commit -m "feat: replace hardcoded $1600 with real budget data and add pacing UI"
```

---

## Task 7: Update InsightsService with pacing-aware insights

**Objective:** Generate smarter insights that use the pacing data — e.g. "Food will run out by day 22 at current pace."

**Files:**
- Modify: `lib/core/services/insights_service.dart`

**Step 1: Add pacing-based insight**

Add a new method `_calcPacingInsights` to `InsightsService`:

```dart
InsightModel? _calcPacingWarning(List<CategoryPacing> pacing) {
  // Find the most at-risk category
  CategoryPacing? worst;
  for (final p in pacing) {
    if (p.healthStatus == 'over_pace' || p.healthStatus == 'over_budget') {
      if (worst == null || p.percentUsed > worst.percentUsed) {
        worst = p;
      }
    }
  }
  if (worst == null) return null;

  final icon = worst.healthStatus == 'over_budget'
      ? Icons.error_rounded
      : Icons.warning_amber_rounded;

  return InsightModel(
    icon: icon,
    title: '${worst.category} Over Pace',
    description: worst.healthStatus == 'over_budget'
        ? '${worst.category} budget exceeded! \$${worst.spent.toStringAsFixed(0)} of \$${worst.allocated.toStringAsFixed(0)} spent.'
        : '${worst.category} at ${worst.percentUsed.toStringAsFixed(0)}% with ${worst.daysUntilExhausted} days left.',
    type: worst.healthStatus == 'over_budget' ? InsightType.warning : InsightType.warning,
  );
}
```

Update `generateInsights` to accept optional pacing data and call this method.

**Step 2: Commit**

```bash
git add lib/core/services/insights_service.dart
git commit -m "feat: add pacing-aware insights to InsightsService"
```

---

## Task 8: Update Gemini prompts with budget context

**Objective:** Feed structured budget data to Gemini so it gives category-specific advice instead of generic responses.

**Files:**
- Modify: `lib/core/services/gemini_service.dart`
- Modify: `lib/screens/ai_assistant/ai_chat_page.dart`

**Step 1: Update analyzeSpending prompt**

Before calling `analyzeSpending()`, build a richer summary that includes budget allocations:

```dart
// In ai_chat_page.dart, update analyzeMonthlySpending():
String summary = "Total spending: \$${total.toStringAsFixed(2)}\n";
summary += "Budget allocations:\n";
for (final b in budgets) {
  summary += "  ${b.category}: \$${b.limit.toStringAsFixed(0)} allocated\n";
}
summary += "Category breakdown:\n";
categories.forEach((key, value) {
  final budgeted = budgets.firstWhere(
    (b) => b.category == key,
    orElse: () => BudgetModel(category: key, limit: 0),
  );
  final remaining = budgeted.limit - value;
  summary += "  $key: \$${value.toStringAsFixed(2)} spent";
  if (budgeted.limit > 0) {
    summary += " / \$${budgeted.limit.toStringAsFixed(0)} budget (\$${remaining.toStringAsFixed(0)} remaining)";
  }
  summary += "\n";
});

final reply = await geminiService.analyzeSpending(summary);
```

**Step 2: Update GeminiService.analyzeSpending prompt**

```dart
Future<String> analyzeSpending(String summary) async {
  if (_model == null) return _unavailableMsg;
  final prompt = """
You are a personal finance advisor for a student.
Analyze the user's spending summary WITH budget context.
Give specific, actionable advice:
1. Which categories are at risk?
2. Where can they cut back?
3. Are they on track for the month?
Be concise and direct. Use the budget numbers.
Spending summary:
$summary
""";
  final response = await _model!.generateContent([Content.text(prompt)]);
  return response.text ?? "";
}
```

**Step 3: Commit**

```bash
git add lib/core/services/gemini_service.dart lib/screens/ai_assistant/ai_chat_page.dart
git commit -m "feat: feed budget context to Gemini for category-specific advice"
```

---

## Verification Checklist

After all tasks:

- [ ] Set budget $2000 via chat → see 7 category cards with suggested amounts
- [ ] Confirm budget → saved to Firestore with month/year
- [ ] Analytics page shows per-category progress bars (not hardcoded $1600)
- [ ] Pacing shows 🟢🟡🔴⚫ per category
- [ ] AI chat "analyze spending" gives category-specific advice with budget numbers
- [ ] Insights show pacing warnings for at-risk categories
- [ ] No compilation errors

---

## Summary

| Task | What | Files | Est. Time |
|------|------|-------|-----------|
| 1 | Extend BudgetModel | budget_model.dart | 5 min |
| 2 | BudgetAllocationService | NEW: budget_allocation_service.dart | 15 min |
| 3 | BudgetPacingService | NEW: budget_pacing_service.dart | 15 min |
| 4 | BudgetRepository update | budget_repository.dart | 10 min |
| 5 | AI Chat budget flow | ai_chat_page.dart, chat_bubble.dart, gemini_service.dart | 30 min |
| 6 | Analytics page fix | analytics_page.dart, budget_chart.dart | 20 min |
| 7 | Pacing insights | insights_service.dart | 10 min |
| 8 | Gemini budget context | gemini_service.dart, ai_chat_page.dart | 10 min |
| **Total** | | | **~115 min** |
