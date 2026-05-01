import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:smartmeal_ai/screens/LoginScreen.dart';
import 'package:smartmeal_ai/screens/HomeScreen.dart';
import 'package:smartmeal_ai/screens/admin/AdminDashboardScreen.dart';
import 'package:smartmeal_ai/utils/CategoryInitializer.dart';
import 'package:smartmeal_ai/utils/FoodMigration.dart';
import 'firebase_options.dart';
import 'models/Role.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize default categories on app startup
  await CategoryInitializer.initializeCategories();

  // Migrate existing food records to use categoryId
  await FoodMigration.migrateToCategory();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SmartMeal AI',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),

      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),

      builder: (context, snapshot) {

        // Đang load Firebase
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Chưa đăng nhập
        if (!snapshot.hasData) {
          return const LoginScreen();
        }

        // Đã đăng nhập → kiểm tra role
        String uid = snapshot.data!.uid;

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection("users")
              .doc(uid)
              .get(),

          builder: (context, roleSnapshot) {

            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (!roleSnapshot.hasData || !roleSnapshot.data!.exists) {
              return const LoginScreen();
            }

            final data = roleSnapshot.data!.data() as Map<String, dynamic>?;
            final String role = (data?["role"] as String?) ?? Role.user;

            // ADMIN
            if (role == Role.admin) {
              return const AdminDashboardScreen();
            }

            // USER
            return const HomeScreen();
          },
        );
      },
    );
  }
}
