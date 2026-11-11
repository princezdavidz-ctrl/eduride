class Child {
  const Child({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.schoolName,
    this.age,
    this.grade,
    this.photoUrl,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String schoolName;
  final int? age;
  final String? grade;
  final String? photoUrl;

  String get fullName => '$firstName $lastName';

  Child copyWith({
    String? firstName,
    String? lastName,
    String? schoolName,
    int? age,
    String? grade,
    String? photoUrl,
  }) {
    return Child(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      schoolName: schoolName ?? this.schoolName,
      age: age ?? this.age,
      grade: grade ?? this.grade,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}
