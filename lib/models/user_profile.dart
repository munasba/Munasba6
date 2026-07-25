enum Gender { male, female }

class UserProfile {
  String name;
  Gender gender;
  String? imagePath; // مسار صورة مخصصة، أو null لاستخدام الصورة الافتراضية

  UserProfile({
    required this.name,
    required this.gender,
    this.imagePath,
  });

  /// الصورة الافتراضية حسب الجنس عند عدم اختيار صورة
  String get defaultAvatarAsset =>
      gender == Gender.male ? 'assets/images/avatar_male.png' : 'assets/images/avatar_female.png';

  Map<String, dynamic> toJson() => {
        'name': name,
        'gender': gender.name,
        'imagePath': imagePath,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        name: json['name'] ?? '',
        gender: (json['gender'] == 'female') ? Gender.female : Gender.male,
        imagePath: json['imagePath'],
      );
}
