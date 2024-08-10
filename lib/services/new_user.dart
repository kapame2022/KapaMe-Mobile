import 'package:flutter/material.dart';

class UserState extends ChangeNotifier {
  DateTime _dateOfBirth = DateTime.now();
  String _gender = 'Select gender';
  String _fullName = '';
  String _email = '';
  String _phoneNumber = '';
  String _password = '';
  String _confirmPassword = '';

  DateTime get dateOfBirth => _dateOfBirth;
  String get gender => _gender;
  String get fullName => _fullName;
  String get email => _email;
  String get phoneNumber => _phoneNumber;
  String get password => _password;
  String get confirmPassword => _confirmPassword;

  void updateDateOfBirth(DateTime newDateOfBirth) {
    _dateOfBirth = newDateOfBirth;
    notifyListeners();
  }

  void updateGender(String newGender) {
    _gender = newGender;
    notifyListeners();
  }

  void updateFullName(String newFullName) {
    _fullName = newFullName;
    notifyListeners();
  }

  void updateEmail(String newEmail) {
    _email = newEmail;
    notifyListeners();
  }

  void updatePhoneNumber(String newPhoneNumber) {
    _phoneNumber = newPhoneNumber;
    notifyListeners();
  }

  void updatePassword(String newPassword) {
    _password = newPassword;
    notifyListeners();
  }

  void updateConfirmPassword(String newConfirmPassword) {
    _confirmPassword = newConfirmPassword;
    notifyListeners();
  }

  @override
  String toString() {
    return 'Fullname: $fullName \nUsername: $fullName \nDate of Birth: $dateOfBirth \nEmail: $email \nGender: $gender \nPhone Number: $phoneNumber \nPassword: $password \nConfirm Password: $confirmPassword';
  }
}
