import 'package:flutter/material.dart';
import 'package:kapame/models/app_user.dart';

class AuthUserState extends ChangeNotifier {
  String? _message = '';
  bool? _isSuccess = false;
  String? _token = '';
  List<String>? _errors;
  AppUser? _user = AppUser();
  DateTime? _expireDate = DateTime.now();

  String? get message => _message;
  bool? get isSuccess => _isSuccess;
  String? get token => _token;
  List<String>? get errors => _errors;
  AppUser? get appUser => _user;
  DateTime? get expireDate => _expireDate;

  Future<void>? updateAuthUser(
      {String? inMessage,
      bool? inIsSuccess,
      String? inToken,
      List<String>? inErrors,
      AppUser? inAppUser,
      DateTime? inExpireDate}) async {
    _message = inMessage;
    _isSuccess = inIsSuccess;
    _token = inToken;
    _errors = inErrors;
    _user = inAppUser;
    _expireDate = inExpireDate;
    notifyListeners();
  }
}
