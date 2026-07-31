class Profile {
  final String id;
  final String? username;
  final String? avatarUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Profile({
    required this.id,
    this.username,
    this.avatarUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      username: json['username'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'avatar_url': avatarUrl,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}