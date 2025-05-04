class User {
  final String id;
  final String email;
  final String username;
  final String? avatar; // Thêm trường avatar
  final DateTime createdAt; // Thêm trường createdAt
  final DateTime lastActive; // Thêm trường lastActive

  User({
    required this.id,
    required this.email,
    required this.username,
    this.avatar,
    required this.createdAt,
    required this.lastActive,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? '',
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      avatar: json['avatar'],
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      lastActive: DateTime.tryParse(json['lastActive']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'email': email,
      'username': username,
      'avatar': avatar,
      'createdAt': createdAt.toIso8601String(),
      'lastActive': lastActive.toIso8601String(),
    };
  }
}