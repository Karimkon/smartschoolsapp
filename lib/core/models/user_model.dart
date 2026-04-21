class UserModel {
  final int id;
  final String name;
  final String email;
  final String role;
  final int? schoolId;
  final String? schoolName;
  final String? avatar;
  final String token;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.schoolId,
    this.schoolName,
    this.avatar,
    required this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, String token) {
    return UserModel(
      id:         json['id'],
      name:       json['name'] ?? '',
      email:      json['email'] ?? '',
      role:       json['role'] ?? 'student',
      schoolId:   json['school_id'],
      schoolName: json['school_name'],
      avatar:     json['avatar'],
      token:      token,
    );
  }

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String get roleLabel {
    switch (role) {
      case 'super_admin':   return 'Super Admin';
      case 'school_admin':  return 'Administrator';
      case 'teacher':       return 'Teacher';
      case 'accountant':    return 'Accountant';
      case 'librarian':     return 'Librarian';
      case 'parent':        return 'Parent';
      case 'student':       return 'Student';
      default:              return role;
    }
  }
}
