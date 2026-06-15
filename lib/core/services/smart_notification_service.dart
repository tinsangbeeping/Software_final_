import '../../models/user_profile_model.dart';
import '../../models/notification_profile_model.dart';

class SmartNotificationService {

  NotificationProfileModel generate(
      UserProfileModel profile) {

    return NotificationProfileModel(

      morningHour:

          profile.wakeHour,

      eveningHour:

          profile.sleepHour - 1,

    );

  }

}