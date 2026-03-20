class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final String avatarUrl;
  final double monthlyBudget;

  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.avatarUrl,
    this.monthlyBudget = 0,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      uid: documentId,
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? 'Người dùng',
      avatarUrl: map['avatarUrl'] ?? '',
      monthlyBudget: (map['monthlyBudget'] as num?)?.toDouble() ?? 0,
    );
  }
}
