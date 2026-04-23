class ProfileModel {
  final String id;
  final String? fullName;
  final int credits;
  final String? avatarUrl;
  final DateTime? updatedAt;
  final Map<String, dynamic>? psychologicalProfile;

  ProfileModel({
    required this.id,
    this.fullName,
    required this.credits,
    this.avatarUrl,
    this.updatedAt,
    this.psychologicalProfile,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String?,
      credits: (json['credits'] as num?)?.toInt() ?? 500,
      avatarUrl: json['avatar_url'] as String?,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : null,
      psychologicalProfile: json['psychological_profile'] != null
          ? Map<String, dynamic>.from(json['psychological_profile'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'credits': credits,
      'avatar_url': avatarUrl,
      'updated_at': updatedAt?.toIso8601String(),
      'psychological_profile': psychologicalProfile,
    };
  }
}
