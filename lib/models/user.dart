class AppUser {
  final String id;
  final String? displayName;
  final String email;
  final String? token;
  final DateTime? lastLogin;

  AppUser({
    required this.id,
    this.displayName,
    required this.email,
    this.token,
    this.lastLogin,
  });

  factory AppUser.fromFirebaseUser(dynamic firebaseUser, {String? token}) {
    return AppUser(
      id: firebaseUser.uid,
      displayName: firebaseUser.displayName ?? firebaseUser.email?.split('@')[0],
      email: firebaseUser.email,
      token: token,
      lastLogin: DateTime.now(),
    );
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] ?? '',
      displayName: json['displayName'],
      email: json['email'] ?? '',
      token: json['token'],
      lastLogin: json['lastLogin'] != null 
          ? DateTime.parse(json['lastLogin']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'email': email,
      'token': token,
      'lastLogin': lastLogin?.toIso8601String(),
    };
  }

  AppUser copyWith({
    String? id,
    String? displayName,
    String? email,
    String? token,
    DateTime? lastLogin,
  }) {
    return AppUser(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      token: token ?? this.token,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
}
