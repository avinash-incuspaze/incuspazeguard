class GuardUser {
  final String id;
  final String email;
  final String? name;
  final String? role;
  final String? centreName;
  final String? building;
  final String? address;

  GuardUser({
    required this.id,
    required this.email,
    this.name,
    this.role,
    this.centreName,
    this.building,
    this.address,
  });

  factory GuardUser.fromJson(Map<String, dynamic> json) {
    return GuardUser(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      name: json['name'] as String?,
      role: json['role'] as String?,
      centreName: json['centreName'] as String? ?? json['centre_name'] as String? ?? json['center_name'] as String?,
      building: json['building'] as String?,
      address: json['address'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'role': role,
        'centreName': centreName,
        'building': building,
        'address': address,
      };
}
