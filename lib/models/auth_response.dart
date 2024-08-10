import 'app_user.dart';

class AuthResponse {
  String message = '';
  bool isSuccess = false;
  String token = '';
  List<String>? errors;
  AppUser user = AppUser();
  DateTime? expireDate = DateTime.now();

  AuthResponse(this.message, this.isSuccess, this.token, this.errors, this.user,
      this.expireDate);
}
