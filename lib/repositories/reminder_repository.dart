import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/reminder_model.dart';

class ReminderRepository {

  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  Future<void> addReminder(
      ReminderModel reminder) async {

    await firestore
        .collection("reminders")
        .add(
          reminder.toMap(),
        );
  }

}