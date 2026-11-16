import 'package:flutter/material.dart';
import 'package:kapame/models/app_user.dart';
import 'package:kapame/models/auth_response.dart';

class AuthUserState extends ChangeNotifier {
  String? _message = '';
  bool? _isSuccess = false;
  String? _token = '';
  List<String>? _errors;
  AppUser? _user;
  DateTime? _expireDate;

  String? get message => _message;
  bool? get isSuccess => _isSuccess;
  String? get token => _token;
  List<String>? get errors => _errors;
  AppUser? get appUser => _user;
  DateTime? get expireDate => _expireDate;

  AuthUserState({String? inToken, AuthResponse? session}) {
    _token = session?.token ?? inToken;
    _message = session?.message;
    _isSuccess = session?.isSuccess ?? false;
    _errors = session?.errors;
    _user = session?.user;
    _expireDate = session?.expireDate;
  }

  Future<void> updateAuthUser(
      {String? inMessage,
      bool? inIsSuccess,
      String? inToken,
      List<String>? inErrors,
      AppUser? inAppUser,
      DateTime? inExpireDate}) async {
    _message = inMessage ?? _message;
    _isSuccess = inIsSuccess ?? _isSuccess;
    _token = inToken ?? _token;
    _errors = inErrors ?? _errors;
    _user = inAppUser ?? _user;
    _expireDate = inExpireDate ?? _expireDate;
    notifyListeners();
  }

  void clear() {
    _message = null;
    _isSuccess = false;
    _token = null;
    _errors = null;
    _user = null;
    _expireDate = null;
    notifyListeners();
  }
}
