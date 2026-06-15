class UserModel {
  final String uid;
  final String name;
  final String email;
  final double monthlyBudget;
  final String preferredCurrency;
  final String theme;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.monthlyBudget,
    required this.preferredCurrency,
    required this.theme,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      "uid": uid,
      "name": name,
      "email": email,
      "monthlyBudget": monthlyBudget,
      "preferredCurrency": preferredCurrency,
      "theme": theme,
      "createdAt": createdAt,
    };
  }
}