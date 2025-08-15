import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:inventory/Authentication/Loginpage.dart';
import 'package:inventory/Authentication/Registrationpage.dart';
import 'package:inventory/Homepage.dart';
import 'package:inventory/helper/SellProductPage.dart';
import 'package:inventory/helper/ViewProductsPage.dart';
import 'package:inventory/helper/add_product.dart';
import 'package:inventory/helper/expense.dart';
import 'package:inventory/helper/income.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
 
    await Firebase.initializeApp(
      options: FirebaseOptions(
          apiKey: "AIzaSyAZjokPOayjxoZ6rxET2Wo4oGkKQ_C5ns4",
          authDomain: "inventory-eecde.firebaseapp.com",
          projectId: "inventory-eecde",
          storageBucket: "inventory-eecde.firebasestorage.app",
          messagingSenderId: "522613859949",
          appId: "1:522613859949:web:d2d7673b52a06fc6240164"
      ),
    );
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Firebase Auth (Web & Mobile)',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: AuthWrapper(),
      routes: {
        '/login': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),
        '/home': (context) => HomePage(),
        '/addProduct': (context) => const AddProductPage(),
        '/products': (context) => const ViewProductsPage(),
        '/expense': (context) => const ExpensePage(),
        '/sellProduct': (context) => const SellProductPage(),
        '/income': (context) => const IncomePage(),



      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
       
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
         
          return Scaffold(
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        } else if (snapshot.hasData) {
          
          return HomePage();
        } else {
          
          return LoginPage();
        }
      },
    );
  }
}
