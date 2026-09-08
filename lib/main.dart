//libraries
import 'package:flutter/material.dart';
import 'package:kapame/services/current_user.dart';
import 'package:kapame/services/new_user.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

//routes
import 'package:kapame/views/auth/login.dart';
import 'package:kapame/views/auth/register.dart';
import 'package:kapame/views/auth/verify_email.dart';
import 'package:kapame/views/home/edit_profile.dart';
import 'package:kapame/views/home/home.dart';
import 'package:kapame/views/home/settings.dart';
import 'package:kapame/views/home/settings/about_us.dart';
import 'package:kapame/views/home/settings/disclaimer.dart';
import 'package:kapame/views/home/settings/popia_agreement.dart';
import 'package:kapame/views/home/settings/privacy_policy.dart';
import 'package:kapame/views/home/settings/terms_and_conditions.dart';
import 'package:kapame/views/home/trip_history.dart';
import 'package:kapame/views/home/messages.dart';
import 'package:kapame/views/trips/trip_chat_page.dart';
import 'package:kapame/models/trip.dart';
import 'package:kapame/views/trips/destination.dart';
import 'package:kapame/views/trips/driver_tracker.dart';
import 'package:kapame/views/trips/filter_destination.dart';
import 'package:kapame/views/trips/filter_pickup.dart';
import 'package:kapame/views/trips/group_transport.dart';
import 'package:kapame/views/trips/group_transporter.dart';
import 'package:kapame/views/trips/item_transport.dart';
import 'package:kapame/views/trips/item_transporter.dart';
import 'package:kapame/views/trips/pick_up.dart';
import 'package:kapame/views/trips/private_commuter.dart';
import 'package:kapame/views/trips/private_driver.dart';
import 'package:kapame/views/trips/public_commuter.dart';
import 'package:kapame/views/trips/public_driver.dart';
import 'package:kapame/views/trips/view_request.dart';
import 'package:provider/provider.dart';
import 'views/home/landing.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize AdMob
  await MobileAds.instance.initialize().then((InitializationStatus status) {
    // Log initialization status for debugging
    status.adapterStatuses.forEach((key, value) {
      debugPrint('Adapter status for $key: ${value.description}');
    });
  });

  const FlutterSecureStorage secureStorage = FlutterSecureStorage();
  String? savedToken = await secureStorage.read(key: 'token');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => UserState()),
        ChangeNotifierProvider(
            create: (context) => AuthUserState(inToken: savedToken)),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KapaMe Mobile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue.shade300),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LandingPage(),
        '/register': (context) => const Register(),
        '/verifyemail': (context) => const VerifyEmail(),
        '/login': (context) => const Login(),
        '/home': (context) => const Home(),
        '/editprofile': (context) => const EditProfile(),
        '/settings': (context) => const Settings(),
        '/triphistory': (context) => const TripHistory(),
        '/messages': (context) => const Messages(),
        '/viewrequest': (context) => const ViewRequest(),
        '/aboutus': (context) => const AboutUs(),
        '/disclaimer': (context) => const Disclaimer(),
        '/popiaagreement': (context) => const PopiaAgreement(),
        '/privacypolicy': (context) => const PrivacyPolicy(),
        '/termsandconditions': (context) => const TermsAndConditions(),
        '/destination': (context) => const Destination(),
        '/drivertracker': (context) => const DriverTracker(),
        '/filterdestination': (context) => const FilterDestination(),
        '/filterpickup': (context) => const FilterPickUp(),
        '/grouptransport': (context) => const GroupTransport(),
        '/grouptransporter': (context) => const GroupTransporter(),
        '/itemtransport': (context) => const ItemTransport(),
        '/itemtransporter': (context) => const ItemTransporter(),
        '/pickup': (context) => const PickUp(),
        '/privatecommuter': (context) => const PrivateCommuter(),
        '/privatedriver': (context) => const PrivateDriver(),
        '/publiccommuter': (context) => const PublicCommuter(),
        '/publicdriver': (context) => const PublicDriver(),
        '/chat': (context) {
          final trip = ModalRoute.of(context)?.settings.arguments;
          return TripChatPage(trip: trip is Trip ? trip : null);
        },
      },
    );
  }
}
