import '../../models/weekly_snapshot_model.dart';

class SpendingTrends {
  final double? weekOverWeekChange;
  final Map<String, double> categoryTrends;
  final double spendingConsistency;
  final WeeklySnapshotModel? bestWeek;
  final WeeklySnapshotModel? worstWeek;
  final int savingsStreak;
  final String? peakDay;
  final double averageWeeklySpending;

  SpendingTrends({
    this.weekOverWeekChange,
    required this.categoryTrends,
    required this.spendingConsistency,
    this.bestWeek,
    this.worstWeek,
    required this.savingsStreak,
    this.peakDay,
    required this.averageWeeklySpending,
  });
}

class SpendingAnalyzerService {
  SpendingTrends analyze(List<WeeklySnapshotModel> snapshots) {
    if (snapshots.isEmpty) {
      return SpendingTrends(
        categoryTrends: {},
        spendingConsistency: 0,
        savingsStreak: 0,
        averageWeeklySpending: 0,
      );
    }

    final sorted = List<WeeklySnapshotModel>.from(snapshots)
      ..sort((a, b) => a.weekStart.compareTo(b.weekStart));

    return SpendingTrends(
      weekOverWeekChange: _calcWeekOverWeek(sorted),
      categoryTrends: _calcCategoryTrends(sorted),
      spendingConsistency: _calcConsistency(sorted),
      bestWeek: _findBestWeek(sorted),
      worstWeek: _findWorstWeek(sorted),
      savingsStreak: _calcSavingsStreak(sorted),
      peakDay: _calcPeakDay(sorted),
      averageWeeklySpending: _calcAverage(sorted),
    );
  }

  double? _calcWeekOverWeek(List<WeeklySnapshotModel> sorted) {
    if (sorted.length < 2) return null;
    final previous = sorted[sorted.length - 2].totalSpent;
    final current = sorted.last.totalSpent;
    if (previous == 0) return null;
    return ((current - previous) / previous) * 100;
  }

  Map<String, double> _calcCategoryTrends(List<WeeklySnapshotModel> sorted) {
    if (sorted.length < 2) return {};

    final trends = <String, double>{};
    final prev = sorted[sorted.length - 2].categoryBreakdown;
    final curr = sorted.last.categoryBreakdown;

    final allCategories = {...prev.keys, ...curr.keys};
    for (final cat in allCategories) {
      final prevVal = prev[cat] ?? 0;
      final currVal = curr[cat] ?? 0;
      if (prevVal > 0) {
        trends[cat] = ((currVal - prevVal) / prevVal) * 100;
      } else if (currVal > 0) {
        trends[cat] = 100;
      }
    }

    return trends;
  }

  double _calcConsistency(List<WeeklySnapshotModel> sorted) {
    if (sorted.length < 2) return 0;
    final amounts = sorted.map((s) => s.totalSpent).toList();
    final mean = amounts.reduce((a, b) => a + b) / amounts.length;
    if (mean == 0) return 0;
    final variance = amounts.map((a) => (a - mean) * (a - mean)).reduce((a, b) => a + b) / amounts.length;
    final stdDev = _sqrt(variance);
    return (stdDev / mean) * 100;
  }

  double _sqrt(double x) {
    if (x <= 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 10; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }

  WeeklySnapshotModel? _findBestWeek(List<WeeklySnapshotModel> sorted) {
    if (sorted.isEmpty) return null;
    return sorted.reduce((a, b) => a.totalSpent < b.totalSpent ? a : b);
  }

  WeeklySnapshotModel? _findWorstWeek(List<WeeklySnapshotModel> sorted) {
    if (sorted.isEmpty) return null;
    return sorted.reduce((a, b) => a.totalSpent > b.totalSpent ? a : b);
  }

  int _calcSavingsStreak(List<WeeklySnapshotModel> sorted) {
    if (sorted.length < 2) return 0;
    int streak = 0;
    for (int i = sorted.length - 1; i > 0; i--) {
      if (sorted[i].totalSpent < sorted[i - 1].totalSpent) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  String? _calcPeakDay(List<WeeklySnapshotModel> sorted) {
    if (sorted.isEmpty) return null;
    final combined = <String, double>{};
    for (final s in sorted) {
      for (final entry in s.dailyBreakdown.entries) {
        combined[entry.key] = (combined[entry.key] ?? 0) + entry.value;
      }
    }
    if (combined.isEmpty) return null;
    return combined.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  double _calcAverage(List<WeeklySnapshotModel> sorted) {
    if (sorted.isEmpty) return 0;
    return sorted.map((s) => s.totalSpent).reduce((a, b) => a + b) / sorted.length;
  }
}
