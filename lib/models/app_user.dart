class AppUser {
  DateTime? dateOfBirth;
  String? gender;
  String? userType;
  String? subscription;
  String? transporter;
  String? id;
  String? fullName;
  String? email;
  String? phoneNumber;

  AppUser(
      {this.dateOfBirth,
      this.gender,
      this.userType,
      this.subscription,
      this.transporter,
      this.id,
      this.fullName,
      this.email,
      this.phoneNumber});

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
        dateOfBirth: DateTime.tryParse(map['dateOfBirth']),
        gender: map['gender'],
        userType: map['userType'],
        subscription: map['subscription'],
        transporter: map['transporter'],
        id: map['id'],
        fullName: map['fullName'],
        email: map['email'],
        phoneNumber: map['phoneNumber']);
  }
}
