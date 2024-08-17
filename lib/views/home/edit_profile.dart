import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:kapame/models/auth_response.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../services/current_user.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  TextEditingController fullNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneNumberController = TextEditingController();

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    AppUser? authUser =
        Provider.of<AuthUserState>(context, listen: false).appUser;
    fullNameController = TextEditingController(text: authUser?.fullName);
    emailController = TextEditingController(text: authUser?.email);
    phoneNumberController = TextEditingController(text: authUser?.phoneNumber);
  }

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    phoneNumberController.dispose();
    super.dispose();
  }

  Future<AppUser?> updateUser() async {
    String? id = Provider.of<AuthUserState>(context, listen: false).appUser?.id;

    try {
      final Dio dio = Dio();

      dio.options.connectTimeout = const Duration(seconds: 30);
      dio.options.receiveTimeout = const Duration(seconds: 30);

      setState(() {
        isLoading = true;
      });

      var res = await dio.put(
        'https://kapameapi.azurewebsites.net/api/auth/$id',
        data: {
          "userId": id,
          "fullName": fullNameController.text.trim(),
          "email": emailController.text.trim(),
          "phoneNumber": phoneNumberController.text.trim(),
        },
      );

      print(res.data);

      if (res.statusCode == 200) {
        return AppUser.fromMap(res.data);
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      if (e is DioException) {
        print("error: $e");
        setState(() {
          isLoading = false;
        });
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    AuthUserState? allAuth = Provider.of<AuthUserState>(context);
    AppUser? authUser = Provider.of<AuthUserState>(context).appUser;
    return Scaffold(
      body: Container(
        color: Colors.blue,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 10),
          child: Column(children: [
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(
                    Icons.arrow_back_outlined,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  "Home",
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
            Text(
              authUser?.fullName ?? '',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
            Row(
              children: [
                Text(
                  "User ID: ${authUser?.id}",
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const Icon(
                  Icons.copy,
                  color: Colors.white,
                )
              ],
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 40, horizontal: 0),
                padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    children: [
                      const Text(
                        "Contact Info",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(
                        height: 40,
                      ),
                      TextField(
                        controller: fullNameController,
                        decoration: const InputDecoration(
                          hintText: 'Fullname',
                          border: OutlineInputBorder(
                              borderSide: BorderSide(width: 1),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10))),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.lightBlue,
                              width: 1,
                            ), // Customize focused border
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 30,
                      ),
                      TextField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          hintText: 'Email',
                          border: OutlineInputBorder(
                              borderSide: BorderSide(width: 1),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10))),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.lightBlue,
                              width: 1,
                            ), // Customize focused border
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 30,
                      ),
                      TextField(
                        controller: phoneNumberController,
                        decoration: const InputDecoration(
                          hintText: 'Phone Number',
                          border: OutlineInputBorder(
                              borderSide: BorderSide(width: 1),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10))),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.lightBlue,
                              width: 1,
                            ), // Customize focused border
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 30,
                      ),
                      FilledButton(
                        onPressed: () async {
                          AppUser? authUser = await updateUser();
                          if (authUser != null) {
                            Provider.of<AuthUserState>(context, listen: false)
                                .updateAuthUser(
                              inAppUser: authUser,
                            );

                            Fluttertoast.showToast(
                              msg: "Profile Successfully Updated!",
                              toastLength: Toast.LENGTH_SHORT,
                              gravity: ToastGravity.BOTTOM,
                              timeInSecForIosWeb: 1,
                              backgroundColor: Colors.green,
                              textColor: Colors.white,
                              fontSize: 16.0,
                            );
                          } else {
                            Fluttertoast.showToast(
                              msg: "Failed to update profile. Please try again",
                              toastLength: Toast.LENGTH_SHORT,
                              gravity: ToastGravity.BOTTOM,
                              timeInSecForIosWeb: 1,
                              backgroundColor: Colors.red,
                              textColor: Colors.white,
                              fontSize: 16.0,
                            );
                          }

                          setState(() {
                            isLoading = false;
                          });

                          print(
                              "Updated User: ID: ${authUser?.id}, Name: ${authUser?.fullName}, Email: ${authUser?.email}, Phone: ${authUser?.phoneNumber}");
                        },
                        style: const ButtonStyle(
                          shape: WidgetStatePropertyAll(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(10),
                              ),
                            ),
                          ),
                          minimumSize: WidgetStatePropertyAll(
                            Size(double.infinity, 60),
                          ),
                          backgroundColor:
                              WidgetStatePropertyAll(Colors.orange),
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              )
                            : const Text("Update"),
                      )
                    ],
                  ),
                ),
              ),
            )
          ]),
        ),
      ),
    );
  }
}
