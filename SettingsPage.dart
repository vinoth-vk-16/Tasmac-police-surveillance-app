// SettingsPage.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main.dart'; // Assuming this is the file where LoginScreen is defined

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profile Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            // Display user profile info here
            Text(
                'User email: ${FirebaseAuth.instance.currentUser?.email ?? 'Not logged in'}'),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                FirebaseAuth.instance.signOut().then((_) {
                  // Navigate to the LoginScreen after sign out
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                  );
                }).catchError((error) {
                  print('Failed to sign out: $error');
                });
              },
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}
