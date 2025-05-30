class User {
  final dynamic id; // Can be String (MongoDB) or int (SQLite)
  final String name;
  final String? email;
  final String? phoneNumber;
  final String? role;
  final bool isAdmin;

  User({
    this.id,
    required this.name,
    this.email,
    this.phoneNumber,
    this.role,
    this.isAdmin = false,
  });

  // Convert a User into a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'role': role,
      'isAdmin': isAdmin,
    };
  }

  // Create a User from a Map
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] ?? map['_id'],
      name: map['name'],
      email: map['email'],
      phoneNumber: map['phoneNumber'],
      role: map['role'],
      isAdmin: map['role'] == 'admin' || map['isAdmin'] == true,
    );
  }

  // Create a copy of User with some changes
  User copyWith({
    dynamic id,
    String? name,
    String? email,
    String? phoneNumber,
    String? role,
    bool? isAdmin,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }
}
