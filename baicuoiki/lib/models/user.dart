class User {
  final String id;
  final String email;
  final String username;
  final String? avatar; // Thêm trường avatar
  final String role; // Thêm trường role
  final DateTime createdAt; // Thêm trường createdAt
  final DateTime lastActive; // Thêm trường lastActive

  User({
    required this.id,
    required this.email,
    required this.username,
    this.avatar,
    this.role = 'User', // Giá trị mặc định cho role
    required this.createdAt,
    required this.lastActive,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? '',
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      avatar: json['avatar'],
      role: json['role'] ?? 'User', // Lấy role từ JSON, mặc định là 'User'
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
      'role': role, // Thêm role vào JSON
      'createdAt': createdAt.toIso8601String(),
      'lastActive': lastActive.toIso8601String(),
    };
  }
}