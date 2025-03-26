// No changes are required in the EmployeeModel class as the error is related to Firestore indexes.
// The provided code snippet is a URL that needs to be accessed to create the required composite index in the Firebase Firestore database.

class EmployeeModel {
  final String? id;
  final String name;
  final String email;
  final String phone;
  final String position;
  final String department;
  final double salary;
  final String joinDate;
  final String? photoUrl;

  EmployeeModel({
    this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.position,
    required this.department,
    required this.salary,
    required this.joinDate,
    this.photoUrl,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      id: json['id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      position: json['position'] ?? '',
      department: json['department'] ?? '',
      salary: (json['salary'] ?? 0.0).toDouble(),
      joinDate: json['joinDate'] ?? '',
      photoUrl: json['photoUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'position': position,
      'department': department,
      'salary': salary,
      'joinDate': joinDate,
      'photoUrl': photoUrl ?? '',
    };
  }

  EmployeeModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? position,
    String? department,
    double? salary,
    String? joinDate,
    String? photoUrl,
  }) {
    return EmployeeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      position: position ?? this.position,
      department: department ?? this.department,
      salary: salary ?? this.salary,
      joinDate: joinDate ?? this.joinDate,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}