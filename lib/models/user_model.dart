import 'package:cloud_firestore/cloud_firestore.dart';

class UserStats {
  final int totalSwipes;
  final int yums;
  final int passes;
  final int fav;

  UserStats({
    this.totalSwipes = 0,
    this.yums = 0,
    this.passes = 0,
    this.fav = 0,
  });

  factory UserStats.fromMap(Map<String, dynamic> map) {
    return UserStats(
      totalSwipes: (map['totalSwipes'] as num?)?.toInt() ?? 0,
      yums: (map['yums'] as num?)?.toInt() ?? 0,
      passes: (map['passes'] as num?)?.toInt() ?? 0,
      fav: (map['fav'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalSwipes': totalSwipes,
      'yums': yums,
      'passes': passes,
      'fav': fav,
    };
  }

  Map<String, dynamic> toJson() => toMap();
}

class UserHistory {
  final List<String> yum;
  final List<String> passed;
  final List<String> fav;

  UserHistory({
    this.yum = const [],
    this.passed = const [],
    this.fav = const [],
  });

  factory UserHistory.fromMap(Map<String, dynamic> map) {
    return UserHistory(
      yum: List<String>.from(map['yum'] ?? []),
      passed: List<String>.from(map['passed'] ?? []),
      fav: List<String>.from(map['fav'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {'yum': yum, 'passed': passed, 'fav': fav};
  }

  Map<String, dynamic> toJson() => toMap();
}

class UserModel {
  final String uid;
  final String? email;
  final String role; // Added role field
  final List<String> preferences;
  final List<String> priceRangePreference;
  final bool showClosedRestaurants;
  final UserStats stats;
  final UserHistory history;
  final DateTime? createdAt;
  final DateTime? lastActiveAt;
  final List<String> ownedRestaurantIds;
  final bool isBusinessMode;
  final String? username;
  final String? profilePictureUrl;

  UserModel({
    required this.uid,
    this.email,
    this.role = 'user', // Default to 'user'
    this.preferences = const [],
    this.priceRangePreference = const [],
    this.showClosedRestaurants = false,
    required this.stats,
    required this.history,
    this.createdAt,
    this.lastActiveAt,
    this.ownedRestaurantIds = const [],
    this.isBusinessMode = false,
    this.username,
    this.profilePictureUrl,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // Parse timestamps safely
    DateTime? parseTimestamp(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return UserModel(
      uid: doc.id,
      email: data['email'] as String?,
      role: data['role'] as String? ?? 'user', // Parse role, default to 'user'
      preferences: List<String>.from(data['preferences'] ?? []),
      priceRangePreference: List<String>.from(
        data['priceRangePreference'] ?? [],
      ),
      showClosedRestaurants: data['showClosedRestaurants'] as bool? ?? false,
      stats: data['stats'] != null
          ? UserStats.fromMap(data['stats'] as Map<String, dynamic>)
          : UserStats(),
      history: data['history'] != null
          ? UserHistory.fromMap(data['history'] as Map<String, dynamic>)
          : UserHistory(),
      createdAt: parseTimestamp(data['createdAt']),
      lastActiveAt: parseTimestamp(data['lastActiveAt']),
      ownedRestaurantIds: List<String>.from(data['ownedRestaurantIds'] ?? []),
      isBusinessMode: data['isBusinessMode'] as bool? ?? false,
      username: data['username'] as String?,
      profilePictureUrl: data['profilePictureUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'role': role, // Include role in JSON
      'preferences': preferences,
      'priceRangePreference': priceRangePreference,
      'showClosedRestaurants': showClosedRestaurants,
      'stats': stats.toMap(),
      'history': history.toMap(),
      'createdAt':
          createdAt, // Firestore handles DateTime -> Timestamp automatically usually, but careful with updates
      'lastActiveAt': lastActiveAt,
      'ownedRestaurantIds': ownedRestaurantIds,
      'isBusinessMode': isBusinessMode,
      if (username != null) 'username': username,
      if (profilePictureUrl != null) 'profilePictureUrl': profilePictureUrl,
    };
  }
}
