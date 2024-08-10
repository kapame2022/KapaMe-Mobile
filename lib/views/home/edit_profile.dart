import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
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

  // Future<AuthResponse> updateUser() async {
  //   final Dio dio = Dio();

  //   dio.options.connectTimeout = const Duration(seconds: 30);
  //   dio.options.receiveTimeout = const Duration(seconds: 30);

  //   setState(() {
  //     isLoading = true;
  //   });

  //   var res = await dio.post(
  //     'https://kapameapi.azurewebsites.net/api/auth/${auth}',
  //     data: {
  //       "id": "",
  //       "fullName": fullNameController.text.trim(),
  //       "email": emailController.text.trim(),
  //       "phoneNumber": phoneNumberController.text.trim(),
  //     },
  //   );

  //   print(res.data);
  //   print(res.data['message']);
  //   print(res.data['user']);

  //   if (res.statusCode == 200) {
  //     AuthResponse currentUser = AuthResponse(
  //         res.data['message'],
  //         res.data['isSuccess'],
  //         res.data['token'],
  //         res.data['errors'],
  //         AppUser.fromMap(res.data['user']),
  //         DateTime.parse(res.data['expireDate']));

  //     return currentUser;
  //   } else {
  //     setState(() {
  //       isLoading = false;
  //     });
  //     throw Exception("Function cannot return null");
  //   }
  // }

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
                          final Dio dio = Dio();

                          dio.options.connectTimeout =
                              const Duration(seconds: 30);
                          dio.options.receiveTimeout =
                              const Duration(seconds: 30);

                          setState(() {
                            isLoading = true;
                          });
                          print(authUser?.id);
                          var res = await dio.put(
                            'https://kapameapi.azurewebsites.net/api/auth/${authUser?.id}',
                            data: {
                              "userId": authUser?.id,
                              "fullName": fullNameController.text.trim(),
                              "email": emailController.text.trim(),
                              "phoneNumber": phoneNumberController.text.trim(),
                            },
                          );
                          print(res.data);
                          print(res.statusCode);

                          if (res.statusCode == 200) {
                            Provider.of<AuthUserState>(context, listen: false)
                                .updateAuthUser(
                              allAuth.message ?? '',
                              allAuth.isSuccess ?? false,
                              allAuth.token ?? '',
                              allAuth.errors,
                              AppUser.fromMap(res.data),
                              allAuth.expireDate ?? DateTime.now(),
                            );

                            Fluttertoast.showToast(
                              msg: "Profile Successfully Updated!",
                              toastLength: Toast.LENGTH_SHORT,
                              gravity: ToastGravity.BOTTOM,
                              timeInSecForIosWeb: 1,
                              backgroundColor: Colors.grey,
                              textColor: Colors.white,
                              fontSize: 16.0,
                            );

                            setState(() {
                              isLoading = false;
                            });
                          } else {
                            setState(() {
                              isLoading = false;
                            });
                          }
                        },
                        style: const ButtonStyle(
                          shape: MaterialStatePropertyAll(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(10),
                              ),
                            ),
                          ),
                          minimumSize: MaterialStatePropertyAll(
                            Size(double.infinity, 60),
                          ),
                          backgroundColor:
                              MaterialStatePropertyAll(Colors.orange),
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
