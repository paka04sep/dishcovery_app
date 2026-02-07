import 'package:dishcovery_app/starting_screen/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screen/swipescreen.dart';
import '../services/auth_service.dart';
import '../screen/foodpreference_screen.dart';
import '../starting_screen/signin_screen.dart';
import '../starting_screen/loading_screen.dart'; // Import LoadingScreen if you want to show it while checking auth

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // If the snapshot has data, the user is logged in
        if (snapshot.connectionState == ConnectionState.active) {
          final User? user = snapshot.data;

          if (user == null) {
            return const SignInScreen();
          }

          // User is logged in, check if it's their first time
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const LoadingScreen();
              }

              if (userSnapshot.hasError) {
                // Fallback in case of error, maybe show error or default to SwipScreen
                return Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Error loading profile: ${userSnapshot.error}"),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () async {
                            await authService.signOut();
                            if (context.mounted) {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (context) => const LoadingScreen(),
                                ),
                                (route) => false,
                              );
                            }
                          },
                          child: const Text("Logout & Retry"),
                        ),
                      ],
                    ),
                  ),
                );
              }

              bool isFirstLogin = true;
              if (userSnapshot.hasData &&
                  userSnapshot.data != null &&
                  userSnapshot.data!.exists) {
                final data = userSnapshot.data!.data() as Map<String, dynamic>?;
                if (data != null && data.containsKey('isFirstLogin')) {
                  isFirstLogin = data['isFirstLogin'];
                }
              }

              // If it's first login (or doc doesn't exist yet), go to preferences
              if (isFirstLogin) {
                return const OnboardingScreen();
              }

              // Otherwise go to main app
              return const SwipScreen();
            },
          );
        }

        // While checking the auth state, show a loading indicator
        return const LoadingScreen();
      },
    );
  }
}
