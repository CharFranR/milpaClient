class Company {
  const Company({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.ownerId,
    required this.department,
    required this.municipality,
    required this.description,
    required this.website,
    required this.verified,
    this.createdAt,
    this.updatedAt,
    this._email,
    this._phoneNumber,
    this._addressLine,
  });

  factory Company.fromJson(Map<String, dynamic> json) => Company(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    categoryId: json['category_id'] as String? ?? '',
    ownerId: json['owner_id'] as String? ?? '',
    department: json['department'] as String? ?? '',
    municipality: json['municipality'] as String? ?? '',
    description: json['description'] as String? ?? '',
    website: json['website'] as String? ?? '',
    verified: json['verified'] as bool? ?? false,
    createdAt: json['created_at'] as String?,
    updatedAt: json['updated_at'] as String?,
    email: json['email'] as String?,
    phoneNumber: json['phone_number'] as String?,
    addressLine: json['address_line'] as String?,
  );

  final String id;
  final String name;
  final String categoryId;
  final String ownerId;
  final String department;
  final String municipality;
  final String description;
  final String website;
  final bool verified;
  final String? createdAt;
  final String? updatedAt;

  final String? _email;
  final String? _phoneNumber;
  final String? _addressLine;

  String? get email => _email;
  String? get phoneNumber => _phoneNumber;
  String? get addressLine => _addressLine;
}

class CompanyDraft {
  const CompanyDraft({
    required this.name,
    this.categoryId,
    this.description = '',
    this.phoneNumber = '',
    this.email = '',
    this.website = '',
  });

  final String name;
  final String? categoryId;
  final String description;
  final String phoneNumber;
  final String email;
  final String website;

  Map<String, dynamic> toJson() {
    final String? category = categoryId?.trim();
    return <String, dynamic>{
      'name': name.trim(),
      if (category != null && category.isNotEmpty) 'category_id': category,
      if (description.trim().isNotEmpty) 'description': description.trim(),
      if (phoneNumber.trim().isNotEmpty) 'phone_number': phoneNumber.trim(),
      if (email.trim().isNotEmpty) 'email': email.trim(),
      if (website.trim().isNotEmpty) 'website': website.trim(),
    };
  }
}
