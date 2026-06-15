import '../../models/user_profile_model.dart';

class AdaptiveBudgetService {

  double getTodayBudget(
      UserProfileModel profile,
      DateTime today) {

    if (
      today.weekday ==
              DateTime.saturday ||
          today.weekday ==
              DateTime.sunday
    ) {

      return profile.weekendBudget;

    }

    return profile.weekdayBudget;
  }
}