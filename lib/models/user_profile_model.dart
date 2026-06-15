class UserProfileModel {

  final double averageDailySpending;

  final double weekdayBudget;

  final double weekendBudget;

  final int wakeHour;

  final int sleepHour;

  UserProfileModel({

    required this.averageDailySpending,

    required this.weekdayBudget,

    required this.weekendBudget,

    required this.wakeHour,

    required this.sleepHour,

  });

  Map<String,dynamic> toMap() {

    return {

      "averageDailySpending":
          averageDailySpending,

      "weekdayBudget":
          weekdayBudget,

      "weekendBudget":
          weekendBudget,

      "wakeHour":
          wakeHour,

      "sleepHour":
          sleepHour,

    };
  }

}