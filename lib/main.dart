import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// Screens
import 'Welcome.dart';
import 'accounttype.dart';
import 'touristlogin.dart';
import 'touristreg.dart';
import 'guidereg.dart';
import 'explore.dart';
import 'guidehome.dart';
import 'admindashboard.dart';
import 'forgetpass.dart';
import 'verificationcode.dart';
import 'resetpass.dart';
import 'passsaved.dart';
import 'touristeditprofile.dart';
import 'settings.dart';
import 'settingscontroller.dart';
import 'cart.dart';
import 'checkout.dart';
import 'paymentverification.dart';
import 'bookingconfirmation.dart';
import 'addcard.dart';
import 'favourites.dart';
import 'adminmanagesites.dart';
import 'adminaddsite.dart';
import 'admineditsite.dart';
import 'history.dart';
import 'places.dart';
import 'placedetails.dart';
import 'bookingform.dart';
import 'guides.dart';
import 'carsselect.dart';
import 'app_entry.dart';
import 'admin_guide_requests.dart';
import 'feedback.dart';
import 'rating.dart';
import 'adminmanageusers.dart';
import 'admincars.dart';
import 'adminmanagereviews.dart';
import 'adminsendnotifications.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await settingsController.loadFromDb();
  runApp(const SaffarOmanApp());
}

final SettingsController settingsController = SettingsController();

class SaffarOmanApp extends StatefulWidget {
  const SaffarOmanApp({super.key});

  @override
  State<SaffarOmanApp> createState() => _SaffarOmanAppState();
}

class _SaffarOmanAppState extends State<SaffarOmanApp> {
  StreamSubscription<User?>? _authSub;

  @override
  void initState() {
    super.initState();

    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user == null) {
        settingsController.resetLocalToDefaults();
      } else {
        await settingsController.loadFromDb();
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  ThemeData _lightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      scaffoldBackgroundColor: Colors.white,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF6B4A3A),
        surface: Colors.white,
        onSurface: Colors.black,
      ),
    );
  }

  ThemeData _darkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF121212),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFB38363),
        surface: Color(0xFF1E1E1E),
        onSurface: Colors.white,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: settingsController,
      builder: (context, _) {
        return MaterialApp(
          title: 'Saffar Oman',
          debugShowCheckedModeBanner: false,
          theme: _lightTheme(),
          darkTheme: _darkTheme(),
          themeMode:
          settingsController.darkMode ? ThemeMode.dark : ThemeMode.light,
          locale: Locale(settingsController.languageCode),
          supportedLocales: const [
            Locale('en'),
            Locale('ar'),
          ],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          localeResolutionCallback: (locale, supportedLocales) {
            if (locale == null) return const Locale('en');

            for (final supportedLocale in supportedLocales) {
              if (supportedLocale.languageCode == locale.languageCode) {
                return supportedLocale;
              }
            }
            return const Locale('en');
          },

          // ✅ التعديل الأساسي هنا
          initialRoute: '/',

          routes: {
            '/': (context) => const WelcomeScreen(),
            '/entry': (context) => const AppEntryScreen(),
            '/chooseAccountType': (context) =>
            const ChooseAccountTypeScreen(),
            '/touristLogin': (context) => const TouristLoginScreen(),
            '/touristRegister': (context) => const TouristRegisterScreen(),
            '/guideRegistration': (context) =>
            const GuideRegistrationScreen(),
            '/forgotPassword': (context) => const ForgotPasswordScreen(),
            '/verifyOtp': (context) => const VerificationCodeScreen(),
            '/resetPassword': (context) => const ResetPasswordScreen(),
            '/passwordSaved': (context) => const PasswordSavedScreen(),
            '/adminDashboard': (context) => const AdminDashboardScreen(),
            '/adminGuideRequests': (context) =>
            const AdminGuideRequestsScreen(),
            '/explore': (context) => const ExploreScreen(),
            '/guideHome': (context) => const GuideHomeScreen(),
            '/touristeditprofile': (context) => const TouristEditProfile(),
            '/settings': (context) =>
                SettingsScreen(controller: settingsController),
            '/cart': (context) => const CartScreen(),
            '/checkout': (context) => const Checkout(),
            '/paymentverification': (context) =>
            const PaymentVerificationScreen(),
            '/bookingconfirmation': (context) =>
            const BookingConfirmation(),
            '/addcard': (context) => const AddCardScreen(),
            '/favourites': (context) => const FavouritesScreen(),
            '/adminManageSites': (context) =>
            const AdminManageSitesScreen(),
            '/adminAddSite': (context) => const AdminAddSiteScreen(),
            '/adminEditSite': (context) => const AdminEditSiteScreen(),
            '/history': (context) => const HistoryScreen(),
            '/places': (context) => const PlacesScreen(),
            '/placeDetails': (context) => const PlaceDetailsScreen(),
            '/bookingForm': (context) => const BookingFormScreen(),
            '/guides': (context) => const GuidesScreen(),
            '/carsSelect': (context) => const CarsSelectScreen(),
            '/feedback': (context) => const FeedbackPage(),
            '/rating': (context) => const RatingPage(),
            '/adminManageUsers': (context) =>
            const AdminManageUsersScreen(),
            '/adminCars': (context) => const AdminCarsScreen(),
            '/adminManageReviews': (context) =>
            const AdminManageReviewsScreen(),
            '/adminSendNotifications': (context) =>
            const AdminSendNotificationsScreen(),
          },
        );
      },
    );
  }
}