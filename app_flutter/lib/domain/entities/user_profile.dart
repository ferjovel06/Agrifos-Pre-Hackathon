class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.birthDate,
    this.gender,
    this.phone,
    this.country,
    this.department,
    this.address,
  });

  final String id;
  final String name;
  final String email;
  final String role;
  final DateTime? birthDate;
  final String? gender;
  final String? phone;
  final String? country;
  final String? department;
  final String? address;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final birthDate = json['birth_date'] as String?;
    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      birthDate: birthDate == null ? null : DateTime.parse(birthDate),
      gender: json['gender'] as String?,
      phone: json['phone'] as String?,
      country: json['country'] as String?,
      department: json['department'] as String?,
      address: json['address'] as String?,
    );
  }
}

class UserProfileUpdate {
  const UserProfileUpdate({
    required this.name,
    this.birthDate,
    this.gender,
    this.phone,
    this.country,
    this.department,
    this.address,
  });

  final String name;
  final DateTime? birthDate;
  final String? gender;
  final String? phone;
  final String? country;
  final String? department;
  final String? address;

  Map<String, dynamic> toJson() => {
    'name': name.trim(),
    'birth_date': birthDate == null ? null : _dateOnly(birthDate!),
    'gender': _nullable(gender),
    'phone': _nullable(phone),
    'country': _nullable(country),
    'department': _nullable(department),
    'address': _nullable(address),
  };

  static String? _nullable(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  static String _dateOnly(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
