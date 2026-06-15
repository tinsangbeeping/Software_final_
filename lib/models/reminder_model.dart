class ReminderModel {
  final String title;
  final String date;

  ReminderModel({
    required this.title,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      "title": title,
      "date": date,
    };
  }

  factory ReminderModel.fromMap(
      Map<String, dynamic> map) {

    return ReminderModel(
      title: map["title"],
      date: map["date"],
    );
  }
}