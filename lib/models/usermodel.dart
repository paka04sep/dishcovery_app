class UserModel {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final List<String> favoriteFoodTypes;
  final double preferredDistance;
  final bool isFirstLogin;

  UserModel({
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
    this.favoriteFoodTypes = const [],
    this.preferredDistance = 25.0,
    this.isFirstLogin = true,
  });

  // แปลงข้อมูลเป็น Map สำหรับเซฟลง Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'favoriteFoodTypes': favoriteFoodTypes,
      'preferredDistance': preferredDistance,
      'isFirstLogin': isFirstLogin,
    };
  }
}
