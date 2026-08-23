class Profile {
  final String id;
  final String? username;
  final String? avatarUrl;
  final String? backgroundUrl;  // ✅ 新增
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Profile({
    required this.id,
    this.username,
    this.avatarUrl,
    this.backgroundUrl,  // ✅ 新增
    this.createdAt,
    this.updatedAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      username: json['username'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      backgroundUrl: json['background_url'] as String?,  // ✅ 新增
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
      'background_url': backgroundUrl,  // ✅ 新增
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}