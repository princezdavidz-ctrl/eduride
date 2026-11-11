class Parent {
  const Parent({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phoneNumber,
    this.photoUrl,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phoneNumber;
  final String? photoUrl;

  String get fullName => '$firstName $lastName';
}
